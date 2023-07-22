#!/usr/bin/python

import math
import sys
from PIL import Image
import numpy as np

width = 160
height = 100

TEXTURE_WIDTH = 64
TEXTURE_HEIGHT = 64

texture = Image.open("texture.png")

distance_table = np.zeros((height*2, width*2), dtype = int)
shade_table = np.zeros((height*2, width*2), dtype = int)
angle_table = np.zeros((height*2, width*2), dtype = int)
color_table = np.zeros((16, 16), dtype = int)

for y in range(0, height*2):
	for x in range(0, width*2):
		ratio = 64.0
		
		if x - width == 0 and y - height == 0:
			d = 0
		else :
			d = int(ratio * TEXTURE_HEIGHT / math.sqrt((x - width)*(x - width) + (y - height)*(y - height)))
 
		distance_table[y][x] = d % TEXTURE_HEIGHT 

		if d == 0:
			shade = 0
		elif d > 80:
			shade = int(300 - d) >> 4
		else:
			shade = 15		

		if shade < 0:
			shade = 0

		shade_table[y][x] = shade

		angle_table[y][x] =  int(2.0 * TEXTURE_WIDTH * math.atan2(float(y - height), float(x - width)) / 3.1416) % TEXTURE_WIDTH	


	
# build color table

colormap = texture.getpalette()

for i in range(0, 16):
	for c in range(0, 16):
		color = colormap[c * 3: c * 3 + 3]

		scale = i / 16.0
		new_col = np.array(color) * scale

		# Find nearest color

		dist = 10000000.0

		the_match = None

		for cc in range(0, 16):
			match_col = np.array(colormap[cc*3:cc*3+3])
			d = np.linalg.norm(new_col - match_col)

			if d < dist:
				dist = d
				the_match = cc

		color_table[i][c] = the_match

# Output tables as binary blobs

import struct

with open("../../../assets/images_out/tunnel_distance_table.bin", "wb") as fil:

	for y in range(0, height*2):
		for x in range(0, width*2):
			fil.write(struct.pack("B", distance_table[y][x]))	

with open("../../../assets/images_out/tunnel_angle_table.bin", "wb") as fil:

	for y in range(0, height*2):
		for x in range(0, width*2):
			fil.write(struct.pack("B", angle_table[y][x]))	

with open("../../../assets/images_out/tunnel_shade_table.bin", "wb") as fil:

	for y in range(0, height*2):
		for x in range(0, width*2):
			fil.write(struct.pack("B", shade_table[y][x]))	

with open("../../../assets/images_out/color_table.bin", "wb") as fil:

	for y in range(0, 16):
		for x in range(0, 16):
			fil.write(struct.pack("B", color_table[y][x]))	

