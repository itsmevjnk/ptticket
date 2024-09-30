const VENDING_API = process.env.VENDING_API || 'http://127.0.0.1:3102/api';
const AUTH_TOKEN = process.env.AUTH_TOKEN || '';

const express = require('express');

const app = express();
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

app.get('/api/healthcheck', (req, res) => {
    axios.get(`${VENDING_API}/healthcheck`).then((resp) => {
        if (resp.status != 200) {
            respondHttp(res, (AUTH_TOKEN) ? 299 : 500, `Upstream vending API health check failed (status code ${resp.status})`); // NOTE: 299 is our custom status code to indicate that we can't process anything other than smart cards
            // upstreamOK.value = false;
        } else {
            respondHttp(res, 200, 'Smart card vending API is functional');
            // upstreamOK.value = true;
        }
    }).catch((err) => {
        respondHttp(res, (AUTH_TOKEN) ? 299 : 500, `Upstream vending API health check failed (status code ${err.code})`); // NOTE: 299 is our custom status code to indicate that we can't process anything other than smart cards
        // upstreamOK = false;
    })
});

app.post('/api/balance/:id', (req, res) => {
    axios.post(VENDING_API + `/cards/sc/${req.params.id}/balance`, {
        amount: req.body.amount
    }, req.axOptions).then((resp) => {
        if (resp.status == 200) resp.data.message.timestamp = Math.floor(new Date(resp.data.message.timestamp).getTime() / 1000); // convert to integer
        respondHttp(res, resp.status, resp.data.message);
    });
});

app.post('/api/pass/:id', (req, res) => {
    axios.post(VENDING_API + `/cards/sc/${req.params.id}/pass`, {
        product: req.body.product,
        duration: req.body.duration
    }, req.axOptions).then((resp) => {
        respondHttp(res, resp.status, resp.data.message);
    });
});

const crypto = require('crypto');
app.post('/api/purchase/:id', (req, res) => {
    // return respondHttp(res, 200, [
    //     {
    //         id: crypto.randomUUID(),
    //         type: 4,
    //         timestamp: Math.floor(Date.now() / 1000),
    //         balance: 10000
    //     },
    //     {
    //         id: crypto.randomUUID(),
    //         type: 5,
    //         timestamp: Math.floor(Date.now() / 1000),
    //         balance: 10000
    //     }
    // ]);

    axios.post(VENDING_API + '/tickets', {
        cardType: 'sc',
        cardID: req.params.id,
        fareType: req.body.fareType,
        balance: (req.body.topUp && req.body.balance > 0) ? req.body.balance : undefined,
        pass: (req.body.pass) ? {
            product: req.body.passProduct,
            duration: req.body.passDuration
        } : undefined
    }, req.axOptions).then((resp) => {
        if (resp.status != 200) return respondHttp(res, resp.status, resp.data.message);

        let transactions = []; // list of transactions to be added
        if (resp.data.message.balance !== null) transactions.push({
            id: resp.data.message.balance.id,
            type: resp.data.message.balance.type,
            timestamp: Math.floor(new Date(resp.data.message.balance.timestamp).getTime() / 1000),
            balance: resp.data.message.balance.balance
        });
        if (resp.data.message.pass !== null) transactions.push({
            id: resp.data.message.pass.id,
            type: resp.data.message.pass.type,
            timestamp: Math.floor(new Date(resp.data.message.pass.timestamp).getTime() / 1000),
            balance: resp.data.message.pass.balance
        });

        respondHttp(res, 200, transactions); // the rest of the card's information can be filled out by the vending device
    });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log('Serving smart card ticket vending frontend on port', PORT);
});