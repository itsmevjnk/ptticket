/* database connection */
const Pool = require('pg').Pool;

let dbConfig = {
    user: process.env.DB_USER || 'static',
    password: process.env.DB_PASS || 'ptticket_static',
    host: process.env.DB_HOST || '127.0.0.1',
    port: process.env.DB_PORT || 5432,
    database: process.env.DB_NAME || 'ptticket'
};
console.log('Connecting to database with config:', dbConfig);
const pool = new Pool(dbConfig);

// TZ should be UTC because turns out node-postgress doesn't exactly like having it set to anything else to then feed it with ISO timestamps
process.env.TZ = 'UTC';

/* MQTT connection */
const mqtt = require('mqtt');
const mqttOptions = {
    username: process.env.MQTT_USERNAME || 'mqadmin',
    password: process.env.MQTT_PASSWORD || 'mqadmin'
};

const fs = require('fs');
const CA_CERT_PATH = process.env.MQTT_CA_CERT || '/ca.crt';
try {
    mqttOptions.ca = fs.readFileSync(CA_CERT_PATH); // supply CA certificate if one exists
    console.log(`Using MQTT via SSL/TLS (MQTTS) with CA certificate at ${CA_CERT_PATH}.`);
} catch (err) {
    console.warn(`Cannot open CA certificate at ${CA_CERT_PATH}, proceeding with insecure MQTT.`);
}
let isMQTTS = mqttOptions.hasOwnProperty('ca');

const mqttClient = mqtt.connect(`${isMQTTS ? 'mqtts' : 'mqtt'}://${process.env.MQTT_HOST || '127.0.0.1'}:${process.env.MQTT_PORT || (isMQTTS ? 8883 : 1883)}`, mqttOptions);

/* static data fetching */
let staticData = null;
const cron = require('node-cron');
let cronSet = false;
const fetchStaticData = () => {
    const newData = {};
    
    let timestampUTC = new Date(); // timestamp in UTC
    let timestamp = new Date(timestampUTC.toLocaleString('en-US', { timeZone: 'Australia/Melbourne' })); // timestamp in AEST/AEDT
    let tzOffset = (Math.floor(timestamp.getTime() / 1000) - Math.floor(timestampUTC.getTime() / 1000)) / 3600; // get timezone offset in hours
    console.log(`Time zone offset: ${(tzOffset >= 0) ? '+' : ''}${tzOffset} hr`);
    let date = timestamp.getFullYear() + '-' + (timestamp.getMonth() + 1) + '-' + timestamp.getDate(); // get date string
    console.log(`Querying applicable special dates for ${date}.`);
    let pDate = pool.query(
        'SELECT bit_or("dateCondition") AS "cond" FROM "static"."SpecialDates" WHERE "from" >= $1 AND "to" <= $1;',
        [date]
    ).then((results) => {
        newData.dateCondition = results.rows[0].cond || 0;
        if (timestamp.getDay() == 0 || timestamp.getDay() == 6) newData.dateCondition |= 1; // weekend
        
        // 1a.1
        console.log(`Querying fare types and their caps on date condition ${newData.dateCondition}.`);
        let pFareTypeCap = pool.query(
            'SELECT fc."type", ft."name" AS "name", fc."cap" FROM ' +
            '(SELECT dfc."fareType" AS "type", MIN(dfc."fareCap") AS "cap" FROM "static"."DailyFareCaps" dfc WHERE dfc."dateCondition" = 0 OR $1 & dfc."dateCondition" != 0 GROUP BY "type") fc ' +
            'JOIN "static"."FareTypes" ft ON fc."type" = ft."type";',
            [newData.dateCondition]
        ).then((results) => {
            let fareTypes = Array(results.rowCount).fill(null);
            results.rows.forEach((entry) => {
                fareTypes[entry.type] = {
                    name: entry.name,
                    cap: entry.cap,
                    productFares: null
                };
            });
            newData.fareTypes = fareTypes;
        }); // get fare types and fare caps

        // 1a.2
        console.log(`Getting product fares on date condition ${newData.dateCondition}.`);
        let pProdFares = pool.query(
            'SELECT "productID", "fareType", MIN("fare") AS "fare" FROM "static"."ProductFares" WHERE "dateCondition" = 0 OR $1 & "dateCondition" != 0 GROUP BY "productID", "fareType";',
            [newData.dateCondition]
        ).then((results) => newData.prodFares = results.rows); // get product fares

        return Promise.all([pFareTypeCap, pProdFares]);
    });

    console.log('Getting products list.');
    let pProd = pool.query(
        'SELECT * FROM "static"."Products";'
    ).then((results) => {
        let products = Array(results.rowCount).fill(null);
        results.rows.forEach((entry) => {
            products[entry.id] = {
                name: entry.name,
                fromZone: entry.fromZone,
                toZone: entry.toZone,
                duration: entry.duration
            };
        });
        newData.products = products;
    });

    console.log('Getting transaction type list.');
    let pTypes = pool.query(
        'SELECT * FROM "static"."TransactionTypes";'
    ).then((results) => {
        let types = Array(results.rowCount).fill(null);
        results.rows.forEach((entry) => types[entry.type] = entry.name);
        newData.transactionTypes = types;
    });

    console.log('Getting list of ticketing locations.');
    let pLocations = pool.query(
        'SELECT * FROM "static"."Locations" ORDER BY "id" ASC;'
    ).then((results) => newData.locations = results.rows);

    // 1 (1a.1+2 + 1b)
    let pFareTypes = Promise.all([pDate, pProd]).then(() => {
        newData.fareTypes.forEach((entry) => entry.productFares = Array(newData.products.length).fill(0));
        newData.prodFares.forEach((entry) => newData.fareTypes[entry.fareType].productFares[entry.productID] = entry.fare);
        delete newData.prodFares;
    });

    // 1+2+3
    Promise.all([pFareTypes, pTypes, pLocations]).then(() => {
        if (timestamp.getHours() >= 3) timestamp.setDate(timestamp.getDate() + 1);
        timestamp.setHours(3 - tzOffset, 0, 0, 0); // 3am AEST/AEDT
        timestamp = new Date(timestamp.toLocaleString('en-US', { timeZone: 'UTC' }));
        newData.expiry = timestamp;
        staticData = newData;

        // console.log(`New static data (expires on ${staticData.expiry}):`, staticData);
        console.log('New static data fetched successfully, expiry timestamp:', staticData.expiry.toString());

        if (!cronSet) {
            let cronStr = `0 0 ${timestamp.getHours()} * * *`;
            cron.schedule(cronStr, fetchStaticData); // schedule static data fetching at 3AM every day
            console.log(`Static data refresh scheduled with cron string ${cronStr}`);
            cronSet = true;
        }

        mqttClient.publish('static', JSON.stringify(staticData), { retain: true }, (err) => {
            if (err) console.error('Cannot publish static data over MQTT:', err);
            else console.log('Published static data via MQTT');
        });
    });
};

mqttClient.on('connect', () => fetchStaticData());

const staticExpired = () => {
    return (staticData === null) || (staticData.expiry < new Date());
};

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

/* gatekeeping middleware for database cache expiry checks */
app.all('*', (req, res, next) => {
    if (staticExpired()) respondHttp(res, 503, 'Static database cache expired');
    else next();
});

/* health check */
app.get('/api/healthcheck', (req, res) => {
    respondHttp(res, 200, 'Static database API is functional');
});

/* REST static data query - MQTT preferred */
app.get('/api/static', (req, res) => { // query entire dataset
    respondHttp(res, 200, staticData);
});

app.get('/api/products', (req, res) => {
    let products = staticData.products;
    if (req.query.hasOwnProperty('hideZones') && req.query.hideZones.toLowerCase() === 'true') {
        products = [];
        staticData.products.forEach((entry) => products.push(entry.name));
    }
    if (req.query.hasOwnProperty('dict') && req.query.dict.toLowerCase() === 'true')
        products = Object.assign({}, products);

    respondHttp(res, 200, products);
});

// app.get('/api/products/:id', (req, res) => {
//     let id = parseInt(req.params.id);
//     if (!isNaN(id) && id >= 0 && id < staticData.products.length)
//         respondHttp(res, 200, staticData.products[id]);
//     else
//         respondHttp(res, 400, `Invalid product ID '${req.params.id}'`);
// });

// app.get('/api/products/search/:a/:b', (req, res) => {
//     let prodID = -1, prodDelta = Infinity;
//     let products = staticData.products;
//     for (let i = 0; i < products.length; i++) {
//         if (products[i].fromZone <= req.params.a && products[i].toZone >= req.params.b) {
//             let delta = (req.params.a - products[i].fromZone) + (products[i].toZone - req.params.b);
//             if (delta < prodDelta) {
//                 prodID = i;
//                 prodDelta = delta;
//             }
//             if (delta == 0) break; // exit early
//         }
//     }

//     if (prodID < 0)
//         respondHttp(res, 404, `Cannot find any product for zones ${req.params.a} to ${req.params.b}`);
//     else
//         respondHttp(res, 200, {
//             id: prodID,
//             delta: prodDelta,
//             details: products[prodID]
//         });
// });

app.get('/api/fareTypes', (req, res) => {
    let types = staticData.fareTypes;
    if (req.query.hasOwnProperty('hideFares') && req.query.hideFares.toLowerCase() === 'true') {
        types = [];
        staticData.fareTypes.forEach((entry) => types.push(entry.name));
    }
    if (req.query.hasOwnProperty('dict') && req.query.dict.toLowerCase() === 'true')
        types = Object.assign({}, types);

    respondHttp(res, 200, types);
});

// app.get('/api/fareTypes/:id', (req, res) => {
//     let id = parseInt(req.params.id);
//     if (!isNaN(id) && id >= 0 && id < staticData.fareTypes.length)
//         respondHttp(res, 200, (req.query.hasOwnProperty('hideFares') && req.query.hideFares.toLowerCase() === 'true') ? staticData.fareTypes[id].name : staticData.fareTypes[id]);
//     else
//         respondHttp(res, 400, `Invalid fare type '${req.params.id}'`);
// });

app.get('/api/transactionTypes', (req, res) => {
    let types = staticData.transactionTypes;
    if (req.query.hasOwnProperty('dict') && req.query.dict.toLowerCase() === 'true')
        types = Object.assign({}, types);

    respondHttp(res, 200, types);
});

app.get('/api/locations', (req, res) => {
    let locations = staticData.locations;
    if (req.query.hasOwnProperty('dict') && req.query.dict.toLowerCase() === 'true')
        locations = Object.assign({}, locations);

    respondHttp(res, 200, locations);
});

// app.get('/api/locations/:id', (req, res) => {
//     let id = parseInt(req.params.id);
//     if (!isNaN(id) && id >= 0 && id < staticData.locations.length)
//         respondHttp(res, 200, staticData.locations[id]);
//     else
//         respondHttp(res, 400, `Invalid location ID '${req.params.id}'`);
// });

const port = process.env.PORT || 3000;
app.listen(port, () => {
    console.log(`Static database caching service running on port ${port}`);
});
