#!/bin/bash

echo "Note: Make sure ESP8266 NodeMCU is plugged into the system before procedding."

read -p "Enter latitude value: " lat
read -p "Enter longitude value: " lon
echo "Crawling BSSIDs from Wigle.net based on the input latitude and lonitude values..."
crawl_command="python3 /home/pi/Desktop/Project/beacon-spammer/generate-bssid.py "$lat" "$lon
echo "Running command: $crawl_command"
eval $crawl_command

macAddr_path="/home/pi/Desktop/Project/beacon-spammer/macAddr.txt"
beaconSpam_path="/home/pi/Desktop/Project/beacon-spammer/esp8266_beaconSpam/esp8266_beaconSpam.ino"
line_to_insert=$(cat $macAddr_path)

echo "Replacing the mac array directly in the arduino file..."
# Remove 2nd line
removeline_command="sed -i '2d' "$beaconSpam_path
eval $removeline_command
# Add to 2nd line
insertline_command="sed -i '2i\\"$line_to_insert"' "$beaconSpam_path
eval $insertline_command

echo "Verifying build for esp8266_beaconSpam.ino..."
verify_command="/opt/arduino-1.8.10/arduino -v --verify --board esp8266:esp8266:nodemcuv2 --port /dev/ttyUSB0 "$beaconSpam_path
eval $verify_command

echo "Uploading build onto nodemcuv2..."
upload_command="/opt/arduino-1.8.10/arduino -v --upload --board esp8266:esp8266:nodemcuv2 --port /dev/ttyUSB0 "$beaconSpam_path
eval $upload_command

echo "Wifi beacon spamming program is uploaded onto nodemcuv2"
