#!/bin/bash
# *****************************************************************************
# pia_establishPort.sh
#   This script will make an MQTT to send the new Port Forward number to Home Assistant
#   This script also reads the configured OPENVPN_CONFIG_PATH to gain the IP Address of the VPN Tunnel
#   It also uses UFW commands to remove old rules and add a new rule for the new port-forwrad number
#
# OUTPUT: pia_registerPort.sh
#   The script (pia_registerPort.sh) will be created/overriten and executed each time this script is run
#
#   ** NOTE: A Cron Jobs need setup to:
#             1. run pia_establishPort.sh every the first day of every month
#             2. run pia_establishPort.sh every reboot
#             3. run pia_registerPort.sh every 15 minutes
#
# Author: Steve Theisen (Tyzen9)
# License: GNU GENERAL PUBLIC LICENSE
#
# Prerequisites: 
#    An openVPN connection should exist to a PIA server that supports PORT Forwarding
#    /etc/sodoers is configured so the user the script runs as does not need to enter a password for sudo commands
#
# Reference: https://github.com/pia-foss/manual-connections
#
# *****************************************************************************

# Set the path to the required configuration file
CONFIG_FILE_PATH="./pia.config"
PORT_HISTORY_PATH="./pia.port_history" 
OPENVPN_CONFIG_PATH="/etc/openvpn/pia_ca-toronto.conf";

# Make sure that the required configuration file exists
if [ ! -f "$CONFIG_FILE_PATH" ]; then
  echo "The required configuration file \"$CONFIG_FILE_PATH\" does not exist"
  exit 1
fi

# First get the PIA credentials from the pia.config file
source $CONFIG_FILE_PATH

# Make sure a PIA username and password was pulled from the config file
if [ ${#PIA_USERNAME} -eq 0 ] || [ ${#PIA_PASSWORD} -eq 0 ]; then
  echo "A PIA Username and Password is needed in the configuration file \"$CONFIG_FILE_PATH\""
  exit 1
fi

# Get the previous PORT number from the portforward log
if [ -f "./_forwardPort.log" ]; then
  read -r CURRENT_PORT < "./_forwardPort.log"
fi

# get the VPN ip address from the OpenVPN config file
VPN_IP=$(cat ${OPENVPN_CONFIG_PATH} | grep -m 1 remote | awk '{print $2}')
echo VPN IP: $VPN_IP

# This function allows you to check if the required tools have been installed.
check_tool() {
  cmd=$1
  if ! command -v "$cmd" >/dev/null; then
    echo "$cmd could not be found"
    echo "Please install $cmd"
    exit 1
  fi
}

# Now we call the function to make sure we can use curl and jq.
check_tool curl
check_tool jq

# Obtain the gateway IP from tun0
GATEWAY_IP=$(ip route | grep 0.0.0.0/1 | grep tun0 | awk '{print $3}')
# echo Gateway IP: $GATEWAY_IP

# Maka a call to PIA to obtain a validated access token
TOKEN=$(curl -s --location --request POST \
  'https://www.privateinternetaccess.com/api/client/v2/token' \
  --form "username=$PIA_USERNAME" \
  --form "password=$PIA_PASSWORD" | jq -r '.token')
#echo Token: $TOKEN

# Now that we have the VPN Gateway IP Address, and a valid Token ans Signature object
SIGNATURE_OBJ=$(curl -s -k "https://$GATEWAY_IP:19999/getSignature?token=$TOKEN")
#echo Signature: $SIGNATURE_OBJ

# The SIGNATURE_OBJ is a JSON object containing the Status, Payload, and Signature
STATUS=$(echo $SIGNATURE_OBJ | jq -r '.status')
PAYLOAD=$(echo $SIGNATURE_OBJ | jq -r '.payload')
SIGNATURE=$(echo $SIGNATURE_OBJ | jq -r '.signature')
#echo Status: $STATUS
#echo Payload: $PAYLOAD
#echo Signature: $SIGNATURE

# The Payload is base64 encrypted JSON object that contains the PORT.  Simply extract the port
# number using jq
PAYLOAD_OBJ=$(echo $PAYLOAD | base64 -d | jq)
PORT=$(echo $PAYLOAD_OBJ | jq -r '.port')
#echo Payload Object: $PAYLOAD_OBJ
#echo Port: $PORT

# Write the port number to a local file for traceability 
cat > ./_forwardPort.log <<EOL
$PORT
EOL

# remove previous UFW rule, if we have a previous port number
if [[ -n "$CURRENT_PORT" ]]; then
  sudo ufw delete allow out to ${VPN_IP} port ${CURRENT_PORT} proto tcp
fi

# Add new UFW rule for new port_forward IP
sudo ufw allow out to ${VPN_IP} port ${PORT} proto tcp

# Publish the new port number to MQTT
# - Configuration is done in pia.config
# - Simply comment out the following line if you are not using MQTT
$(mosquitto_pub -r -h $MQTT_BROKER -u $MQTT_USERNAME -P $MQTT_PASSWORD -t "$MQTT_TOPIC" -m "$PORT")

# Using the data we have gathered thus far, we need to register this port number via PIA so 
# that is can be "registered".  This will be run immediatly after creation
#
# NOTE: This registration needs to be done every 15 minutes by a cron job after the initial run.
cat >./pia_registerPort.sh <<EOL
#!/bin/bash

# Make a call to bind this port number every 15 mins
curl -sGk --data-urlencode \
 "payload=${PAYLOAD}" \
 --data-urlencode \
 "signature=${SIGNATURE}" \
 https://${GATEWAY_IP}:19999/bindPort

# Write the time this was last done to a file
date > _lastBindRequest.log

EOL

# Make the dynamic file executable
chmod 755 ./pia_registerPort.sh

# Execute the newly created script
# REMEMBER to setup a cron job that will run this script every 15 minutes to keep the port alive.
./pia_registerPort.sh

exit 0
