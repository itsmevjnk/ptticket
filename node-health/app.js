const SERVICES = {
    dbapi: process.env.DBAPI_HOST || 'http://172.17.0.1:3101',
    online: process.env.ONLINE_HOST || 'http://172.17.0.1:3103',
    auth: process.env.AUTH_HOST || 'http://172.17.0.1:3121'
};
if (process.env.NO_VENDING === undefined || process.env.NO_VENDING != 1) SERVICES.vending = process.env.VENDING_HOST || 'http://172.17.0.1:3102';
console.log('Service(s) watched:', SERVICES);
const svcNames = Object.keys(SERVICES);

const express = require('express');
const app = express();
app.use(express.json());

const axios = require('axios');
axios.default.respondValidate = (status) => true;

const respondHttp = (res, status, payload) => {
    res.status(status).json({
        status: status,
        message: payload,
        time: Date.now()
    });
};

/* health check */
app.get('/api/healthcheck', (req, res) => {
    let promises = [];
    for (const [name, host] of Object.entries(SERVICES)) promises.push(axios.get(host + '/api/healthcheck'));
    Promise.all(promises).then((respArray) => {
        let payload = {};
        let status = 200;
        for (let i = 0; i < svcNames.length; i++) {
            let resp = respArray[i];
            if (resp.status != 200) status = 500;
            payload[svcNames[i]] = resp.data;
        }
        respondHttp(res, status, payload);
    });
});

const port = process.env.PORT || 3000;
app.listen(port, () => {
    console.log(`App running on port ${port}`);
});
