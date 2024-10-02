const mqtt = require('mqtt');

const mqttOptions = {};
if (process.env.MQTT_ADMIN_USERNAME && process.env.MQTT_ADMIN_USERNAME.length > 0) {
    mqttOptions.username = process.env.MQTT_ADMIN_USERNAME;
    mqttOptions.password = process.env.MQTT_ADMIN_PASSWORD || '';
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
const DYNSEC_TOPIC = process.env.MQTT_DYNSEC_TOPIC || '$CONTROL/dynamic-security/v1'; // Mosquitto Dynamic Security Plugin topic

mqttClient.publish(DYNSEC_TOPIC, JSON.stringify({
    commands: [
        {
            command: 'createRole',
            rolename: 'listen',
            acls: [{
                acltype: 'subscribePattern',
                topic: 'static',
                priority: -1,
                allow: true
            }]
        },
        {
            command: 'createRole',
            rolename: 'broadcast',
            acls: [{
                acltype: 'publishClientSend',
                topic: 'static',
                priority: -1,
                allow: true
            }]
        },
        {
            command: 'addClientRole',
            username: mqttOptions.username,
            rolename: 'broadcast'
        }
    ]
}), (err) => {
    if (err) console.warn('Cannot execute role creation command:', err);
    // else console.log('Created role for ordinary listeners');
});

const createSubscriber = require('pg-listen');

const dbConfig = {
    user: process.env.DB_USER || 'auth',
    password: process.env.DB_PASS || 'ptticket_auth',
    host: process.env.DB_HOST || '127.0.0.1',
    port: process.env.DB_PORT || 5432,
    database: process.env.DB_NAME || 'ptticket'
};
const ADD_CHANNEL = process.env.DB_ADD_CHANNEL || 'auth_add';
const DEL_CHANNEL = process.env.DB_DEL_CHANNEL || 'auth_del';

const subscriber = createSubscriber({
    connectionString: `postgres://${dbConfig.user}:${dbConfig.password}@${dbConfig.host}:${dbConfig.port}/${dbConfig.database}`
});

subscriber.notifications.on(ADD_CHANNEL, (payload) => {
    let id = payload.id;
    console.log('API token added:', id);

    mqttClient.publish(DYNSEC_TOPIC, JSON.stringify({
        commands: [{
            command: 'createClient',
            username: id,
            password: id,
            roles: [{ rolename: 'listen', priority: -1 }]
        }]
    }), (err) => {
        if (err) console.error(`Cannot authorise client ${id}:`, err);
        // else console.log(`Authorised client ${id}`);
    });
});

subscriber.notifications.on(DEL_CHANNEL, (payload) => {
    let id = payload.id;
    console.log('API token deleted:', id);

    mqttClient.publish(DYNSEC_TOPIC, JSON.stringify({
        commands: [{
            command: 'deleteClient',
            username: id
        }]
    }), (err) => {
        if (err) console.error(`Cannot deauthorise client ${id}:`, err);
        // else console.log(`Deauthorised client ${id}`);
    });
});

subscriber.notifications.on('error', (error) => {
    console.error('Fatal database connection error:', error);
    process.exit(1);
});

process.on('exit', () => {
    subscriber.close();
});

subscriber.connect().then(() => {
    console.log('Connected to database');
    subscriber.listenTo(ADD_CHANNEL).then(() => console.log('Connected to token addition notification channel', ADD_CHANNEL));
    subscriber.listenTo(DEL_CHANNEL).then(() => console.log('Connected to token deletion notification channel', DEL_CHANNEL));
});
