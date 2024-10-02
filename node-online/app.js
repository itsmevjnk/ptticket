const DATABASE_API = process.env.DATABASE_API || 'http://127.0.0.1:3101/api';
console.log(`Database API URL set to ${DATABASE_API}`);
process.env.TZ = 'Australia/Melbourne';

const UPSTREAM_API = process.env.UPSTREAM_API || null;
const TOKEN = process.env.TOKEN || null; // API token for contacting upstream transaction server
if (UPSTREAM_API !== null) console.log('This instance is deployed OUTSIDE of the central server - per instance caching will be performed!');

/* static data pulled off MQTT */
let staticData = null;

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

const mqttClient = require('mqtt').connect(`${isMQTTS ? 'mqtts' : 'mqtt'}://${process.env.MQTT_HOST || '127.0.0.1'}:${process.env.MQTT_PORT || (isMQTTS ? 8883 : 1883)}`, mqttOptions);
mqttClient.on('message', (topic, message) => {
    staticData = JSON.parse(message);
    console.log('Received static data from upstream, expiry timestamp:', new Date(staticData.expiry).toString());
});
mqttClient.on('connect', () => {
    console.log('Connected to MQTT broker for static data');
    mqttClient.subscribe('static');
});

/* database write queue - for outside deployments only */
const dbTicketWriteQueue = {};
const dbTransactionQueue = {};

let _upstreamOK = { value: true };
const upstreamOK = new Proxy(_upstreamOK, {
    set(target, key, value) {
        if (value != _upstreamOK.value) {
            if (value) {
                /* upstream server OK */
                console.log('Upstream server is good again');

                let idCache = new Map();

                /* flush ticket write queue */
                for (let [id, data] of Object.entries(dbTicketWriteQueue)) {
                    let pResolveID = (id.includes('/')) ? axios.get(`/api/cards/${id}?idOnly=true`) : new Promise((resolve, reject) => {
                        resolve({
                            status: 200,
                            message: {
                                ticketID: id
                            }
                        });                        
                    });
                    pResolveID.then((resp) => {
                        if (resp.status != 200) return console.error(`Ticket ID query for ${id} failed: ${resp.status} ${resp.data.message}`);
                        
                        let ticketID = resp.data.message.ticketID;
                        idCache.set(id, ticketID);

                        console.log(`Writing ticket ${ticketID}`);
                        return axios.patch(`${DATABASE_API}/tickets/${ticketID}`, data)
                        .then((resp) => {
                            if (resp.status != 200)
                                console.error(`Cannot write data for ticket ${ticketID}: ${resp.status} ${resp.data.message}`);
                            else delete dbTicketWriteQueue[ticketID];
                        });
                    }).catch((err) => value = _upstreamOK.value = false);
                }

                /* flush transaction write queue */
                for (let [id, data] of Object.entries(dbTransactionQueue)) {
                    let pResolveID = (idCache.has(id))
                        ? new Promise((resolve, reject) => {
                            resolve({
                                status: 200,
                                message: {
                                    ticketID: idCache.get(id)
                                }
                            });                        
                        }) : (
                            (id.includes('/')) ? axios.get(`/api/cards/${id}?idOnly=true`) : new Promise((resolve, reject) => {
                                resolve({
                                    status: 200,
                                    message: {
                                        ticketID: id
                                    }
                                });                        
                            })
                        );

                    pResolveID.then((resp) => {
                        if (resp.status != 200) return console.error(`Ticket ID query for ${id} failed: ${resp.status} ${resp.data.message}`);
                        
                        let ticketID = resp.data.message.ticketID;
                        idCache.set(id, ticketID);

                        let details = {
                            id: id,
                            timestamp: data.timestamp,
                            ...data.details
                        };
                        console.log(`Writing transaction ${id} for ${ticketID}`);
                        return axios.post(`${DATABASE_API}/tickets/${ticketID}/transactions`, details)
                            .then((resp) => {
                                if (resp.status != 200)
                                    console.error(`Cannot write transaction ${id} for ${ticketID}: ${resp.status} ${resp.data.message}`);
                                else delete dbTransactionQueue[id];
                            });
                    }).catch((err) => value = _upstreamOK.value = false);
                }
            } else {
                /* upstream server down */
                console.warn('Upstream server is down');
            }
        }
        return Reflect.set(...arguments);
    }
});

let upstreamCheck = null;
const resetUpstreamCheck = () => {
    if (UPSTREAM_API === null) return; // no upstream checks if deployed inside central server
    if (upstreamCheck) clearInterval(upstreamCheck);
    upstreamCheck = setInterval(() => {
        axios.get(`${UPSTREAM_API}/healthcheck`).then((resp) => {
            upstreamOK.value = (resp.status == 200);
        }).catch((err) => {
            upstreamOK.value = false;
        });
    }, 15000); // health check every 15 sec
};
resetUpstreamCheck();

const express = require('express');
const axios = require('axios').create({
    headers: {
        'Authorization': (TOKEN !== null) ? ('Bearer ' + TOKEN) : undefined
    },
    validateStatus: () => true
});

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
    axios.get(`${DATABASE_API}/healthcheck`).then((resp) => {
        if (resp.status != 200) {
            respondHttp(res, (TOKEN) ? 299 : 500, `Upstream database API health check failed (status code ${resp.status})`); // NOTE: 299 is our custom status code to indicate that we can't process anything other than smart cards
            upstreamOK.value = false;
        } else {
            respondHttp(res, 200, 'Online transaction API is functional');
            upstreamOK.value = true;
        }
    }).catch((err) => {
        respondHttp(res, (TOKEN) ? 299 : 500, `Upstream database API health check failed (status code ${err.code})`); // NOTE: 299 is our custom status code to indicate that we can't process anything other than smart cards
        upstreamOK.value = false;
    })
});

/* check if enough data is given for ticket validation and extract data from it */
const extractValidateRequest = (body) => {
    let ret = {}; // make return object

    if (typeof body !== 'object') return null; // body is not an object (e.g. parse error)

    if (body.hasOwnProperty('card') == body.hasOwnProperty('ticketID')) return null; // can't have both card and ticket ID or none of them
    else if (body.hasOwnProperty('card')) {
        /* card given */
        if (typeof body.card !== 'object' || typeof body.card.type !== 'string' || typeof body.card.id !== 'string') return null; // invalid card specification
        
        let validateData = true;
        if (body.card.hasOwnProperty('skipValidation')) {
            if (typeof body.card.skipValidation !== 'boolean') return null; // invalid skipValidation
            else validateData = false;
        }

        if (validateData) {
            /* check if data provided is valid */
            if (
                typeof body.card.fareType !== 'number'
                || typeof body.card.balance !== 'number'
                || typeof body.card.dailyExpenditure !== 'number' || body.card.dailyExpenditure < 0
                || typeof body.card.currentProduct !== 'number' || body.card.currentProduct < 0
                || typeof body.card.touchedOn !== 'number' || body.card.touchedOn < 0
                || typeof body.card.prodValidated !== 'string'
                || typeof body.card.prodDuration !== 'number'
                || !Array.isArray(body.card.passes) || body.card.passes.length > 2
                || !Array.isArray(body.card.prodBits) || body.card.prodBits.length != 2
                || typeof body.card.prodBits[0] !== 'string' || typeof body.card.prodBits[1] !== 'string'
            ) return null;

            /* check passes */
            for (let pass of body.card.passes) {
                if (
                    typeof pass.transactionID !== 'string'
                    || typeof pass.product !== 'number'
                    || !(pass.hasOwnProperty('duration') ^ pass.hasOwnProperty('expiryDate'))
                    || (pass.hasOwnProperty('duration') && typeof pass.duration !== 'number')
                    || (pass.hasOwnProperty('expiryDate') && typeof pass.expiryDate !== 'string')
                ) return null;
            }

            ret.cardVerify = body.card;
        }

        ret.card = body.card;
    }
    else if (typeof body.ticketID !== 'string') return null;
    else ret.ticketID = body.ticketID;
    
    if (typeof body.location !== 'number') return null; // no location
    ret.location = body.location;

    ret.direction = { entry: true, exit: true }; // default direction
    if (body.hasOwnProperty('direction')) {
        /* gate direction given */
        if (typeof body.direction !== 'object') return null; // but it's invalid

        if (body.direction.hasOwnProperty('entry')) {
            if (typeof body.direction.entry !== 'boolean') return null;
            ret.direction.entry = body.direction.entry;
        }

        if (body.direction.hasOwnProperty('exit')) {
            if (typeof body.direction.exit !== 'boolean') return null;
            ret.direction.exit = body.direction.exit;
        }
    }
    ret.direction.entryOnly = ret.direction.entry && !ret.direction.exit;
    ret.direction.exitOnly = ret.direction.exit && !ret.direction.entry;

    return ret;
};

/* request card information */
const getCardInfo = (type, id) => axios.get(`${DATABASE_API}/cards/${type}/${id}`);

/* request ticket information */
const getTicketInfo = (id) => axios.get(`${DATABASE_API}/tickets/${id}`);

/* request last transaction */
const getLastTransaction = (id) => axios.get(`${DATABASE_API}/tickets/${id}/transactions?validateOnly=true&limit=1`);

/* request pass information */
const getPasses = (id) => axios.get(`${DATABASE_API}/tickets/${id}/passes`);

/* activate pass */
const activatePass = (ticketID, passID, date) => axios.post(`${DATABASE_API}/tickets/${ticketID}/passes/${passID}`, { date: date });

/* request product bits */
const getProdBits = (id) => axios.get(`${DATABASE_API}/tickets/${id}/prodbits`);

/* disable card */
const blockCard = (type, id) => axios.delete(`${DATABASE_API}/cards/${type}/${id}`);

/* get location details */
const getLocDetails = (id) => {
    const sLocations = staticData.locations;
    if (!isNaN(id) && id >= 0 && id < sLocations.length)
        return sLocations[id];
    else return null;
};

/* get product details */
const getProdDetails = (id) => {
    const sProducts = staticData.products;
    if (!isNaN(id) && id >= 0 && id < sProducts.length)
        return sProducts[id];
    else return null;
}


/* get fare type details */
const getFareTypeDetails = (id) => {
    const sFareTypes = staticData.fareTypes;
    if (!isNaN(id) && id >= 0 && id < sFareTypes.length)
        return sFareTypes[id];
    else return null;
};

/* search product covering zones */
const searchProduct = (from, to) => {
    const sProducts = staticData.products;
    let prodID = -1, prodDelta = Infinity;
    for (let i = 0; i < sProducts.length; i++) {
        if (sProducts[i].fromZone <= from && sProducts[i].toZone >= to) {
            let delta = (from - sProducts[i].fromZone) + (sProducts[i].toZone - to);
            if (delta < prodDelta) {
                prodID = i;
                prodDelta = delta;
            }
            if (delta == 0) break; // exit early
        }
    }

    if (prodID < 0) return null;
    else return {
        id: prodID,
        delta: prodDelta,
        details: sProducts[prodID]
    };
};

/* set bit in base64 bitmap */
const b64Set = (bitmap, bit) => {
    let buf = Buffer.from(bitmap, 'base64');
    buf[Math.floor(bit / 8)] |= 1 << (bit % 8);
    return buf.toString('base64');
};

/* test bit in base64 bitmap */
const b64Test = (bitmap, bit) => {
    let buf = Buffer.from(bitmap, 'base64');
    return (buf[Math.floor(bit / 8)] & 1 << (bit % 8)) != 0;
};

/* generic respond */
const respondValidate = (res, code, state, text, transaction, details) => {
    respondHttp(res, code, {
        state: state,
        text: text,
        transaction: transaction,
        details: details
    });
};

/* response - card blocked */
const respondBlocked = (res, details) => respondValidate(res, 403, 'blocked', 'Card blocked - please contact support', null, details);

/* response - ticket expired */
const respondExpired = (res, details) => respondValidate(res, 403, 'expired', 'Ticket expired - time to get a new one', null, details);

/* response - negative balance */
const respondNegBalance = (res, details) => respondValidate(res, 403, 'negBalance', 'Negative balance', null, details);

/* write ticket data */
const writeTicketData = (res, id, details) => {
    // console.log('writeTicketData');
    return axios.patch(
        `${DATABASE_API}/tickets/${id}`,
        {
            fareType: details.fareType,
            balance: details.balance,
            dailyExpenditure: details.dailyExpenditure,
            touchedOn: details.touchedOn,
            currentProduct: details.currentProduct,
            prodValidated: details.prodValidated,
            prodDuration: details.prodDuration
        }
    ).then((resp) => {
        // console.log(resp.status, resp.data);
        if (resp.status != 200) return respondHttp(res, resp.status, resp.data.message);
        return resp;
    }).catch((err) => {
        // console.error(err);
        if (UPSTREAM_API !== null) {
            dbTicketWriteQueue[id] = Object.assign(dbTicketWriteQueue.hasOwnProperty(id) ? dbTicketWriteQueue[id] : {}, details);
            console.log(`Added ticket data write for ${id} to queue`);
            return {
                status: 200,
                message: dbTicketWriteQueue[id] // TODO: does this matter?
            };
        } else return respondHttp(res, 503, `Cannot connect to database server (${err.code})`);
    });
};

/* write transaction */
const crypto = require('crypto');
const writeTransaction = (res, id, trans) => {
    return axios.post(
        `${DATABASE_API}/tickets/${id}/transactions`,
        trans
    ).then((resp) => {
        if (resp.status != 200) return respondHttp(res, resp.status, resp.data.message);
        return resp;
    }).catch((err) => {
        if (UPSTREAM_API !== null) {
            let transID = crypto.randomUUID();
            let transObj = {
                ticketID: id,
                timestamp: new Date().toISOString(),
                details: trans
            };
            dbTransactionQueue[transID] = transObj;
            console.log(`Added ticket data write for ${id} to queue`);
            return {
                status: 200,
                message: {
                    id: transID,
                    timestamp: transObj.timestamp,
                    type: trans.type,
                    location: trans.location,
                    product: trans.product,
                    balance: trans.balance
                }
            }; // fake response so the other end is happy
        } else respondHttp(res, 503, `Cannot connect to database server (${err.code})`);
    });
};

/* verify card details */
const verifyCard = (local, remote) => {
    if (UPSTREAM_API !== null && !_upstreamOK.value) return true; // cannot check due to outage

    if (
        local.fareType != remote.fareType
        || local.balance != remote.balance
        || local.dailyExpenditure != remote.dailyExpenditure
        || local.touchedOn != remote.touchedOn
        || local.currentProduct != remote.currentProduct
        || local.prodValidated.slice(0, -5) != remote.prodValidated.slice(0, -5)
        || local.prodDuration != remote.prodDuration
    ) return false;

    /* check product bits */
    if (remote.prodBits[0] != 'AAAAAAAAAAAAAAAAAAAAAA==' || remote.prodBits[1] != 'AAAAAAAAAAAAAAAAAAAAAA==') {
        for (let i = 0; i < 2; i++)
            if (local.prodBits[i] != remote.prodBits[i]) return false;
    }

    /* check passes */
    let locPass = local.passes, remPass = remote.passes;
    if (locPass.length != remPass.length) return false;
    for (let l of locPass) {
        let found = false;
        for (let r of remPass) {
            if (r.transactionID != l.transactionID) continue;
            found = true;

            if (
                (r.activationDate !== null) != l.hasOwnProperty('expiryDate') /* unactivated pass: local gives duration instead of expiryDate, remote gives activationDate = null */
                || (r.activationDate === null) != l.hasOwnProperty('duration') /* activated pass: local gives expiryDate instead of duration, remote gives activationDate != null */
                || l.product != r.product
            ) return false;

            if (l.hasOwnProperty('duration')) {
                /* unactivated pass */
                if (l.duration != r.duration) return false;
            } else {
                /* activated pass - check expiry date */
                let lExpiry = new Date(l.expiryDate);
                let rExpiry = new Date(r.activationDate); rExpiry.setDate(rExpiry.getDate() + r.duration);
                if (lExpiry != rExpiry) return false;
            }

            break;
        }
        
        if (!found) return false; // unmatched pass
    }

    return true;
};

/* make transaction */
const makeTransaction = (type, location, details, setProduct) => {
    return {
        type: type,
        location: location,
        balance: details.balance,
        product: setProduct ? details.currentProduct : 0
    };
}

/* handler for missing touch on */
const missingTouchOn = (res, location, ticketID, details) => {
    let trans = makeTransaction(3, location.id, details, false);
    return writeTransaction(res, ticketID, trans)
        .then((resp) => {
            if (resp === undefined) return;
            respondValidate(res, 403, 'missingTouchOn', 'Missing touch on', trans, details);
        });
};

/* handler for touch on */
const touchOn = (res, location, ticketID, details, touchedOff) => {
    if (details.balance <= 0)
        return respondNegBalance(res, details);
    
    details.touchedOn = location.minProduct;
    
    if (details.prodDuration != 0) {
        /* check if expired */
        let prodExpiry = new Date(details.prodValidated);
        if (details.prodDuration < 0) {
            /* daily fare */
            if (prodExpiry.getHours() >= 3) prodExpiry.setDate(prodExpiry.getDate() + 1);
            prodExpiry.setHours(3, 0, 0, 0);
        } else prodExpiry.setMinutes(prodExpiry.getMinutes() + details.prodDuration);

        if (prodExpiry.getTime() < Date.now()) details.prodValidated = new Date().toISOString();
    } else details.prodValidated = new Date().toISOString();

    let trans = makeTransaction(touchedOff ? 2 : 0, location.id, details, false);
    return Promise.all([
        writeTransaction(res, ticketID, trans),
        writeTicketData(res, ticketID, details)
    ]).then((respArray) => {
        for (let resp of respArray)
            if (resp === undefined) return;
        respondValidate(res, 200, 'touchedOn', 'Touched on', trans, details);
    });
};

/* get PT date (i.e. new day starts at 3AM) */
const getPTDate = (date) => {
    let ret = new Date(date);
    if (ret.getHours() < 3) ret.setDate(ret.getDate() - 1);
    ret.setHours(3, 0, 0, 0);
    return ret;
};

/* stub method for touching off given the end product ID */
const touchOffProduct = (res, prodID, ticketID, fareType, details, currentProductExpired) => {
    let ticketValue = 0, farePending = 0;
    
    let touchedOnProdDetails = getProdDetails(details.touchedOn);
    if (touchedOnProdDetails == null) return respondHttp(res, 500, `Invalid product ID ${details.touchedOn}`);
    let onProduct = { id: details.touchedOn, ...touchedOnProdDetails };
    
    let prodIDDetails = getProdDetails(prodID);
    if (prodIDDetails == null) return respondHttp(res, 500, `Invalid product ID ${prodID}`);
    let offProduct = { id: prodID, ...prodIDDetails };
    
    let from = Math.min(onProduct.fromZone, offProduct.fromZone);
    let to = Math.min(onProduct.toZone, offProduct.toZone);
    
    if (!currentProductExpired && details.currentProduct != 0) {
        ticketValue = fareType.productFares[details.currentProduct];
        // let prodBits1 = Buffer.from(msg.details.prodBits[1], 'base64');
        // let byte = Math.floor(details.currentProduct / 8), bit = details.currentProduct % 8;
        if (b64Test(details.prodBits[1], details.currentProduct)) ticketValue *= 2;

        let currentProdDetails = getProdDetails(details.currentProduct);
        if (currentProdDetails == null) return respondHttp(res, 500, `Invalid product ID ${details.currentProduct}`);

        from = Math.min(from, currentProdDetails.fromZone);
        to = Math.max(to, currentProdDetails.toZone);
    }
    
    let minProduct = searchProduct(from, to); // replaces msg.minProd
    if (minProduct == null) return respondHttp(res, 500, `Cannot search for product spanning zones ${from}-${to}`);
        
    /* query for passes */
    let passes = []; // list of promises
    for (let pass of details.passes) {
        let passProduct = getProdDetails(pass.product);
        if (passProduct == null) return respondHttp(res, 500, `Invalid pass product ID ${pass.product}`);
        passes.push(passProduct);
    }

    /* find suitable pass */
    let passIdx = -1;
    for (let i = passes.length - 1; i >= 0; i--) {
        let prodDetails = passes[i];
        if (prodDetails.fromZone <= minProduct.fromZone && prodDetails.toZone >= minProduct.toZone) {
            passIdx = i;
            if (details.passes[i].activationDate !== null) break; // pre-activated pass
        }
    }

    if (passIdx >= 0) {
        /* pass found */
        ticketValue = 2 * fareType.productFares[details.passes[passIdx].product];
        details.currentProduct = details.passes[passIdx].id;
        details.prodDuration = -1; // daily fare
        // farePending = 0
        for (let pbits of details.prodBits)
            b64Set(pbits, details.currentProduct);
        if (details.passes[passIdx].activationDate === null) {
            /* activate pass */
            let activationDate = new Date();
            activationDate.setHours(0, 0, 0, 0);
            details.passes[passIdx].activationDate = activationDate.toISOString();

            return activatePass(ticketID, details.passes[passIdx].id, details.passes[passIdx].activationDate)
                .then((resp) => {
                    if (resp.status != 200) return respondHttp(res, resp.status, resp.data.message);
                    return {
                        farePending: farePending,
                        defaultTouchOff: false
                    };
                });
        }
        
        return {
            farePending: farePending,
            defaultTouchOff: false
        }; // pass already activated - do nothing
    }

    /* pass not found - check if product is actually expired */
    if (!currentProductExpired) {
        let prodExpiry = new Date(details.prodValidated);
        if (details.prodDuration < 0) {
            /* daily fare */
            if (prodExpiry.getHours() >= 3) prodExpiry.setDate(prodExpiry.getDate() + 1);
            prodExpiry.setHours(3, 0, 0, 0);
        } else {
            prodExpiry.setMinutes(prodExpiry.getMinutes() + minProduct.details.duration);
        }
        if (prodExpiry.getTime() < Date.now()) return {
            farePending: farePending, // probably 0
            defaultTouchOff: true
        }; // follow up with a default touch-off
    }
    
    details.prodDuration = minProduct.details.duration;
    if (details.currentProduct != minProduct.id) {
        let prodMarked = [];
        for (let pbits of details.prodBits)
            prodMarked.push(b64Test(pbits, minProduct.id));

        if (!prodMarked[0]) { // 2hr
            farePending = fareType.productFares[minProduct.id];
            b64Set(details.prodBits[0], minProduct.id);
        } else if (!prodMarked[1]) { // daily
            farePending = 2 * fareType.productFares[minProduct.id];
            b64Set(details.prodBits[1], minProduct.id);
        } // otherwise fare has already been paid for
    }
    details.currentProduct = minProduct.id;
    farePending -= ticketValue; if (farePending < 0) farePending = 0;
    if (details.dailyExpenditure + farePending > fareType.cap) farePending = fareType.cap - details.dailyExpenditure;
    return {
        farePending: farePending,
        defaultTouchOff: false
    };
};

/* handler for touch off */
const touchOff = (res, location, entryOnly, ticketID, details) => {
    let lastTransaction = null;
    // let touchedOn = null; // touched-on product details
    let fareType = null; // fare type information
    // let ticketValue = 0; // ticket value
    let prodExpiredPrev = false;
    let oldCurrentProduct = details.currentProduct;

    getLastTransaction(ticketID).then((resp) => {
        if (resp.status != 200) return respondHttp(res, resp.status, resp.data.message);

        if (resp.data.message.length == 0) return respondHttp(res, 500, 'Assertion failed: no last transaction');
        lastTransaction = resp.data.message[0];

        let locDetails = getLocDetails(lastTransaction.location); // get transaction location details
        if (locDetails == null) return respondHttp(res, 500, `Invalid location ID ${lastTransaction.location}`);
        lastTransaction.location = { id: lastTransaction.location, ...locDetails }; // replaces msg.lastLocDetails
        
        let ftDetails = getFareTypeDetails(details.fareType) // get fare type details
        if (ftDetails == null) return respondHttp(res, 500, `Invalid fare type ID ${details.fareType}`);
        // touchedOn = { id: details.touchedOn, ...respArray[1].data.message }; // replaces msg.onDetails
        fareType = { id: details.fareType, ...ftDetails };

        let validatedDay = getPTDate(details.prodValidated);
        let today = getPTDate(Date.now());
        prodExpiredPrev = validatedDay.getTime() != today.getTime();
        if (prodExpiredPrev) return new Promise((resolve, reject) => resolve({
            farePending: 0,
            defaultTouchOff: true
        })); // default touch off
        
        /* not rolling over to the next day yet - but we may still be expired */
        let offProduct = (location.minProduct == 3)
            ? ((details.touchedOn == 5 || details.touchedOn == 3) ? 5 : 1)
            : location.minProduct;
        let toffResp = touchOffProduct(res, offProduct, ticketID, fareType, details, false); // {farePending: number, defaultTouchOff: boolean} or undefined
        if (toffResp.defaultTouchOff)
            toffResp = touchOffProduct(res, lastTransaction.location.defaultProduct, ticketID, fareType, details, true);
        if (toffResp.defaultTouchOff)
            return respondHttp(res, 500, 'Assertion failed: defaultTouchOff still true after default touch-off');

        details.balance -= toffResp.farePending;
        details.dailyExpenditure += toffResp.farePending;
        details.touchedOn = 0;

        if (prodExpiredPrev) { // reset for new day
            details.prodBits = ["AAAAAAAAAAAAAAAAAAAAAA==","AAAAAAAAAAAAAAAAAAAAAA=="];
            details.currentProduct = 0;
        }

        if (prodExpiredPrev || entryOnly || (location.mode != lastTransaction.location.mode))
            return touchOn(res, location, ticketID, details, true); // touch on after touching off
        
        /* stop here */
        let trans = makeTransaction(1, location.id, details, details.currentProduct != oldCurrentProduct);
        return Promise.all([
            writeTransaction(res, ticketID, trans),
            writeTicketData(res, ticketID, details)
        ]).then((respArray) => {
            for (let resp of respArray)
                if (resp === undefined) return;
            respondValidate(res, 200, 'touchedOff', 'Touched off', trans, details);
        });
    });
};

/* main endpoint - ticket validation */
app.post('/api/validate', (req, res) => {
    if ((staticData === null) || (staticData.expiry < new Date()))
        return respondHttp(res, 503, 'Static database cache expired');

    new Promise((resolve, reject) => { // passthrough to central server
        if (UPSTREAM_API !== null && upstreamOK.value) {
            axios.post(`${UPSTREAM_API}/validate`, req.body).then((resp) => {
                respondHttp(res, resp.status, resp.data.message);
                resolve(true); // passed through successfully
            }).catch((err) => {
                upstreamOK.value = false;
                resolve(false);
            });
        } else resolve(false);
    }).then((passed) => {
        if (passed) return;

        // console.log(req.body);
        let validateReq = extractValidateRequest(req.body);
        if (validateReq === null) return respondHttp(res, 400, 'Invalid request body');

        /* get card/ticket details */
        let details = null;
        let oldCurrentProduct = null;
        let ticketID = ''; // ticket ID
        let pDetails = (upstreamOK.value)
            ? (
                validateReq.hasOwnProperty('card')
                ? getCardInfo(validateReq.card.type, validateReq.card.id)
                : getTicketInfo(validateReq.ticketID)
            ) : new Promise((resolve, reject) => resolve({
                status: 200,
                data: {
                    message: validateReq
                }
            }));
        pDetails.then((resp) => {
            if (resp.status != 200) return respondHttp(res, resp.status, resp.data.message); // pass error from upstream

            details = resp.data.message;
            if (details.disabled) return respondBlocked(res, details);

            if (validateReq.hasOwnProperty('card')) {
                ticketID = (upstreamOK.value) ? details.ticketID : `${validateReq.card.type}/${validateReq.card.id}`;
                if (details.expiryDate !== null && new Date(details.expiryDate) < new Date())
                    return respondExpired(res, details);
            } else ticketID = validateReq.ticketID;

            if (upstreamOK.value) {
                /* get product bits and passes */
                return Promise.all([
                    // getLastTransaction(ticketID),
                    getProdBits(ticketID),
                    getPasses(ticketID)
                ]);
            } else if (!validateReq.hasOwnProperty('cardVerify')) {
                /* can't handle */
                return respondHttp(res, 503, 'Lost connection to database server');
            } else {
                details = validateReq.cardVerify;
                return null; // nothing going on here
            }
        }).then((respArray) => {
            if (respArray === undefined) return; // premature exit

            if (respArray !== null) {
                /* check for failure */
                for (let resp of respArray) {
                    if (resp.status != 200) return respondHttp(res, resp.status, resp.data.message);
                }

                // details.lastTransaction = respArray[0].data.message;
                details.prodBits = respArray[0].data.message;
                details.passes = respArray[1].data.message;

                if (validateReq.hasOwnProperty('cardVerify')) {
                    /* verify card details */
                    if (!verifyCard(validateReq.cardVerify, details)) {
                        /* invalid card - block card now */
                        console.log(validateReq.card);
                        return blockCard(validateReq.card.type, validateReq.card.id).then((resp) => {
                            console.log(resp.data);
                            if (resp.status != 200) return respondHttp(res, resp.status, resp.data.message);
                            details.disabled = true;
                            respondBlocked(res, details);
                        });
                    }
                }
            }

            // oldCurrentProduct = details.currentProduct;
            let locDetails = getLocDetails(validateReq.location);
            if (locDetails == null) return respondHttp(res, 400, `Invalid location ID ${validateReq.location}`);
            validateReq.location = { id: validateReq.location, ...locDetails }; // replaces msg.locDetails

            if (details.touchedOn == 0) {
                /* touched off */
                if (validateReq.direction.exitOnly)
                    return missingTouchOn(res, validateReq.location, ticketID, details);
                return touchOn(res, validateReq.location, ticketID, details, false);
            } else {
                /* touched on - now touch off */
                return touchOff(res, validateReq.location, validateReq.direction.entryOnly, ticketID, details);
            }
        });
    });
});

const PORT = process.env.PORT || 3000; // whoopsie!
app.listen(PORT, () => {
    console.log(`App running on port ${PORT}`);
});
