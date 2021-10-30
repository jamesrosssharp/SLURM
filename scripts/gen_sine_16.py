
import math

amp = 1

for i in range(0,32):
	print("\tdw 0x%x" % (0xb000 + int(amp + amp*math.sin(2*3.14*i / 16.0) + 0.5)))

