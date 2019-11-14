#!/usr/bin/python

import pyproj

lat, lon = 40.7106779,-74.009618
alt = 100

ecef = pyproj.Proj(proj='geocent', ellps='WGS84', datum='WGS84')
lla = pyproj.Proj(proj='latlong', ellps='WGS84', datum='WGS84')

x, y, z = pyproj.transform(lla, ecef, lon, lat, alt, radians=False)

print lat, lon, alt
print x, y, z
