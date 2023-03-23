
import math

amp = 31

for i in range(0,256):
	print("\tdb 0x%x" % (int(amp  + 1 + amp*math.sin(2*3.14*i / 256) + 0.5)))

