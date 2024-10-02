/* admin authorisation token */
const ADMIN_KEY = process.env.ADMIN_KEY || require('crypto').randomUUID();
if (process.env.ADMIN_KEY === undefined) console.log('Auto-generated administration key for this instance:', ADMIN_KEY);

/* database connection */
const Pool = require('pg').Pool;

let dbConfig = {
    user: process.env.DB_USER || 'auth',
    password: process.env.DB_PASS || 'ptticket_auth',
    host: process.env.DB_HOST || '127.0.0.1',
    port: process.env.DB_PORT || 5432,
    database: process.env.DB_NAME || 'ptticket'
};
console.log('Connecting to database with config:', dbConfig);
const pool = new Pool(dbConfig);

/* listener for token deletions */
const subscriber = require('pg-listen')({
    connectionString: `postgres://${dbConfig.user}:${dbConfig.password}@${dbConfig.host}:${dbConfig.port}/${dbConfig.database}`
});

// TZ should be UTC because turns out node-postgress doesn't exactly like having it set to anything else to then feed it with ISO timestamps
// process.env.TZ = 'Australia/Melbourne';

const keyCache = new Map(); // key cache
const cron = require('node-cron');

/* calculate UTC offset - AEST or AEDT */
let tzTimestamp = new Date(); // temporary timestamp for time zone offset calculation
let tzOffset = (Math.floor(new Date(tzTimestamp.toLocaleString('en-US', { timeZone: 'Australia/Melbourne' })).getTime() / 1000) - Math.floor(tzTimestamp.getTime() / 1000)) / 3600; // get timezone offset in hours
console.log(`Time zone offset: ${(tzOffset >= 0) ? '+' : ''}${tzOffset} hr`);
tzTimestamp.setHours(3 - tzOffset);
let cronStr = `0 0 ${tzTimestamp.getHours()} * * *`;

cron.schedule(cronStr, () => {
    keyCache.clear();
}); // schedule key cache clearing
console.log('Key cache scheduled for clearing using cron string', cronStr);

const DEL_CHANNEL = process.env.DB_DEL_CHANNEL || 'auth_del';
subscriber.notifications.on(DEL_CHANNEL, (payload) => {
    let id = payload.id;
    console.log('API token deleted:', id);

    // keyCache.delete(id);
    keyCache.set(id, false);
});

subscriber.connect().then(() => {
    console.log('Listener connected to database');
    subscriber.listenTo(DEL_CHANNEL).then(() => console.log('Connected to token deletion notification channel', DEL_CHANNEL));
});

const express = require('express');

const app = express();
app.use(express.json());

const respondHttp = (res, status, payload) => {
    res.status(status).json({
        status: status,
        message: payload,
        time: Date.now()
    });
};

/* health check */
app.get('/api/healthcheck', (req, res) => {
    respondHttp(res, 200, 'Authorisation API is functional');
});

/* test authorisation */
app.get('/api/auth', (req, res) => {
    let key = req.headers.authorization;
    if (typeof key !== 'string') return respondHttp(res, 400, 'Invalid or missing Authorization header');
    if (!/^Bearer [0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/.test(key)) return respondHttp(res, 401, 'Invalid Authorization header');
    key = key.split(' ')[1]; // key[1] has our key

    /* query from either key cache or database */
    let auth = (key == ADMIN_KEY) ? true : keyCache.get(key);
    let pFetchAuth = (auth === undefined) ? pool.query('SELECT 1 FROM "auth"."Keys" WHERE "key" = $1', [key]) : new Promise((resolve, reject) => resolve(null));

    /* act on result */
    pFetchAuth.then((queryResult) => {
        if (queryResult !== null) {
            /* database was queried */
            // console.log(queryResult);
            auth = (queryResult.rowCount > 0);
            keyCache.set(key, auth); // save to cache
        }
        
        if (auth) respondHttp(res, 200, 'Key is authorised');
        else {
            console.warn(`Unauthorised access attempt by ${req.ip} using key ${key}`);
            respondHttp(res, 401, 'Key is unauthorised');
        }
    }).catch((e) => {
        console.log(e);
        respondHttp(res, 500, `Error performing operation: ${e}`);
    });
});

const port = process.env.PORT || 3000;
app.listen(port, () => {
    console.log(`App running on port ${port}`);
});
