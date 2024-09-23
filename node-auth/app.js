/* admin authorisation token */
const ADMIN_KEY = process.env.ADMIN_KEY;
if (ADMIN_KEY === undefined) {
    console.error('Administration token is not provided in environment variables, exiting.');
    process.exit(1);
}

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

/* check if string is UUID */
const isUUID = (str) => /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/.test(str);

/* test authorisation */
app.get('/api/auth', (req, res) => {
    let key = req.headers.authorization;
    if (typeof key !== 'string') return respondHttp(res, 400, 'Invalid or missing Authorization header');
    key = key.split(' '); if (key.length != 2 || key[0] !== 'Bearer' || !isUUID(key[1])) return respondHttp(res, 401, 'Invalid Authorization header');
    key = key[1]; // key[1] has our key

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

/* middleware for authorising administration endpoints */
app.all(['/api/keys', '/api/keys*'], (req, res, next) => {
    if (req.headers.authorization !== `Bearer ${ADMIN_KEY}`) return respondHttp(res, 401, 'Unauthorised operation');
    next();
});

/* create key */
app.post('/api/keys', (req, res) => {
    pool.query('INSERT INTO "auth"."Keys" DEFAULT VALUES RETURNING *;').then((result) => {
        if (result.rowCount == 0) return respondHttp(res, 500, 'Database insertion failed');
        
        keyCache.set(result.rows[0].key, true); // set in cache
        respondHttp(res, 200, result.rows[0]);
    }).catch((e) => {
        console.log(e);
        respondHttp(res, 500, `Error performing operation: ${e}`);
    });
});

/* revoke key */
app.delete('/api/keys/:key', (req, res) => {
    let key = req.params.key;
    if (!isUUID(key)) return respondHttp(res, 400, 'Invalid key format');
    pool.query('DELETE FROM "auth"."Keys" WHERE "key" = $1;', [key]).then((result) => {
        keyCache.set(key, false); // TODO: propagate cache invalidation across other instances
        respondHttp(res, 200, 'Key has been revoked');
    }).catch((e) => {
        console.log(e);
        respondHttp(res, 500, `Error performing operation: ${e}`);
    });
});

/* query key in database */
app.get('/api/keys/:key', (req, res) => {
    let key = req.params.key;
    if (!isUUID(key)) return respondHttp(res, 400, 'Invalid key format');
    pool.query('SELECT * FROM "auth"."Keys" WHERE "key" = $1', [key]).then((result) => {
        if (result.rowCount == 0) { // key doesn't exist in database
            keyCache.set(key, false);
            respondHttp(res, 404, 'Key does not exist in database');
        } else {
            respondHttp(res, 200, {
                timestamp: result.rows[0].timestamp,
                cached: (keyCache.get(key) !== undefined)
            });
            keyCache.set(key, true);
        }
    }).catch((e) => {
        console.log(e);
        respondHttp(res, 500, `Error performing operation: ${e}`);
    });
});

/* invalidate key in cache (i.e. next authorisation will be sourced from database) */
app.post('/api/keys/:key/invalidate', (req, res) => {
    if (!isUUID(key)) return respondHttp(res, 400, 'Invalid key format');
    respondHttp(res, 200, keyCache.delete(req.params.key) ? 'Key has been invalidated in cache' : 'Key is not cached');
});

const port = process.env.PORT || 3000;
app.listen(port, () => {
    console.log(`App running on port ${port}`);
});
