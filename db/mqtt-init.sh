#!/bin/sh

if [[ -n "$MQTT_CLEAN" ]]; then
    echo "Cleaning MQTT files..."
    rm -rf /mosquitto/*
fi
mkdir -p /mosquitto/data
mkdir -p /mosquitto/config
mkdir -p /mosquitto/log

DEFAULT_MQTT_USERNAME=mqadmin
DEFAULT_MQTT_PASSWORD=mqadmin

MQTT_ADMIN_USERNAME=${MQTT_ADMIN_USERNAME:-$DEFAULT_MQTT_USERNAME}
MQTT_ADMIN_PASSWORD=${MQTT_ADMIN_PASSWORD:-$DEFAULT_MQTT_PASSWORD}

echo "Admin credentials: ${MQTT_ADMIN_USERNAME} ${MQTT_ADMIN_PASSWORD}"

mosquitto_ctrl dynsec init /mosquitto/config/dynamic-security.json ${MQTT_ADMIN_USERNAME} ${MQTT_ADMIN_PASSWORD}
