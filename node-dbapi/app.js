/* database connection */
const Pool = require('pg').Pool;

let dbConfig = {
    user: process.env.DB_USER || 'dynamic',
    password: process.env.DB_PASS || 'ptticket_dynamic',
    host: process.env.DB_HOST || '127.0.0.1',
    port: process.env.DB_PORT || 5432,
    database: process.env.DB_NAME || 'ptticket'
};
console.log('Connecting to database with config:', dbConfig);
const pool = new Pool(dbConfig);

// TZ should be UTC because turns out node-postgress doesn't exactly like having it set to anything else to then feed it with ISO timestamps
// process.env.TZ = 'Australia/Melbourne';

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
    });
};
fetchStaticData();

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
    respondHttp(res, 200, 'Database API is functional');
});

/* static data query */
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

app.get('/api/products/:id', (req, res) => {
    let id = parseInt(req.params.id);
    if (!isNaN(id) && id >= 0 && id < staticData.products.length)
        respondHttp(res, 200, staticData.products[id]);
    else
        respondHttp(res, 400, `Invalid product ID '${req.params.id}'`);
});

app.get('/api/products/search/:a/:b', (req, res) => {
    let prodID = -1, prodDelta = Infinity;
    let products = staticData.products;
    for (let i = 0; i < products.length; i++) {
        if (products[i].fromZone <= req.params.a && products[i].toZone >= req.params.b) {
            let delta = (req.params.a - products[i].fromZone) + (products[i].toZone - req.params.b);
            if (delta < prodDelta) {
                prodID = i;
                prodDelta = delta;
            }
            if (delta == 0) break; // exit early
        }
    }

    if (prodID < 0)
        respondHttp(res, 404, `Cannot find any product for zones ${req.params.a} to ${req.params.b}`);
    else
        respondHttp(res, 200, {
            id: prodID,
            delta: prodDelta,
            details: products[prodID]
        });
});

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

app.get('/api/fareTypes/:id', (req, res) => {
    let id = parseInt(req.params.id);
    if (!isNaN(id) && id >= 0 && id < staticData.fareTypes.length)
        respondHttp(res, 200, staticData.fareTypes[id]);
    else
        respondHttp(res, 400, `Invalid fare type '${req.params.id}'`);
});

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

app.get('/api/locations/:id', (req, res) => {
    let id = parseInt(req.params.id);
    if (!isNaN(id) && id >= 0 && id < staticData.locations.length)
        respondHttp(res, 200, staticData.locations[id]);
    else
        respondHttp(res, 400, `Invalid location ID '${req.params.id}'`);
});

/* create ticket */
app.post('/api/tickets', (req, res) => {
    if (typeof req.body !== 'object')
        return respondHttp(res, 400, 'Invalid request body');

    let queryParams = ['qr', 0]; // card type and fare type
    if (req.body.hasOwnProperty('cardType')) queryParams[0] = req.body.cardType;
    if (req.body.hasOwnProperty('fareType')) queryParams[1] = parseInt(req.body.fareType);

    let pTicket = null; // we'll put the promise in here
    let queryStmt = 'WITH ticket AS (INSERT INTO "dynamic"."Tickets" ("fareType") VALUES ($2) RETURNING "id") ';
    if (req.body.hasOwnProperty('cardID')) {
        /* ticket creation with given ID */
        queryParams.push(req.body.cardID);
        queryStmt += 'INSERT INTO "dynamic"."PhysicalTickets" ("type", "ticketID", "id") SELECT $1, "id", $3';
    } else queryStmt += 'INSERT INTO "dynamic"."PhysicalTickets" ("type", "ticketID") SELECT $1, "id"';
    queryStmt += ' FROM ticket RETURNING "id", "ticketID";';

    pool.query(queryStmt, queryParams).then((results) => {
        if (results.rowCount != 1)
            return respondHttp(res, 500, 'Unexpected SQL query output');
        
        let queryResp = results.rows[0];
        respondHttp(res, 200, {
            ticketID: queryResp.ticketID,
            fareType: queryParams[1],
            cardID: queryResp.id,
            cardType: queryParams[0]
        });
    }).catch((error) => {
        respondHttp(res, 500, 'SQL operation error: ' + error);
        console.error(error);
    });
});

/* query ticket information */
app.get('/api/tickets/:id', (req, res) => {
    let queryStmt = ''; // statement
    if (req.query.hasOwnProperty('card') && req.query.card.toLowerCase() === 'true')
        queryStmt = 'SELECT ti."fareType", ti."balance", ti."dailyExpenditure", ti."touchedOn", ti."currentProduct", ti."prodValidated", ti."prodDuration", pti."id" AS "cardID", pti."type" AS "cardType", pti."expiryDate" AS "cardExpiry", pti."disabled" AS "cardDisabled" ' +
            'FROM "dynamic"."Tickets" ti ' + 
            'JOIN "dynamic"."PhysicalTickets" pti ON pti."ticketID" = ti."id" ' + 
            'WHERE ti."id" = $1 AND pti."disabled" = false;';
    else
        queryStmt = 'SELECT ti."fareType", ti."balance", ti."dailyExpenditure", ti."touchedOn", ti."currentProduct", ti."prodValidated", ti."prodDuration" ' +
            'FROM "dynamic"."Tickets" ti WHERE ti."id" = $1;';
    pool.query(queryStmt, [req.params.id]).then((results) => {
        if (results.rowCount == 0)
            return respondHttp(res, 404, `Ticket '${req.params.id}' not found`);
        else
            return respondHttp(res, 200, results.rows[0]);
    }).catch((error) => {
        respondHttp(res, 500, 'SQL operation error: ' + error);
        console.error(error);
    });
});

/* change ticket data */
app.patch('/api/tickets/:id', (req, res) => {
    if (typeof req.body !== 'object' || Object.keys(req.body).length === 0)
        return respondHttp(res, 400, 'Invalid request body');
    let queryStmt = `UPDATE "dynamic"."Tickets" SET `;
    let queryParams = [];
    for (let key of ['fareType', 'balance', 'dailyExpenditure', 'touchedOn', 'currentProduct', 'prodValidated', 'prodDuration']) {
        if (req.body.hasOwnProperty(key)) {
            queryParams.push(req.body[key]);
            queryStmt += `"${key}" = \$${queryParams.length}, `;
        }
    }
    queryParams.push(req.params.id);
    queryStmt = queryStmt.slice(0, -2) + ` WHERE "id" = \$${queryParams.length} RETURNING *;`;
    pool.query(queryStmt, queryParams).then((results) => {
        if (results.rowCount == 0)
            return respondHttp(res, 404, `Ticket '${req.params.id}' not found`);
        results.rows[0].prodExpiry = results.rows[0].productExpiry; delete results.rows[0].productExpiry; // rename
        respondHttp(res, 200, results.rows[0]);
    }).catch((error) => {
        respondHttp(res, 500, 'SQL operation error: ' + error);
        console.error(error);
    });
});

/* get ticket's daily travelled products bits */
app.get('/api/tickets/:id/prodbits', (req, res) => {
    let time = new Date(); if (time.getHours() < 3) time.setDate(time.getDate() - 1); time.setHours(3, 0, 0, 0); // start of PT day
    let queryParams = [req.params.id, time.toISOString()];
    time.setDate(time.getDate() + 1); queryParams.push(time.toISOString());
    pool.query('SELECT "product" FROM "dynamic"."Transactions" WHERE "ticketID" = $1 AND "timestamp" >= $2 AND "timestamp" < $3 AND ("type" = 1 OR "type" = 2) AND "product" != 0;', queryParams).then((results) => {
        let bits1 = Array(16).fill(0), bits2 = Array(16).fill(0);

        results.rows.forEach((entry) => {
            let prod = entry.product;
            let byte = Math.floor(prod / 8), bit = prod % 8;
            if (bits1[byte] & (1 << bit)) bits2[byte] |= (1 << bit);
            else bits1[byte] |= (1 << bit);
        });

        respondHttp(res, 200, [
            Buffer.from(bits1).toString('base64'),
            Buffer.from(bits2).toString('base64')
        ]);
    }).catch((error) => {
        respondHttp(res, 500, 'SQL operation error: ' + error);
        console.error(error);
    });
});

/* get ticket's associated card */
app.get('/api/tickets/:id/card', (req, res) => {
    let queryStmt = 'SELECT "id", "type", "expiryDate", "disabled" FROM "dynamic"."PhysicalTickets" WHERE "ticketID" = $1';
    let all = req.query.hasOwnProperty('all') && req.query.all.toLowerCase() === 'true';
    if (!all)
        queryStmt += ' AND "disabled" = false';
    queryStmt += ';';
    pool.query(queryStmt, [req.params.id]).then((results) => {
        if (results.rowCount == 0)
            return respondHttp(res, 404, `No cards associated with ticket '${req.params.id}'`);
        respondHttp(res, 200, (all) ? results.rows : results.rows[0]);
    });
});

/* generate new card for ticket */
const crypto = require('crypto');
app.post('/api/tickets/:id/card', (req, res) => {
    let newType = (typeof req.body === 'object' && req.body.hasOwnProperty('newType')) ? req.body.newType : null; // new card type

    /* get existing card */
    pool.query('SELECT "type", "disabled" FROM "dynamic"."PhysicalTickets" WHERE "ticketID" = $1;', [req.params.id]).then((results) => {
        if (results.rowCount > 0) {
            /* there's an existing card */
            let cardType = newType || (results.rows.find((e) => !e.disabled) || results.rows[results.rows.length - 1]).type; // TODO: this may not guarantee the correct current card type
            pool.connect().then((client) => { // get ourselves a client
                client.query('BEGIN;').then((results) => { // begin transaction
                    return client.query('UPDATE "dynamic"."PhysicalTickets" SET "disabled" = true WHERE "id" = $1;', [req.params.id]).then((results) => { // disable all cards. NOTE: return is needed to form chain
                        let cardID = crypto.randomUUID();
                        return client.query('INSERT INTO "dynamic"."PhysicalTickets" ("id", "type", "ticketID") VALUES ($1, $2, $3);', [cardID, cardType, req.params.id])
                        .then((results) => { // create new card
                            return client.query('COMMIT;').then((results) => respondHttp(res, 200, { // commit transaction
                                cardID: cardID,
                                cardType: cardType
                            }));
                        });
                    });
                }).catch((e) => {
                    client.query('ROLLBACK;');
                    throw e;
                }).finally(() => client.release()); // release client when we're done
            });
        } else {
            /* there are no cards - check if ticket exists at all */
            pool.query('SELECT 1 FROM "dynamic"."Tickets" WHERE "ticketID" = $1;', [req.params.id]).then((results) => {
                if (results.rowCount == 0)
                    return respondHttp(res, 404, `Ticket '${req.params.id}' does not exist`);
                if (newType === null)
                    return respondHttp(res, 400, `Ticket '${req.params.id}' does not have a card, but no new card type has been given`);
                pool.query('INSERT INTO "dynamic"."PhysicalTickets" ("type", "ticketID") VALUES ($1, $2) RETURNING "id";', [newType, req.params.id])
                    .then((results) => respondHttp(res, 200, {
                        cardID: results.rows[0].id,
                        cardType: newType
                    })); // create new card
            });
        }
    }).catch((error) => {
        respondHttp(res, 500, 'SQL operation error: ' + error);
        console.error(error);
    }); // we only need one to catch everything
});

/* disable card associated with ticket */
app.delete('/api/tickets/:id/card', (req, res) => {
    pool.query('UPDATE "dynamic"."PhysicalTickets" SET "disabled" = true WHERE "ticketID" = $1', [req.params.id]).then((results) => {
        if (results.rowCount == 0)
            respondHttp(res, 404, `Ticket '${req.params.id}' not found`);
        else
            respondHttp(res, 200, `All cards associated with ticket '${req.params.id}' have been disabled`);
    });
});

/* query card information */
app.get('/api/cards/:type/:id', (req, res) => {
    let queryStmt = 'SELECT pti."ticketID"'; // query statement
    if (req.query.hasOwnProperty('idOnly') && req.query.idOnly.toLowerCase() === 'true')
        queryStmt += ' FROM "dynamic"."PhysicalTickets" pti'; // get ID only
    else
        queryStmt += ', pti."expiryDate", pti."disabled", ti."fareType", ti."balance", ti."dailyExpenditure", ti."touchedOn", ti."currentProduct", ti."prodValidated", ti."prodDuration" ' + 
            'FROM "dynamic"."PhysicalTickets" pti ' +
            'JOIN "dynamic"."Tickets" ti ON pti."ticketID" = ti."id"';
    queryStmt += ' WHERE pti."id" = $2 AND pti."type" = $1';
    pool.query(queryStmt, [req.params.type, req.params.id]).then((results) => {
        if (results.rowCount == 0)
            respondHttp(res, 404, `Card ${req.params.type}/${req.params.id} not found`);
        else
            respondHttp(res, 200, results.rows[0]);
    }).catch((error) => {
        respondHttp(res, 500, 'SQL operation error: ' + error);
        console.error(error);
    });
});

/* disable card associated with ticket */
app.delete('/api/cards/:type/:id', (req, res) => {
    pool.query('UPDATE "dynamic"."PhysicalTickets" SET "disabled" = true WHERE "type" = $1 AND "id" = $2', [req.params.type, req.params.id]).then((results) => {
        if (results.rowCount == 0)
            respondHttp(res, 404, `Card ${req.params.type}/${req.params.id} not found`);
        else
            respondHttp(res, 200, `Card ${req.params.type}/${req.params.id} has been disabled`);
    }).catch((error) => {
        respondHttp(res, 500, 'SQL operation error: ' + error);
        console.error(error);
    });
});

/* get transactions associated with ticket */
app.get('/api/tickets/:id/transactions', (req, res) => {
    let queryStmt = 'SELECT "id", "timestamp", "type", "location", "product", "balance" FROM "dynamic"."Transactions" WHERE "ticketID" = $1'; // base query
    let queryParams = [req.params.id];
    if (req.query.hasOwnProperty('validateOnly') && req.query.validateOnly.toLowerCase() === 'true')
        queryStmt += ' AND "type" <= 2'; // touch on/off only
    queryStmt += ' ORDER BY "timestamp" DESC';
    if (req.query.hasOwnProperty('limit') && !isNaN(req.query.limit)) {
        queryParams.push(req.query.limit);
        queryStmt += ' LIMIT $2';
    }
    queryStmt += ';'; // terminate

    pool.query(queryStmt, queryParams).then((results) => {
        respondHttp(res, 200, results.rows);
    }).catch((error) => {
        respondHttp(res, 500, 'SQL operation error: ' + error);
        console.error(error);
    });
});

/* get transaction details */
app.get('/api/tickets/:id/transactions/:tid', (req, res) => {
    pool.query(
        'SELECT "id", "timestamp", "type", "location", "product", "balance" FROM "dynamic"."Transactions" WHERE "id" = $2 AND "ticketID" = $1;',
        [req.params.id, req.params.tid]
    ).then((results) => {
        if (results.rowCount == 0)
            respondHttp(res, 404, `Transaction '${req.params.tid}' for ticket '${req.params.id}' not found`);
        else
            respondHttp(res, 200, results.rows[0]);
    }).catch((error) => {
        respondHttp(res, 500, 'SQL operation error: ' + error);
        console.error(error);
    });
});

/* add transaction */
app.post('/api/tickets/:id/transactions', (req, res) => {
    let ok = true; // set if we can proceed
    let queryParams = [
        req.params.id, // ticketID
    ];
    let pass = false; // set if we're adding passes
    if (typeof req.body === 'object') {
        /* for adding pre-performed transactions */
        queryParams.push((req.body.hasOwnProperty('id') && typeof req.body.id === 'string') ? req.body.id : crypto.randomUUID()); // [1]: transaction ID
        queryParams.push((req.body.hasOwnProperty('timestamp') && typeof req.body.timestamp === 'string') ? req.body.timestamp : (new Date()).toISOString()); // [2]: timestamp
        queryParams.push((req.body.hasOwnProperty('product') && typeof req.body.product === 'number') ? req.body.product : 0); // [3]: product ID
        
        /* required params */
        if (req.body.hasOwnProperty('type') && typeof req.body.type === 'number')
            queryParams.push(req.body.type); // [4]: transaction type
        else ok = false;
        if (req.body.hasOwnProperty('location') && typeof req.body.location === 'number')
            queryParams.push(req.body.location); // [5]: location ID
        else ok = false;
        if (req.body.hasOwnProperty('balance') && typeof req.body.balance === 'number')
            queryParams.push(req.body.balance); // [6]: balance
        else ok = false;

        if (req.body.type == 5) {
            /* pass purchase */
            if (req.body.hasOwnProperty('pass') && typeof req.body.pass === 'object') {
                if (req.body.pass.hasOwnProperty('duration') && typeof req.body.pass.duration === 'number')
                    queryParams.push(req.body.pass.duration); // [7]: pass duration
                else ok = false;
                if (req.body.pass.hasOwnProperty('product') && typeof req.body.pass.product === 'number')
                    queryParams.push(req.body.pass.product); // [8]: pass product ID
                else ok = false;

                pass = true;
            } else ok = false;
        }
    } else ok = false;

    if (!ok) return respondHttp(res, 400, 'Invalid request body');

    let promise = null; // promise after transaction insertion
    if (pass) {
        /* pass purchase - SQL transaction incoming */
        promise = pool.connect().then((client) => { // get ourselves a client
            return client.query('BEGIN;').then((results) => { // begin transaction
                return client.query(
                    'INSERT INTO "dynamic"."Transactions" ' + 
                    '("id", "ticketID", "timestamp", "type", "location", "product", "balance") ' +
                    'VALUES ($2, $1, $3, $5, $6, $4, $7) ' +
                    'RETURNING "id", "timestamp", "type", "location", "product", "balance";',
                    queryParams.slice(0, 7)
                ).then((results) => { // insert transaction
                    return client.query(
                        'INSERT INTO "dynamic"."Passes" ("transactionID", "ticketID", "duration", "product") VALUES ($1, $2, $3, $4);',
                        [queryParams[1], queryParams[0], queryParams[7], queryParams[8]]
                    ).then((results) => { // create new pass
                        return client.query('COMMIT;'); // commit transaction
                    });
                });
            }).catch((e) => {
                client.query('ROLLBACK;');
                throw e;
            }).finally(() => client.release()); // release client when we're done
        }).then(() => {
            return pool.query(
                'SELECT t."id", t."timestamp", t."type", t."location", t."product", t."balance", p."duration" AS "passDuration", p."product" AS "passProduct"' +
                'FROM "dynamic"."Transactions" t ' +
                'JOIN "dynamic"."Passes" p ON t."id" = p."transactionID" ' +
                'WHERE t."id" = $1;',
                [queryParams[1]]
            );
        });
    } else {
        promise = pool.query(
            'INSERT INTO "dynamic"."Transactions" ' + 
            '("id", "ticketID", "timestamp", "type", "location", "product", "balance") ' +
            'VALUES ($2, $1, $3, $5, $6, $4, $7) ' +
            'RETURNING "id", "timestamp", "type", "location", "product", "balance";',
            queryParams.slice(0, 7)
        );
    }

    promise.then((results) => {
        if (results.rowCount == 0)
            return respondHttp(res, 500, 'Transaction not recorded');

        let payload = results.rows[0];
        if (payload.hasOwnProperty('passProduct')) {
            payload.pass = {
                duration: payload.passDuration,
                product: payload.passProduct
            };
            delete payload.passDuration;
            delete payload.passProduct;
        }

        respondHttp(res, 200, payload);
    }).catch((error) => {
        respondHttp(res, 500, 'SQL operation error: ' + error);
        console.error(error);
    });
});

/* get passes associated with ticket */
app.get('/api/tickets/:id/passes', (req, res) => {
    let queryStmt = 'SELECT p."transactionID", p."duration", p."activationDate", p."product" ' +
        'FROM "dynamic"."Passes" p ' +
        'JOIN "dynamic"."Transactions" t ON t."id" = p."transactionID" ' +
        'WHERE t."ticketID" = $1 ';
    
    if (!(req.query.hasOwnProperty('all') && req.query.all.toLowerCase() === 'true'))
        queryStmt += 'AND (p."activationDate" IS NULL OR p."activationDate" + p."duration" * INTERVAL \'1 day\' > CURRENT_DATE) '; // only retrieve unactivated or unexpired ones

    queryStmt += 'ORDER BY t."timestamp" DESC;';

    pool.query(queryStmt, [req.params.id]).then((results) => {
        respondHttp(res, 200, results.rows);
    }).catch((error) => {
        respondHttp(res, 500, 'SQL operation error: ' + error);
        console.error(error);
    });
});

/* get pass details */
app.get('/api/tickets/:id/passes/:tid', (req, res) => {
    pool.query(
        'SELECT p."transactionID", p."duration", p."activationDate", p."product" ' +
        'FROM "dynamic"."Passes" p ' +
        'JOIN "dynamic"."Transactions" t ON t."id" = p."transactionID" ' +
        'WHERE t."ticketID" = $1 AND p."transactionID" = $2;',
        [req.params.id, req.params.tid]
    ).then((results) => {
        if (results.rowCount == 0)
            respondHttp(res, 404, `Pass '${req.params.tid}' for ticket '${req.params.id}' not found`);
        else
            respondHttp(res, 200, results.rows[0]);
    }).catch((error) => {
        respondHttp(res, 500, 'SQL operation error: ' + error);
        console.error(error);
    });
});

/* activate pass */
app.post('/api/tickets/:id/passes/:tid', (req, res) => {
    let queryStmt = 'UPDATE "dynamic"."Passes" SET "activationDate" = ';
    let queryParams = [];
    if (typeof req.body === 'object' && req.body.hasOwnProperty('date')) {
        queryParams.push(req.body.date);
        queryStmt += '$1';
    } else queryStmt += 'CURRENT_DATE';
    queryStmt += ' WHERE "ticketID" = $ticketID AND "transactionID" = $transID AND "activationDate" IS NULL RETURNING "ticketID", "transactionID", "activationDate";';
    pool.query(queryStmt, queryParams).then((results) => {
        if (results.rowCount == 0)
            respondHttp(res, 404, `Pass '${req.params.tid}' for ticket '${req.params.id}' not found or already activated`);
        else
            respondHttp(res, 200, results.rows[0]);
    }).catch((error) => {
        respondHttp(res, 500, 'SQL operation error: ' + error);
        console.error(error);
    });
});

const port = process.env.PORT || 3000;
app.listen(port, () => {
    console.log(`App running on port ${port}`);
});
