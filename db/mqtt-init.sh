#!/bin/sh

DEFAULT_MQTT_USERNAME=mqadmin
DEFAULT_MQTT_PASSWORD=mqadmin

MQTT_ADMIN_USERNAME=${MQTT_ADMIN_USERNAME:-$DEFAULT_MQTT_USERNAME}
MQTT_ADMIN_PASSWORD=${MQTT_ADMIN_PASSWORD:-$DEFAULT_MQTT_PASSWORD}

echo "Admin credentials: ${MQTT_ADMIN_USERNAME} ${MQTT_ADMIN_PASSWORD}"

mosquitto_ctrl dynsec init /mosquitto/config/dynamic-security.json ${MQTT_ADMIN_USERNAME} ${MQTT_ADMIN_PASSWORD}
