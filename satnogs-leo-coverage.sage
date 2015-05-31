#%cython
import numpy as np
import pylab,math
import matplotlib as plt
try:
	import requests
except ImportError:
	pass
import sys
reload(sys)
sys.setdefaultencoding("utf-8")
MYAPIKEY = 'Fmjtd%7Cluu82l01nd%2C22%3Do5-94zal6'

#Area functions
Scap(r,h) = 2*math.pi*h*(r+h)
Ssphere(r,h) = 4*math.pi*(r+h)^2
A(r,h,n) = Scap(r,h)*(n + \floor(Ssphere(r,h)/Scap(r,h))) - Ssphere(r,h)

def generate_weight_table(H, F, max_height):
	assert (len(H) is len(F))
	W = np.zeros(len(H))
	for i in range(len(H)):
		j = i
		while H[j] <= max_height:
			W[i] += F[j]
			j = j+1
	return W
	
def find_extrema(H,W,r0):
	assert(len(H) is len(W))
	S = []
	wmax = max(W)
	for i in range(len(H)):
		if W[i] is wmax:
			S.append(H[i])
	return S
	
def check_elevation(P, elev_fcn, min_alt, max_alt):
	flag = True #nice data
	for p in P:
		if elev_fcn(p[0],p[1]) < min_alt or elev_fcn(p[0],p[1]) > max_alt:
			#bad data
			flag = False
			break
	return flag
	
def mapquest_elevdata(lat,lon, APIKEY=MYAPIKEY):
	#latitude is limited between 56S and 60N
	if (lat < -50) or (lat > 60):
		return 10
	else:
		requesturl = 'http://open.mapquestapi.com/elevation/v1/profile?key={0}&shapeFormat=raw&latLngCollection={1},{2},,,,,'.format(APIKEY, lat,lon)
		result = requests.get(requesturl).json()
		result = result[result.keys()[0]][0]
		return float(result['height'])

def google_request_elevdata(lat, lon):
	requesturl = 'http://maps.googleapis.com/maps/api/elevation/json?locations={0},{1}'.format(lat,lon)
	result = requests.get(requesturl).json()
	result = result[result.keys()[1]][0]
	return float(result['elevation'])
	
def request_elevation(lat, lon, radians = True, APIKEY=MYAPIKEY):
	if radians:
		lat = math.degrees(lat); lon = math.degrees(lon)
		#negatives ? 
		lat = lat - int(lat/360); lon = lon - int(lon/360)
	if (lat < -50) or (lat > 60):
		return google_request_elevdata(lat,lon)
	else:
		return mapquest_elevdata(lat,lon,APIKEY)

GR = (np.sqrt(5)-1)/2
GA = math.pi*GR

def gen_fibsphere(n):
	pts = []
	for i in range(1,n+1):
		lat = GA*i
		lon = math.asin(-1+2*i/n)
		pts.append(np.array((lat,lon)))
	return pts
#TODO proto tetartimorio	
	
def to_cartesian(pts, R):
	pts2 = []
	for p in pts:
		phi, theta = p[0],p[1]
		x,y,z = R*math.cos(phi)*math.sin(theta), R*math.sin(phi)*math.sin(theta), R*math.cos(theta)
		pts2.append(np.array([x,y,z]))
	return pts2
	
def distance(u,v):
	return np.sqrt(np.dot(u-v,u-v))

def get_distances(pts):
	distances = np.zeros([len(pts),len(pts)])
	for i in range(len(pts)):
		for j in range(len(pts)):
			if i<j:
				distances[i][j] = distance(pts[i],pts[j])
				
	return distances

def find_equidistant_pts(pts):
	distances = get_distances(pts)
	results = {}
	for i in range(len(pts)):
		for j in range(len(pts)):
			if i<j:
				if distances[i][j] not in results.keys():
					results[distances[i][j]] = [(i,j)]
				else:
					results[distances[i][j]].append((i,j))
	return results
	
def plot_pts(pts):
	X,Y,Z = [],[],[]
	for x,y,z in pts:
		X.append(x); Y.append(y); Z.append(z) 
	matplotlib.pyplot.scatter(x,y,z)
	matplotlib.pyplot.show()
		
if __name__ == '__main__':
	EARTH_RADIUS = 6371
	max_broadcast_altitude = 500 #TODO Check
	min_altitude = 0
	max_altitude = 1800
	#init_lat = 
	#init_long = 
	H = [] #heights
	F = [] #relative frequencies
	W = generate_weight_table(H,F,max_broadcast_altitude)
	extrema = find_extrema(H,W,EARTH_RADIUS)
	for extremum in extrema:
		flag = False
		N = ceil(Ssphere(EARTH_RADIUS,extremum)/Scap(EARTH_RADIUS,extremum))
		while flag is False:
		flag = True
		pts = gen_fibsphere(N)
		for pt in pts:
			elev = request_elevation(pt[0],pt[1]) 
			if elev < min_altitude or elev > max_altitude:
				flag = False
				break
		if not(flag):
			N += 1
		
				
			
		
		
		
	
	
	
