# LocationServicesSpoofing

# Required Hardware
● RaspberryPI Model 3 <br />
● LimeSDR Mini <br />
● NodeMCU ESP8266 <br />

# 1	Installation
## 1.1	Setup for Raspberry Pi 3
Install newest packages in Rasbian OS:
> sudo apt-get update <br />
> sudo apt-get upgrade <br />

Install gcc and cmake to build and compile C code:
> sudo apt-get install software-properties-common <br />
> sudo apt-get install cmake <br />

## 1.2	Packages for GPS spoofing
### 1.2.1	LimeSuite library
Download ScratchRadio as the tool contains package  dependencies for SDR components (i.e. LimeSuite)
Installation commands:
> git clone https://github.com/myriadrf/ScratchRadio.git <br />
> sudo ./scripts/install_deps.sh <br />
> make LimeSuite <br />
> make clean <br />

### 1.2.2	gps-sdr-sim
gps-sdr-sim is a tool to generate GPS signal data streams used by software-defined radios (SDRs) to convert into radio frequency (RF).
Installation commands: 
> git clone https://github.com/osqzss/gps-sdr-sim.git <br />
> cd gps-sdr-sim <br />
> gcc gpssim.c -lm -O3 -o gps-sdr-sim -DUSER_MOTION_SIZE=4000 <br />
> cd player <br />
> make limeplayer <br />

## 1.3	Packages for Wi-Fi/BSSID spoofing
There are various hardware mediums used for Wi-Fi spoofing, such as Wi-Fi adaptors or access points. For our case, we will be using NodeMCU which runs on ESP8266 Wi-Fi chip. As such, we will need to install Arduino to compile and upload C code to the hardware.
### 1.3.1	Arduino
The simplest way to install Arduino is to run:
> sudo apt-get install arduino <br />

However, this is a bare bones installation without any add-on tools, including the ability to interact with Arduino command line interface (CLI). Alternatively, launch Chrome on Raspberry Pi, head to magpi.cc/2tPw8ht, and download Arduino using the Linux ARM link. Extract the file to /opt directory , then open a Terminal and run the install.sh script.
Installation commands:
> cd ~/Downloads <br />
> tar -xf arduino-1.8.3-linuxarm.tar.xz <br />
> sudo mv arduino-1.8.3 /opt <br />
> sudo /opt/arduino-1.8.3/install.sh <br />

Arduino by default does not include ESP8266 board. We can run the following commands to add ESP8266 board URL and install board packages:
> /opt/arduino-1.8.3/arduino --pref "boardsmanager.additional.urls=http://arduino.esp8266.com/stable/package_esp8266com_index.json" --save-prefs <br />
> /opt/arduino-1.8.3/arduino --install-boards esp8266:esp8266 --save-prefs <br />

# 2	GPS signals spoofing
Spoofing GPS signals is a simple task with the help of a SDR (i.e. LimeSDR mini). The idea here is to simulate a stream of GPS signal based on our specifications and playback using an SDR so that the signal can be received by GPS receivers nearby.
## 2.1	Obtain GPS Broadcast Ephemerides
GPS broadcast ephemerides (BRDC) are extrapolated satellite orbit data transmitted by satellites to receiver for navigation purposes. These data are archived daily and are available publicly through the NASA’s Crustal Dynamics Data Information System (CDDIS) website. The data is required for gps-sdr-sim tool to generate GPS data streams.
Installation command format:
> wget ftp://cddis.nasa.gov/gnss/data/daily/<4-digit year>/brdc/brdc<3-digit date>0.<2-digit year>n.Z <br />
> uncompress brdc<3-digit date>0.<2-digit year>n.Z <br />

Formatted example (year - 2019, date - 25 October):
> wget ftp://cddis.nasa.gov/gnss/data/daily/2019/brdc/brdc2980.19n.Z <br />
> uncompress brdc2980.19n.Z <br />

3-digit date refer to the number of days since the start of the year at 1st January, with values running from 1 to 365. The value can be obtained by running the command:
> date +%j <br />

## 2.2	Obtain GPS sample signal file
As explained under section 3.2.2, we can feed the downloaded ephemerides data through gps-sdr-sim to generate a binary file containing GPS signal.
Command format:
> gps-sdr-sim \ <br />
	-e <brdc file> \ # GPS ephemerides <br />
	-u <user motion> # NMEA GGA in csv <br />
	—l <lat,lon,alt> \ # static location <br />
	-s <sampling rate> \ # default 2.6MHz <br />
	-b <IQ bit> \ # 1 for limeplayer <br />
	-o <output> \ # default gpssim.bin <br />

For static GPS location, specify the ‘-l’ parameter instead of ‘-u’ parameter, while inserting latitude, longitude and altitude values of our intended spoofing location.
For dynamic GPS locations, specify the ‘-u’ parameter instead of ‘-l’. This parameter requires a National Marine Electronics Association (NMEA) Fix information (GGA) formatted CSV file. To generate the file, these steps are executed in-order:
Sketch a route using Google Earth
Export the route file in KML format.
Load the file into SatGen’s NMEA simulator to convert KML file to NMEA GGA text file. (Note: set output rate to 10Hz)
Convert NMEA GGA text file to user motion CSV file using the ‘nmea2um’ tool provided in gps-sdr-sim/satgen:
> ./nmea2um <nmea_gga> <user_motion> <br />

## 2.3	Playback GPS signals
Use the generated GPS signal file as an input for limeplayer to broadcast the signals to its surroundings.
Command format:
> limeplayer \ <br />
	-g 0.5 \ # RF gain [0.0 … 1.0] <br />
	-b 1 \ # IQ bit count <br />
	-s 2600000 \ # sampling rate <br />
	< gpssim.bin \ # GPS signal file  <br />

## 2.4	Pipelining the process
To make the tools work in conjunction to one another, our team have made an assembly line chaining the necessary tools with the help of a bash script. The pipeline starts from obtaining the latest (if not already downloaded) BRDC data from CDDIS FTP server. The user will then input a GPS signal file name to be generated. If the file name was previously created, the script will use the existing file and launch it on limeplayer. Else, the user will input the latitude and longitude data which will be used to generate the 400 seconds worth of GPS sample data. It when then proceed to be broadcasted by limeplayer using pre-defined parameters.

# 3	Wi-Fi signals spoofing
The Wi-Fi Positioning System (WPS) makes use of nearby Wi-Fi hotspots and other wireless access points (APs) to triangulate or “guess” the location of a device. This is especially useful indoors where GPS signals are limited. Thus, by fabricating APs from another location, the WPS on a smartphone can be fooled into thinking that the device is currently in that specified location.  As discussed in the earlier sections, we know that WPS infers the location based on BSSIDs or MAC addresses of nearby APs. In the following subsections, we explore the usage of some tools to crawl AP information and to broadcast beacons of spoofed BSSID information.
## 3.1	Obtain network information from WiGLE
WiGle.net is a consolidated central database containing wireless network information across the world. Queries can be fired from directly through their web interface or using their API.
For the purpose of being able to automate the crawling process, we used API tokens (allocated to account holders)  to query the web server by sending our crafted HTTP request detailing the specifications of our search criteria.
HTTP request format:
https://api.wigle.net/api/v2/network/search?onlymine=false&first=0&latrange1=<1>&latrange2=<2>&longrange1=<3>&longrange2=<4>&lastupdt=<5>&encryption=<6>&freenet=false&paynet=false&minQoS=<7>&resultsPerPage=<8>

Explanation of fields labelled <> <br />
<1> and <2>: Latitude lower and upper bounds <br />
<3> and <4>: Longitude lower and upper bounds <br />
<5>: Last update time - this is set to 3 months prior to current date as setting it too recent may result in zero search results. <br />
<6>: Encryption criteria is set to WPA2  <br />
<7>: Minimum quality of signal is set to 2 to exclude weak signals for better location accuracy. <br />
<8>: The maximum number of results returned by the query is set to 50. <br />
We wrote a python code read in user-specified latitude and longitude values and fire the crafted HTTP request to the web server using authentic API tokens. The results containing network information are stored in JSON format. By extracting the field ‘netid’, we can collate all the MAC addresses or BSSIDs of the wireless networks found in the area of interest and write them to a text file. <br />
These information are used to build C code which is then uploaded to NodeMCU. Since the code have to be compiled before uploading to NodeMCU, there is no simple way to construct a variable containing all the MAC addresses during run time. One method to overcome this is to establish communication between Raspberry Pi and NodeMCU so that Raspberry Pi will read the contents of the MAC addresses file and transmit the information to NodeMCU, which will receive and construct a variable to hold the values. We implemented a much simpler approach, which is to directly insert/replace into a pre-determined line of code in C program with the contents of the file specifying the variable that holds all the MAC addresses. In this way, the code will be already contain the variable before being compiled.

Next, a command line text stream editor called SED is used to insert/replace a line in the C code with our text. Specifically for our code, the global variable will sit at the 2nd line of code to avoid tempering with the main code beneath it. <br />
Commands used: <br />
> sed -i ‘2d’ macAddr.txt \ # Remove 2nd line <br />
> sed -i ‘2i\<text to insert>’ macAddr.txt \ # Insert text into 2nd line <br />

## 3.2	NodeMCU beacon spammer
A beacon spamming tool that works on the ESP8266 chip is used as a base template for our Wi-Fi spoofing purposes (https://github.com/spacehuhn/esp8266_beaconSpam). For the original code, random MAC addresses were used for each SSIDs. Beacon packets are crafted and repeatedly sent to 14 different Wi-Fi channels. <br />
By changing the bytes for the field ‘BSSID’, the beacon frame can be configured to carry our intended BSSID/MAC address. 
As explained in section 3.1, the constant variable containing all the MAC addresses will be inserted into this beacon spamming code. By editing the base code, these MAC addresses can be attached to dummy SSIDs and broadcasted its surroundings.

## 3.3	Pipelining the process
Similar to GPS spoofing, we pipeline the process by chaining all required tools through bash script. The user is expected to input a static location with latitude and longitude information. The surrounding networks from the location will be automatically crawled from wigle.net and BSSIDs are extracted from the JSON object while formatting the output. The output is then inserted directly into the Arduino code which is then verified and upload to NodeMCU using Arduino CLI. <br /> 
The command to verify and upload: <br />
> /opt/arduino-1.8.3/arduino -v verify —-board esp8266:esp8266:nodemcuv2 --port /dev/ttyUSB0 beaconSpam.ino <br />
> /opt/arduino-1.8.3/arduino -v upload —-board esp8266:esp8266:nodemcuv2 --port /dev/ttyUSB0 beaconSpam.ino <br />
