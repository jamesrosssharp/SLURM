#!/usr/bin/python3

#
#
#	Generate sin and cos tables
#
#

import math

print("\t.global height_table")
print("height_table:")
for i in range(0,256):
	if i == 0:
		d = 1
	else:
		d = i
	h = round(10*256 / d) 
	if h > 65535:
		h = 65535
	print("\tdw 0x%x // %f" % (h&0xffff, h) )



