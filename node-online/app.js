const DBAPI_HOST = process.env.DBAPI_HOST || 'http://127.0.0.1:4000';
console.log(`Database API URL set to ${DBAPI_HOST}`);
process.env.TZ = 'Australia/Melbourne';

const express = require('express');
const axios = require('axios');
axios.default.respondValidate = (status) => true;

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
    respondHttp(res, 200, 'Database API is functional');
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
const getCardInfo = (type, id) => axios.get(`${DBAPI_HOST}/api/cards/${type}/${id}`);

/* request ticket information */
const getTicketInfo = (id) => axios.get(`${DBAPI_HOST}/api/tickets/${id}`);

/* request last transaction */
const getLastTransaction = (id) => axios.get(`${DBAPI_HOST}/api/tickets/${id}/transactions?validateOnly=true&limit=1`);

/* request pass information */
const getPasses = (id) => axios.get(`${DBAPI_HOST}/api/tickets/${id}/passes`);

/* activate pass */
const activatePass = (ticketID, passID, date) => axios.post(`${DBAPI_HOST}/api/tickets/${ticketID}/passes/${passID}`, { date: date });

/* request product bits */
const getProdBits = (id) => axios.get(`${DBAPI_HOST}/api/tickets/${id}/prodbits`);

/* disable card */
const blockCard = (type, id) => axios.delete(`${DBAPI_HOST}/api/cards/${type}/${id}`);

/* get location details */
const getLocDetails = (id) => axios.get(`${DBAPI_HOST}/api/locations/${id}`);

/* get product details */
const getProdDetails = (id) => axios.get(`${DBAPI_HOST}/api/products/${id}`);

/* get fare type details */
const getFareTypeDetails = (id) => axios.get(`${DBAPI_HOST}/api/fareTypes/${id}`);

/* search product covering zones */
const searchProduct = (from, to) => axios.get(`${DBAPI_HOST}/api/products/search/${from}/${to}`);

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
    return axios.patch(
        `${DBAPI_HOST}/api/tickets/${id}`,
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
        if (resp.status != 200) return respondHttp(res, resp.status, resp.data.message);
        return resp;
    });
};

/* write transaction */
const writeTransaction = (res, id, trans) => {
    return axios.post(
        `${DBAPI_HOST}/api/tickets/${id}/transactions`,
        trans
    ).then((resp) => {
        if (resp.status != 200) return respondHttp(res, resp.status, resp.data.message);
        return resp;
    });
};

/* verify card details */
const verifyCard = (local, remote) => {
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
    let onProduct = null, offProduct = null, minProduct = null;
    let ticketValue = 0, farePending = 0;
    return Promise.all([
        getProdDetails(details.touchedOn),
        getProdDetails(prodID)
    ]).then((respArray) => {
        for (let resp of respArray)
            if (resp.status != 200) return respondHttp(res, resp.status, resp.data.message);
        
        onProduct = {
            id: details.touchedOn,
            ...respArray[0].data.message
        };
        offProduct = {
            id: prodID,
            ...respArray[1].data.message
        };

        if (currentProductExpired || details.currentProduct == 0) return null;
        
        ticketValue = fareType.productFares[details.currentProduct];
        // let prodBits1 = Buffer.from(msg.details.prodBits[1], 'base64');
        // let byte = Math.floor(details.currentProduct / 8), bit = details.currentProduct % 8;
        if (b64Test(details.prodBits[1], details.currentProduct)) ticketValue *= 2;

        return getProdDetails(details.currentProduct);
    }).then((resp) => {
        if (resp === undefined) return;

        let from = Math.min(onProduct.fromZone, offProduct.fromZone);
        let to = Math.min(onProduct.toZone, offProduct.toZone);

        if (resp !== null) {
            if (resp.status != 200) return respondHttp(res, resp.status, resp.data.message);
            from = Math.min(from, resp.data.message.fromZone);
            to = Math.max(to, resp.data.message.toZone);
        }

        return searchProduct(from, to);
    }).then((resp) => {
        if (resp === undefined) return;
        if (resp.status != 200) return respondHttp(res, resp.status, resp.data.message);
        minProduct = resp.data.message; // replaces msg.minProd
        
        /* query for passes */
        let pPasses = []; // list of promises
        for (let pass of details.passes)
            pPasses.push(getProdDetails(pass.product));
        return Promise.all(pPasses);
    }).then((respArray) => {
        if (respArray === undefined) return;

        let passes = [];
        for (let resp of respArray) {
            if (resp.status != 200) return respondHttp(res, resp.status, resp.data.message);
            passes.push(resp.data.message);
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
    });
};

/* handler for touch off */
const touchOff = (res, location, entryOnly, ticketID, details) => {
    let lastTransaction = null;
    // let touchedOn = null; // touched-on product details
    let fareType = null; // fare type information
    // let ticketValue = 0; // ticket value
    let prodExpiredPrev = false;
    let oldCurrentProduct = details.currentProduct;

    return Promise.all([
        getLastTransaction(ticketID).then((resp) => {
            if (resp.status != 200) return respondHttp(res, resp.status, resp.data.message);
    
            if (resp.data.message.length == 0) return respondHttp(res, 500, 'Assertion failed: no last transaction');
            lastTransaction = resp.data.message[0];
    
            return getLocDetails(lastTransaction.location); // get transaction location details
        }).then((resp) => {
            if (resp === undefined) return;
            if (resp.status != 200) return respondHttp(res, resp.status, resp.data.message);
            lastTransaction.location = {
                id: lastTransaction.location,
                ...resp.data.message
            }; // replaces msg.lastLocDetails
        }), // get last transaction and its location details (undefined)
        // getProdDetails(details.touchedOn), // get touched on product details
        getFareTypeDetails(details.fareType) // get fare type details
    ]).then((respArray) => {
        if (respArray[1].status != 200)
            return respondHttp(res, respArray[1].status, respArray[1].data.message);

        // touchedOn = { id: details.touchedOn, ...respArray[1].data.message }; // replaces msg.onDetails
        fareType = { id: details.fareType, ...respArray[1].data.message };

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
        return touchOffProduct(res, offProduct, ticketID, fareType, details, false);
    }).then((resp) => { // {farePending: number, defaultTouchOff: boolean} or undefined
        if (resp === undefined) return;
        if (resp.defaultTouchOff)
            return touchOffProduct(res, lastTransaction.location.defaultProduct, ticketID, fareType, details, true);
        return resp; // pass on to next stage
    }).then((resp) => {
        if (resp === undefined) return;
        if (resp.defaultTouchOff) return respondHttp(res, 500, 'Assertion failed: defaultTouchOff still true after default touch-off');

        details.balance -= resp.farePending;
        details.dailyExpenditure += resp.farePending;
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
    let validateReq = extractValidateRequest(req.body);
    if (validateReq === null) return respondHttp(res, 400, 'Invalid request body');

    /* get card/ticket details */
    let details = null;
    let oldCurrentProduct = null;
    let ticketID = ''; // ticket ID
    let pDetails = validateReq.hasOwnProperty('card')
        ? getCardInfo(validateReq.card.type, validateReq.card.id)
        : getTicketInfo(validateReq.ticketID);
    pDetails.then((resp) => {
        if (resp.status != 200) return respondHttp(res, resp.status, resp.data.message); // pass error from upstream

        details = resp.data.message;
        if (details.disabled) return respondBlocked(res, details);

        if (validateReq.hasOwnProperty('card')) {
            ticketID = details.ticketID;
            if (details.expiryDate !== null && new Date(details.expiryDate) < new Date())
                return respondExpired(res, details);
        } else ticketID = validateReq.ticketID;

        /* get product bits and passes */
        return Promise.all([
            // getLastTransaction(ticketID),
            getProdBits(ticketID),
            getPasses(ticketID)
        ]);
    }).then((respArray) => {
        if (respArray === undefined) return; // premature exit

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

        // oldCurrentProduct = details.currentProduct;
        return getLocDetails(validateReq.location);
    }).then((resp) => {
        if (resp === undefined) return; // premature exit

        if (resp.status != 200) return respondHttp(res, resp.status, resp.data.message); // pass error from upstream
        validateReq.location = {
            id: validateReq.location,
            ...resp.data.message
        }; // replaces msg.locDetails

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

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`App running on port ${PORT}`);
});
