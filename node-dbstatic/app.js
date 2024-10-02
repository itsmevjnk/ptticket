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
const mqttOptions = {};
if (process.env.MQTT_USERNAME && process.env.MQTT_USERNAME.length > 0) {
    mqttOptions.username = process.env.MQTT_USERNAME;
    mqttOptions.password = process.env.MQTT_PASSWORD || '';
}

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

mqttClient.on('connect', () => {
    console.log('Connected to MQTT broker');
    fetchStaticData();
});
