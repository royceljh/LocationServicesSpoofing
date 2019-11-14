#!/usr/bin/env python3

# Wigle API. Populate wigle.conf with your API keys / email.
# See https://api.wigle.net/

import requests
import logging
import json
import configparser 
from requests.auth import HTTPBasicAuth

requests_log = logging.getLogger("requests")
requests_log.setLevel(logging.ERROR)

class Wigle(object):

    def __init__(self,confFile='wigle.conf'):
        Config = configparser.ConfigParser()
        Config.read(confFile)
        try:
            user = Config.get('wigle','user')
            key = Config.get('wigle','key')
        except:
            raise ValueError('Please enter your API key into the wigle.conf file. See https://api.wigle.net/')
        if user == "changeme" or key == "changeme":
            raise ValueError('Please enter your API key into the wigle.conf file. See https://api.wigle.net/')
        self.auth = HTTPBasicAuth(user, key)

    def lookupNetworks(self, lat, lon):
        """Lookup an WPA2 networks via Wigle's database"""
        from datetime import datetime, timedelta
        currentDate = datetime.today()
        targetDate = currentDate - timedelta(days=90)
        
        s = "https://api.wigle.net/api/v2/network/search?onlymine=false&first=0&latrange1=%s&latrange2=%s&longrange1=%s&longrange2=%s&lastupdt=%s&encryption=WPA2&freenet=false&paynet=false&minQoS=2&resultsPerPage=50" % (float(lat)-0.0005, float(lat)+0.0005, float(lon)-0.0005, float(lon)+0.0005, targetDate.strftime('%Y%m%d'))
    
        print("HTTP request: " + s)

        r = requests.get(s, auth=self.auth)

        if r.status_code != 200:
            logging.error("Unable to lookup location, bad status: %d. Have you set your API keys correctly?" % r.status_code)
            return
        try:
            result = r.json()
        except:
            try:
                result = r.json
            except Exception as e:
                logging.error("Unable to decode JSON response for location %s, %s" % (lat, lon))
                logging.error(e)
                return

        networks = result.get('results')
        bssids = []
        index = 0
        while index < len(networks):
            bssids.append(networks[index].get('netid'))
            index += 1
        return bssids,len(networks)

    def getConstArrObjInitString(self, arr):
        result = "const uint8_t mac[][6] = {"
        index = 0
        # Format for each mac: {0x00,0x00,0x00,0x00,0x00,0x00}
        while index < len(arr):
            result += "{"
            mac = arr[index].split(":")
            result = result+"0x"+mac[0]+",0x"+mac[1]+",0x"+mac[2]+",0x"+mac[3]+",0x"+mac[4]+",0x"+mac[5]+"}"
            if index < len(arr)-1:
                result += ","
            index += 1
        result += "};"
        return result

if __name__ == "__main__":
    import sys
    from pprint import pprint as pp
    if len(sys.argv) != 3:
        print("Supply latitude and longtitude values to lookup.")
        exit(-1)
    
    w = Wigle()
    bssids,count = w.lookupNetworks(sys.argv[1], sys.argv[2])
    pp(bssids)
    print("BSSIDs found: " + str(count))

    f = open("macAddr.txt","w+")
    print("Converting mac addresses to a string defining an array object...\n")
    results = w.getConstArrObjInitString(bssids)
    f.write(results)
    f.close()
