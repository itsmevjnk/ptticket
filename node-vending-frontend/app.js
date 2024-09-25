const VENDING_API = process.env.VENDING_API || 'http://127.0.0.1:3102/api';
const DB_API = process.env.DB_API || 'http://127.0.0.1:3101/api';

const API_KEY = process.env.API_KEY || '';
const options = {
    headers: {
        'Authorization': 'Bearer ' + API_KEY
    }
};

const express = require('express');

const app = express();
app.use(express.static(__dirname + '/static'));
app.use('/bs', express.static(__dirname + '/node_modules/bootstrap/dist')); // export Bootstrap for use
app.use('/jq', express.static(__dirname + '/node_modules/jquery/dist')); // export JQuery too
app.use('/qr', express.static(__dirname + '/node_modules/html5-qrcode')); // QR code reader

const cors = require('cors');
app.use(cors());

app.use(express.json()); // for parsing incoming POST requests

const axios = require('axios');
axios.default.respondValidate = (status) => true; // disable error throwing on error response

const respondHttp = (res, status, payload) => {
    res.status(status).json({
        status: status,
        message: payload,
        time: Date.now()
    });
};

app.get('/fareTypes', (req, res) => {
    axios.get(DB_API + '/fareTypes?hideFares=true&dict=true', options).then((resp) => {
        respondHttp(res, resp.status, resp.data.message);
    });
});

app.get('/products', (req, res) => {
    axios.get(DB_API + '/products?hideZones=true&dict=true', options).then((resp) => {
        respondHttp(res, resp.status, resp.data.message);
    });
});

app.get('/card/:id', (req, res) => {
    axios.get(DB_API + `/cards/qr/${req.params.id}`, options).then((resp) => {
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
                axios.get(DB_API + `/tickets/${resp.data.message.ticketID}/passes`, options),
                axios.get(DB_API + `/products/${resp.data.message.currentProduct}`, options),
                axios.get(DB_API + `/fareTypes/${resp.data.message.fareType}?hideFares=true`, options)
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
                        promises.push(axios.get(DB_API + `/products/${pass.product}`, options));
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

const qrcode = require('qrcode');

app.post('/purchase', (req, res) => {
    axios.post(VENDING_API + '/tickets', {
        cardType: 'qr',
        fareType: req.body.fareType,
        balance: (req.body.topUp) ? (req.body.balance * 100) : undefined,
        pass: (req.body.pass) ? {
            product: req.body.passProduct,
            duration: req.body.passDuration
        } : undefined
    }, options).then((resp) => {
        if (resp.status != 200) return respondHttp(res, resp.status, 'Upstream request failed: ' + resp.data.message);
        qrcode.toString(resp.data.message.create.cardID, {
            errorCorrectionLevel: 'H',
            type: 'svg'
        }, (err, data) => {
            if (err) return respondHttp(res, 500, 'Failed to create QR code: ' + err);
            respondHttp(res, 200, {
                cardID: resp.data.message.create.cardID,
                qr: data
            });
        });
    });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log('Serving QR ticket vending frontend on port', PORT);
});