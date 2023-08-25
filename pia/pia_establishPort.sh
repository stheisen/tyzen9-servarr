#!/bin/bash
# *****************************************************************************
# pia_establishPort.sh
#
# Author: Steve Theisen (Tyzen9)
# License: GNU GENERAL PUBLIC LICENSE
#
# Prerequisites: 
#    An openVPN connection should exist to a PIA server that supports PORT Forwarding
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

# First get the PIA credentials from the pia.config file
# $PIA_USERNAME
# $PIA_PASSWORD
source $CONFIG_FILE_PATH

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
echo Port: $PORT

exit 0

cat >./pia_registerPort.sh <<EOL
#!/bin/bash

curl -sGk --data-urlencode \
 "payload=${PAYLOAD}" \
 --data-urlencode \
 "signature=${SIGNATURE}" \
 https://${GATEWAY_IP}:19999/bindPort
EOL

chmod +x ./pia_registerPort.sh
