# import the geocoding services you'd like to try
import csv, sys

#print 'generating mapsAPI HTML code
#convert:
#CSV row: "Alma, QC",5,5.0,48.548885,"{(http://e-artexte.ca/23426),(http://e-artexte.ca/25344),(http://e-artexte.ca/23422),(http://e-artexte.ca/23428),(http://e-artexte.ca/23425)}"
#to
#CSV row: "Alma, QC",5,5.0,48.548885,"<a href='http://e-artexte.ca/23426'>item</a>,(http://e-artexte.ca/25344),(http://e-artexte.ca/23422),(http://e-artexte.ca/23428),(http://e-artexte.ca/23425)}"
#replace all "(" with "<a href='"
#replace all ")" with "'>item</a>"


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

# list to hold all rows
dout = []

csv.register_dialect('space', delimiter=' ')
csv.register_dialect('comma', delimiter=',')
  
with open('OUTPUT/urlcount_with_locations-merged-file.csv', mode='rb') as fin:

    reader = csv.reader(fin, dialect='comma')
    j = 0
    for row in reader:
        print 'processing #',j
        j+=1
        try:
			#print row
			# configure this based upon your input CSV file
			#45.43719,12.33459,{(Venise : Italie)},3,"{({(http://e-artexte.ca/23088),(http://e-artexte.ca/20010),(http://e-artexte.ca/23088)})}"
			urls = row[4]
			locations = row[2]
			print locations
			if (locations.find("(s.l.)") <> -1):
				print(row[2])
				print("setting to 0,0")
  				row[0]=0
  				row[1]=0
  			if (row[0] == ''):
  				print(row[2])
				print("setting to 1.0,1.0")
  				row[0]="1.0"
  				row[1]="1.0"
			#print (urls)
			result = urls.replace("(http", "<a href='http")
			result = result.replace("})}", "}}")
			result = result.replace(")", "'>item</a>")
			result = result.replace("}'>item</a>","}")
			# add the lat/lon values to the row
			row[4] = result;
			# add the new row to master list
			dout.append(row)
        except:
            print 'you are a beautiful unicorn'

print 'writing the results to file'

# print results to file
with open('OUTPUT/geocoded-locations-fusion-table.csv', 'wb') as fout:
    writer = csv.writer(fout, dialect='comma')
    writer.writerows(dout)

print 'all done!'