const DATABASE_API = process.env.DATABASE_API || 'http://127.0.0.1:3101/api';
const VENDING_API = process.env.VENDING_API || 'http://127.0.0.1:3102/api';
const VALIDATE_API = process.env.VALIDATE_API || 'http://127.0.0.1:3103/api';
const AUTH_TOKEN = process.env.AUTH_TOKEN || '';

const LOCATION = parseInt(process.env.LOCATION || 1);

const crypto = require('crypto');
const CARD_ID_HEX = (process.env.CARD_ID) ? Buffer.from(process.env.CARD_ID, 'hex') : crypto.randomBytes(4);
const CARD_ID = `${CARD_ID_HEX.toString('hex')}-0000-0000-0000-0123456789ab`; // expand 32-bit card ID (standard for Mifare cards) to 128-bit UUID
console.log(`Using card ID ${CARD_ID_HEX.toString('hex')} (${CARD_ID})`);

const express = require('express');

const app = express();
app.use(express.static(__dirname + '/static'));
app.use('/bs', express.static(__dirname + '/node_modules/bootstrap/dist')); // export Bootstrap for use
app.use('/jq', express.static(__dirname + '/node_modules/jquery/dist')); // export JQuery too

const cors = require('cors');
app.use(cors());

app.use(express.json()); // for parsing incoming POST requests

const axios = require('axios').create({
    headers: {
        'Authorization': 'Bearer ' + AUTH_TOKEN
    },
    validateStatus: () => true
});

const respondHttp = (res, status, payload) => {
    res.status(status).json({
        status: status,
        message: payload,
        time: Date.now()
    });
};

app.get('/fareTypes', (req, res) => {
    axios.get(DATABASE_API + '/fareTypes?hideFares=true&dict=true').then((resp) => {
        respondHttp(res, resp.status, resp.data.message);
    });
});

app.get('/products', (req, res) => {
    axios.get(DATABASE_API + '/products?hideZones=true&dict=true').then((resp) => {
        respondHttp(res, resp.status, resp.data.message);
    });
});

app.get('/card/id', (req, res) => {
    respondHttp(res, 200, CARD_ID);
});

let cardData = null;
app.get('/card/local', (req, res) => {
    if (req.query.beautify && req.query.beautify.toLowerCase() == 'true')
        respondHttp(res, 200, JSON.stringify(cardData, null, 4));
    else
        respondHttp(res, 200, cardData);
});

app.get('/card/remote', (req, res) => {
    if (cardData == null) return respondHttp(res, 409, 'Card has not been purchased yet');

    axios.get(DATABASE_API + `/cards/sc/${CARD_ID}`).then((resp) => {
        if (resp.status != 200) return respondHttp(res, resp.status, resp.data.message);
        let payload = {
            disabled: resp.data.message.disabled
        };
        if (!payload.disabled) {
            payload.balance = resp.data.message.balance / 100;
            payload.status = (resp.data.message.touchedOn != 0) ? 'Touched on' : 'Touched off';
            let prodExpiry = new Date(resp.data.message.prodValidated); prodExpiry.setMinutes(prodExpiry.getMinutes() + resp.data.message.prodDuration);
            payload.productExpiry = prodExpiry.toISOString();

            Promise.all([
                axios.get(DATABASE_API + `/tickets/${resp.data.message.ticketID}/passes`),
                axios.get(DATABASE_API + `/products/${resp.data.message.currentProduct}`),
                axios.get(DATABASE_API + `/fareTypes/${resp.data.message.fareType}?hideFares=true`)
            ]).then((respArray) => {
                /* product name */
                let resp = respArray[1];
                payload.product = (resp.status != 200) ? `Error querying product (${resp.status})` : resp.data.message.name;

                /* fare type name */
                resp = respArray[2];
                payload.fareType = (resp.status != 200) ? `Error querying fare type (${resp.status})` : resp.data.message;

                /* passes */
                resp = respArray[0];
                if (resp.status != 200) {
                    payload.passes = null;
                    respondHttp(res, 200, payload);
                }
                else {
                    payload.passes = [];
                    let promises = [];
                    for (let pass of resp.data.message) {
                        payload.passes.push({
                            // product: pass.product,
                            duration: pass.duration,
                            activeDate: pass.activationDate
                        });
                        promises.push(axios.get(DATABASE_API + `/products/${pass.product}`));
                    }
                    Promise.all(promises).then((respArray) => {
                        for (let i = 0; i < respArray.length; i++)
                            payload.passes[i].product = (respArray[i].status != 200) ? `Error querying product (${respArray[i].status})` : respArray[i].data.message.name;
                        respondHttp(res, 200, payload);
                    });
                }

            });
        } else return respondHttp(res, 200, payload);
    });
});

app.post('/balance', (req, res) => {
    if (cardData == null) return respondHttp(res, 409, 'Card has not been purchased yet');
    axios.post(VENDING_API + `/cards/sc/${CARD_ID}/balance`, {
        amount: req.body.amount * 100
    }).then((resp) => {
        respondHttp(res, resp.status, resp.data.message);

        if (resp.status == 200) cardData.balance = resp.data.message.balance;
    });
});

app.post('/pass', (req, res) => {
    if (cardData == null) return respondHttp(res, 409, 'Card has not been purchased yet');
    if (cardData.passes.length == 2) return respondHttp(res, 400, 'Card already has two passes - cannot buy more');

    const reqBody = {
        product: req.body.product,
        duration: req.body.duration
    };
    axios.post(VENDING_API + `/cards/sc/${CARD_ID}/pass`, reqBody).then((resp) => {
        respondHttp(res, resp.status, resp.data.message);

        if (resp.status == 200) cardData.passes.push({
            id: resp.data.message.id,
            product: reqBody.product,
            durationExpiry: reqBody.duration
        });
    });
});

app.post('/purchase', (req, res) => {
    if (cardData != null) return respondHttp(res, 409, 'Card has already been purchased');

    const reqBody = {
        cardType: 'sc',
        cardID: CARD_ID,
        fareType: req.body.fareType,
        balance: (req.body.topUp) ? (req.body.balance * 100) : undefined,
        pass: (req.body.pass) ? {
            product: req.body.passProduct,
            duration: req.body.passDuration
        } : undefined
    };
    axios.post(VENDING_API + '/tickets', reqBody).then((resp) => {
        if (resp.status != 200) return respondHttp(res, resp.status, 'Upstream request failed: ' + resp.data.message);

        cardData = {
            fareType: reqBody.fareType,
            balance: reqBody.balance || 0,
            dailyExpenditure: 0,
            currentProduct: 0,
            touchedOn: 0,
            prodValidated: 0,
            prodDuration: 0,
            prodBits: ["AAAAAAAAAAAAAAAAAAAAAA==", "AAAAAAAAAAAAAAAAAAAAAA=="],
            passes: [],

            transactions: []
        };

        if (resp.data.message.balance != null) cardData.transactions.unshift(resp.data.message.balance);
        if (resp.data.message.pass != null) {
            cardData.passes.push({
                id: resp.data.message.pass.id,
                product: reqBody.pass.product,
                durationExpiry: reqBody.pass.duration
            });
            cardData.transactions.unshift(resp.data.message.pass);
        }

        respondHttp(res, 200, resp.data.message);
    });
});

app.post('/validate', (req, res) => {
    if (cardData == null) return respondHttp(res, 409, 'Card has not been purchased yet');

    const reqCard = {
        type: 'sc',
        id: CARD_ID,

        fareType: cardData.fareType,
        balance: cardData.balance,
        dailyExpenditure: cardData.dailyExpenditure,
        currentProduct: cardData.currentProduct,
        touchedOn: cardData.touchedOn,
        prodValidated: new Date(cardData.prodValidated).toISOString(),
        prodDuration: cardData.prodDuration,
        passes: [],
        prodBits: cardData.prodBits
    };
    for (const pass of cardData.passes) {
        reqCard.passes.push({
            id: pass.id, product: pass.product,
            duration: (pass.durationExpiry <= 365) ? pass.durationExpiry : undefined,
            expiryDate: (pass.durationExpiry > 365) ? new Date(pass.durationExpiry).toISOString() : undefined
        });
    }

    axios.post(VALIDATE_API + '/validate', {
        card: reqCard,
        location: LOCATION
    }).then((resp) => {
        if (resp.status != 200 && typeof resp.data.message != 'object') return respondHttp(res, resp.status, 'Upstream request failed: ' + resp.data.message);
        
        respondHttp(res, resp.status, resp.data.message);
        if (typeof resp.data.message == 'object') {
            /* log transaction and new details */
            if (resp.data.message.transaction != null) cardData.transactions.unshift(resp.data.message.transaction);

            let newDetails = resp.data.message.details;
            // console.log(newDetails);
            cardData.balance = newDetails.balance;
            cardData.dailyExpenditure = newDetails.dailyExpenditure;
            cardData.currentProduct = newDetails.currentProduct;
            cardData.touchedOn = newDetails.touchedOn;
            cardData.prodValidated = new Date(newDetails.prodValidated).getTime();
            cardData.prodDuration = newDetails.prodDuration;
            cardData.prodBits = newDetails.prodBits;
        }
    }).catch((err) => {
        respondHttp(res, 503, 'Upstream request failed: ' + err.code);
    });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log('Serving app on port', PORT);
});
