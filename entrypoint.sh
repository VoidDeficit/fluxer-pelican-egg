#!/bin/sh
cd /home/container || exit 1
mkdir -p /home/container/data
# Expand Pelican's {{VAR}} placeholders in the startup command and run it.
MODIFIED_STARTUP=$(echo "$STARTUP" | sed -e 's/{{/${/g' -e 's/}}/}/g')
echo ":/home/container$ ${MODIFIED_STARTUP}"
eval exec ${MODIFIED_STARTUP}
