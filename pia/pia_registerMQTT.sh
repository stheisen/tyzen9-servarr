#!/bin/bash
# *****************************************************************************
# pia_registerMQTT.sh
#
#
# Author: Steve Theisen (Tyzen9)
# License: GNU GENERAL PUBLIC LICENSE
#
# Prerequisites: 
#    mosquitto-clients - this is installed with `sudo apt-get install mosquitto-clients`
#
# Reference: https://github.com/pia-foss/manual-connections
#
# *****************************************************************************

# Set the path to the required configuration file
CONFIG_FILE_PATH="./pia.config"

# Make sure that the required configuration file exists
if [ ! -f "$CONFIG_FILE_PATH" ]; then
  echo "The required configuration file \"$CONFIG_FILE_PATH\" does not exist"
  exit 1
fi

# First get the MQTT credentials and settings from the pia.config file
source $CONFIG_FILE_PATH

$(mosquitto_pub -r -h $MQTT_BROKER -u $MQTT_USERNAME -P $MQTT_PASSWORD -t "homeassistant/sensor/blackpearl-pia-port/config" -m \
'{
	"name" : "PIA Forwarding Port",
	"state_topic": "homeassistant/sensor/blackpearl-pia-port/state", 
    "unique_id": "piaport01",
	"device": {
		"identifiers": ["blackpearl01pi"], 
		"name": "Black Pearl", 
		"manufacturer": "Raspberry PI", 
		"model": "Model B 8GB"
	}
}')
