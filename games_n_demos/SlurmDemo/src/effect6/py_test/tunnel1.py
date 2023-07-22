
#!/usr/bin/python3

import pygame
import random
import math
import sys
from PIL import Image
import numpy as np

SQUARE_WIDTH = 32
SQUARE_SHIFT = 5
# Window dimensions
width = 80
height = 40

pixelWidth = 4
pixelHeight = 4

my_drawmap = False

SINETABLE_SIZE = 512

screen = pygame.display.set_mode((width * pixelWidth, height * pixelHeight))
clock = pygame.time.Clock()
running = True

fish_eye_table = []

texture = None
distance_table = np.zeros((height*2, width*2))
angle_table = np.zeros((height*2, width*2))
color_table = np.zeros((16, 16), dtype = int)

TEXTURE_HEIGHT = 64
TEXTURE_WIDTH = 64

#=================== Put pixel ===============================

def putPixel(x, y, r, g, b):

		x1 = x * pixelWidth;
		y1 = y * pixelHeight;

		if (x1 > pixelWidth*width or x1 < 0):
			return

		if (y1 > pixelHeight*height or y1 < 0):
			return

		for i in range (x1, x1 + pixelWidth):
			for j in range (y1, y1 + pixelHeight):
				screen.set_at((i, j), (r, g, b))

def render(frame):

	shiftX = int(TEXTURE_WIDTH * 0.1 * frame)	
	shiftY = int(TEXTURE_WIDTH * 0.1 * frame)	
	
	shiftLookX = width // 2 + int (width / 2 * 0.75 * math.sin(frame * 0.05))
	shiftLookY = height // 2 + int (height / 2 * 0.75 * math.sin(frame * 0.1))

	for y in range(0, height):
		for x in range(0, width):
			u = int(distance_table[y + shiftLookY][x + shiftLookX] + shiftX) % TEXTURE_WIDTH
			v = int(angle_table[y + shiftLookY][x + shiftLookX] + shiftY) % TEXTURE_HEIGHT

			scale = 1.0			

			d = distance_table[y + shiftLookY][x + shiftLookX]
			
			if d == 0:
				d = 0
			elif d > 20:
				d = int(300 - d) >> 4
			else:
				d = 15		

			if d < 0:
				d = 0

			color = texture.getpixel((u, v))
			
			color = color_table[int(d)][color]
			color = texture.getpalette()[color*3:color*3+3]
			

			putPixel(x, y, int(color[0] * scale), int(color[1] * scale), int(color[2] * scale)) 


#===================== Main loop ================================

# Open level map

texture = Image.open("texture3.png")

# compute tables

frame = 0

for y in range(0, height*2):
	for x in range(0, width*2):
		ratio = 64.0
		if x - width == 0 and y - height == 0:
			pass
		else :
			distance_table[y][x] = int(ratio * TEXTURE_HEIGHT / math.sqrt((x - width)*(x - width) + (y - height)*(y - height)))
		angle_table[y][x] =  int(2.0 * TEXTURE_WIDTH * math.atan2(float(y - height), float(x - width)) / 3.1416) % TEXTURE_WIDTH;		
	
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

print(color_table)

while running:

	render(frame)

	for event in pygame.event.get():
		if event.type == pygame.QUIT:
				running = False
		#elif event.type == pygame.KEYDOWN or event.type == pygame.KEYUP:
		#if 1:	

	pygame.display.flip()
	clock.tick(20)

	frame += 1

	screen.fill((0,0,0))


