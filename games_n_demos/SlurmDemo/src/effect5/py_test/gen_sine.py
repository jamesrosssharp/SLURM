#!/usr/bin/python3

#
#
#	Generate sin and cos tables
#
#

import math

print("sin_table_8_8:")
for i in range(0,512):
	print("\tdw 0x%x" % (round(256*math.sin(2*3.14*i / 512)) & 0xffff))

print("\ntan_table_8_8:")
for i in range(0,256):
	tan = math.tan(2*3.14*i / 512) 
	if tan > 127:
		tan = 127
	print("\tdw 0x%x // %f" % (round(256*tan) & 0xffff, tan))

print("\ncot_table_8_8:")
for i in range(0,256):
	tan = math.tan(2*3.14*i / 512) 
	if tan == 0:
		cot = 127
	else:
		cot = 1/tan
	print("\tdw 0x%x // %f" % (round(256*cot) & 0xffff, cot))



#print("cos_table_8_8:")
#for i in range(0,256):
#	print("\tdb 0x%x" % (round(256*math.cos(2*3.14*i / 256)) & 0xffff))


