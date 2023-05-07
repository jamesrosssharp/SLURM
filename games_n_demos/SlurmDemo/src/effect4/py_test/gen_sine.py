#!/usr/bin/python3

#
#
#	Generate sin and cos tables
#
#

import math

print("sin_table_8_8:")
for i in range(0,256):
	print("\tdw 0x%x" % (round(256*math.sin(2*3.14*i / 256)) & 0xffff))

#print("cos_table_8_8:")
#for i in range(0,256):
#	print("\tdb 0x%x" % (round(256*math.cos(2*3.14*i / 256)) & 0xffff))


