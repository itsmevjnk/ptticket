const VENDING_API = process.env.VENDING_API || 'http://127.0.0.1:3102/api';
const API_KEY = 'Bearer ' + (process.env.API_KEY || '');

const express = require('express');

const app = express();
app.use(express.static(__dirname + '/static'));
app.use('/bs', express.static(__dirname + '/node_modules/bootstrap/dist')); // export Bootstrap for use
app.use('/jq', express.static(__dirname + '/node_modules/jquery/dist')); // export JQuery too

const cors = require('cors');
app.use(cors());

app.use(express.urlencoded({
    extended: true
})); // for parsing incoming POST requests

const axios = require('axios');
axios.default.respondValidate = (status) => true; // disable error throwing on error response

const respondHttp = (res, status, payload) => {
    res.status(status).json({
        status: status,
        message: payload,
        time: Date.now()
    });
};

const qrcode = require('qrcode');

app.post('/purchase', (req, res) => {
    axios.post(VENDING_API + '/tickets', {
        cardType: 'qr',
        balance: req.body.balance,
        fareType: req.body.fareType,
        pass: (req.body.passProduct) ? {
            product: req.body.passProduct,
            duration: req.body.passDuration
        } : undefined
    }, {
        headers: {
            'Authorization': API_KEY
        }
    }).then((resp) => {
        if (resp.status != 200) return respondHttp(res, resp.status, 'Upstream request failed: ' + resp.data.message);
        qrcode.toString(res.create.cardID, {
            errorCorrectionLevel: 'H',
            type: 'svg'
        }, (err, data) => {
            if (err) return respondHttp(res, 500, 'Failed to create QR code: ' + err);
            respondHttp(res, 200, {
                cardID: resp.data.message.cardID,
                qr: data
            });
        });
    });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log('Serving QR ticket vending frontend on port', PORT);
});