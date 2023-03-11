#! /usr/bin/python

import math

#
#	Generate linear pitch slide up table
#

slide_up_lo = []
slide_up_hi = []
slide_down_lo = []
slide_down_hi = []


for i in range(0, 256):
	val = int(math.floor(65536 * 2**(i / 192)))
	lo = val & 0xffff
	hi = val >> 16
	slide_up_lo.append(lo)
	slide_up_hi.append(hi)

for i in range(0, 256):
	val = int(math.floor(65536 * 2**(-i / 192)))
	lo = val & 0xffff
	hi = val >> 16
	slide_down_lo.append(lo)
	slide_down_hi.append(hi)

def print_table(table, title):

	print("const unsigned short %s[256] = {\n\t" % title, end="")
	i = 0
	for s in table:
		print("%d, " % s, end="")
		if (i % 8 == 7):
			print("\n\t", end="")
		i += 1
	print("};")

print_table(slide_up_lo, "slide_up_lo")
print_table(slide_up_hi, "slide_up_hi")
print_table(slide_down_lo, "slide_down_lo")
print_table(slide_down_hi, "slide_down_hi")
