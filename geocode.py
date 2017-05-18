# import the geocoding services you'd like to try
from geopy.geocoders import ArcGIS, Bing, Nominatim, OpenCage, GeocoderDotUS, GoogleV3, OpenMapQuest
import csv, sys

#print 'creating geocoding objects!'

print "CSV max size limit"
print csv.field_size_limit()
print "attempting to increase to available max"

maxInt = sys.maxsize
newlimit=maxInt
decrement = True

while decrement:
    # decrease the maxInt value by factor 10 
    # as long as the OverflowError occurs.

    decrement = False
    try:
        csv.field_size_limit(maxInt)
        newlimit=maxInt
    except OverflowError:
        maxInt = int(maxInt/10)
        decrement = True

print "new max size CSV limit"
print newlimit

nominatim = Nominatim(timeout=100)
googlev3 = GoogleV3('---INSERT YOUR API KEY HERE---',timeout=100)
arcgis = ArcGIS(timeout=100)

#bing = Bing('your-API-key',timeout=100)
#opencage = OpenCage('your-API-key',timeout=100)
#geocoderDotUS = GeocoderDotUS(timeout=100)
#openmapquest = OpenMapQuest(timeout=100)

# choose and order your preference for geocoders here
geocoders = [googlev3,arcgis,nominatim]

def geocode(address):
	i = 0
	while i < len(geocoders):
		try:
			# try to geocode using a service
			print (geocoders[i])
			location = geocoders[i].geocode(address)
			# if it returns a location
			if location != None:    
				# return those values
				answer = [location.latitude, location.longitude]
				print answer
				return answer
			else:
				# otherwise try the next one
				i += 1
		except:
			# catch whatever errors, likely timeout, and return null values
			print sys.exc_info()[0]
			if i < len(geocoders):
				i += 1
			else:
				# if all services have failed to geocode, return null values
				print "returning null null, all geocode services failed to find this location"
				return ['null','null']
        			
print 'geocoding addresses!'

# list to hold all rows
dout = []

csv.register_dialect('space', delimiter=' ')
csv.register_dialect('comma', delimiter=',')
  
with open('OUTPUT/urlcount-merged-file.csv', mode='rb') as fin:

    reader = csv.reader(fin, dialect='space')
    j = 0
    for row in reader:
        print 'processing #',j
        j+=1
        try:
			#print row
			# configure this based upon your input CSV file
			address = row[0]
			print (address)
			result = geocode(address)
			# add the lat/lon values to the row
			row.extend(result)
			# add the new row to master list
			dout.append(row)
        except:
            print 'you are a beautiful unicorn'

print 'writing the results to file'

# print results to file
with open('OUTPUT/geocoded-locations.csv', 'wb') as fout:
    writer = csv.writer(fout, dialect='comma')
    writer.writerows(dout)

print 'all done!'