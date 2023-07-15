#!/usr/bin/python3

#
#
#	Generate sin and cos tables
#
#

import math

print("\t.global sin_table_2_14")
print("sin_table_2_14:")
for i in range(0,512):
	print("\tdw 0x%x" % (round(16384*math.sin(2*3.14*i / 512)) & 0xffff))

print("\n\t.global tan_table_16_16")
print("tan_table_16_16:")
for i in range(0,256):
	tan = math.tan(2*3.14*i / 512) 
	if tan > 10000:
		tan = 10000
	print("\tdw 0x%x // " % (round(65536*tan) & 0xffff))
	print("\tdw 0x%x // %f" % ((round(65536*tan) >> 16) & 0xffff, tan))

print("\n\t.global cot_table_16_16:")
print("cot_table_16_16:")
for i in range(0,256):
	tan = math.tan(2*3.14*i / 512) 
	if tan == 0:
		cot = 100000
	else:
		cot = 1/tan
	print("\tdw 0x%x // " % (round(65536*cot) & 0xffff))
	print("\tdw 0x%x // %f" % ((round(65536*cot) >> 16) & 0xffff, cot))



#print("cos_table_8_8:")
#for i in range(0,256):
#	print("\tdb 0x%x" % (round(256*math.cos(2*3.14*i / 256)) & 0xffff))


