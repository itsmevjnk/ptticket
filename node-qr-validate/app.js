const ONLINE_API = process.env.ONLINE_API || 'http://127.0.0.1:3103/api';
const AUTH_API = process.env.AUTH_API || 'http://127.0.0.1:3121/api';

const AUTH_TOKEN = process.env.AUTH_TOKEN || '';
const LOCATION = parseInt(process.env.LOCATION || '');
if (isNaN(LOCATION) || LOCATION == 0) {
    console.error('Invalid location or location not given');
    process.exit(1);
}

const express = require('express');

const app = express();
app.use(express.static(__dirname + '/static'));
app.use('/bs', express.static(__dirname + '/node_modules/bootstrap/dist')); // export Bootstrap for use
app.use('/jq', express.static(__dirname + '/node_modules/jquery/dist')); // export JQuery too
app.use('/qr', express.static(__dirname + '/node_modules/html5-qrcode')); // QR code reader

const cors = require('cors');
app.use(cors());

app.use(express.json()); // for parsing incoming POST requests

const cookieParser = require('cookie-parser');
app.use(cookieParser());

const axios = require('axios').create({
    headers: {
        'Authorization': 'Bearer ' + AUTH_TOKEN
    },
    validateStatus: () => true
});

axios.get(AUTH_API + '/auth').then((resp) => {
    if (resp.status != 200) {
        console.error(`Authentication check failed with status code ${resp.status}:`);
        console.error(resp.data);
        process.exit(1);
    }
});

const respondHttp = (res, status, payload) => {
    res.status(status).json({
        status: status,
        message: payload,
        time: Date.now()
    });
};

app.all('*', (req, res, next) => {
    // if (!/^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/.test(req.cookies.auth))
    //     return respondHttp(res, 401, 'Missing or invalid token');
    // req.locID = parseInt(req.cookies.loc);
    // if (isNaN(req.locID) || req.locID == 0)
    //     return respondHttp(res, 400, 'Missing or invalid location ID');
    req.locDirection = {
        entry: parseInt(req.cookies.entry),
        exit: parseInt(req.cookies.exit)
    };
    if (isNaN(req.locDirection.entry) || isNaN(req.locDirection.exit))
        return respondHttp(res, 400, 'Missing or invalid direction data');
    req.locDirection.entry = req.locDirection.entry != 0;
    req.locDirection.exit = req.locDirection.exit != 0;
    // req.axOptions = {
    //     headers: {
    //         'Authorization': 'Bearer ' + req.cookies.auth
    //     }
    // };
    next();
});

app.post('/validate/:id', (req, res) => {
    axios.post(ONLINE_API + '/validate', {
        card: {
            type: 'qr',
            id: req.params.id,
            skipValidation: true
        },
        location: LOCATION,
        direction: req.locDirection
    }).then((resp) => {
        respondHttp(res, resp.status, (resp.status !== 200) ? resp.data.message : {
            text: resp.data.message.text,
            balance: resp.data.message.details.balance / 100
        });
    });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log('Serving QR ticket validation frontend on port', PORT);
});