#!/bin/bash

PIA_USERNAME=p3931578
PIA_PASSWORD=4fmZ7KN8rA

# Obtaint the gateway IP  from tun0
GATEWAY_IP=$(ip route | grep 0.0.0.0/1 | grep tun0 | awk '{print $3}')
echo Gateway IP: $GATEWAY_IP

TOKEN=$(curl -s --location --request POST \
  'https://www.privateinternetaccess.com/api/client/v2/token' \
  --form "username=$PIA_USERNAME" \
  --form "password=$PIA_PASSWORD" | jq -r '.token')
echo Token: $TOKEN

SIGNATURE_OBJ=$(curl -s -k "https://$GATEWAY_IP:19999/getSignature?token=$TOKEN")
#echo Signature: $SIGNATURE_OBJ
#echo  ---

echo

STATUS=$(echo $SIGNATURE_OBJ | jq -r '.status')
echo Status: $STATUS

PAYLOAD=$(echo $SIGNATURE_OBJ | jq -r '.payload')
echo Payload: $PAYLOAD

SIGNATURE=$(echo $SIGNATURE_OBJ | jq -r '.signature')
echo Signature: $SIGNATURE

PAYLOAD_OBJ=$(echo $PAYLOAD | base64 -d | jq)
echo Payload Object: $PAYLOAD_OBJ

PORT=$(echo $PAYLOAD_OBJ | jq -r '.port')
echo Port: $PORT

cat >./pia_registerPort.sh <<EOL
#!/bin/bash

curl -sGk --data-urlencode \
 "payload=${PAYLOAD}" \
 --data-urlencode \
 "signature=${SIGNATURE}" \
 https://${GATEWAY_IP}:19999/bindPort
EOL

chmod +x ./pia_registerPort.sh
