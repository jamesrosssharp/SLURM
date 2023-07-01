#!/usr/bin/python3

import pygame
import random
import math
import sys
from PIL import Image
import numpy as np

# Window dimensions
width = 320
height = 240

pixelWidth = 2
pixelHeight = 2

screen = pygame.display.set_mode((width * pixelWidth, height * pixelHeight))
clock = pygame.time.Clock()
running = True

#=================== Put pixel ===============================

class Point:

	def __init__(self, x, y):
		self.x = x
		self.y = y

	def step_forward(self, ang):

		self.x -= math.sin(ang)
		self.y -= math.cos(ang)

	def step_backward(self, ang):

		self.x += math.sin(ang)
		self.y += math.cos(ang)



def putPixel(x, y, r, g, b):

		x1 = x * pixelWidth;
		y1 = y * pixelHeight;

		if (x1 > 2*width or x1 < 0):
			return

		if (y1 > 2*height or y1 < 0):
			return

		for i in range (x1, x1 + pixelWidth):
			for j in range (y1, y1 + pixelHeight):
				screen.set_at((i, j), (r, g, b))


def DrawVerticalLine(x, y1, y2, colour, cmap, z):

	if y2 < 0:
		y2 = 0
	if y1 < 0:
		y1 = 0

	for y in range(int(y1) + 120, int(y2) + 120):
		putPixel(x, y, z*cmap[colour*3], z*cmap[colour*3+1], z*cmap[colour*3+2])

	for y in range(120 - int(y2), 120 - int(y1)):
		putPixel(x, y, z*cmap[colour*3], z*cmap[colour*3+1], z*cmap[colour*3+2])




def Render(p, phi, height, horizon, scale_height, distance, screen_width, screen_height, heightmap, colormap, cmap):
    # precalculate viewing angle parameters
    sinphi = math.sin(phi);
    cosphi = math.cos(phi);
    
    # initialize visibility array. Y position for each column on screen 
    ybuffer = np.zeros(screen_width)
    for i in range(0, screen_width):
        ybuffer[i] = screen_height

    # Draw from front to the back (low z coordinate to high z coordinate)
    dz = 1.
    z = 20.
    while z < distance:
        # Find line on map. This calculation corresponds to a field of view of 90°
        pleft = Point(
            (-cosphi*z - sinphi*z) + p.x,
            ( sinphi*z - cosphi*z) + p.y)
        pright = Point(
            ( cosphi*z - sinphi*z) + p.x,
            (-sinphi*z - cosphi*z) + p.y)

        # segment the line
        dx = (pright.x - pleft.x) / screen_width
        dy = (pright.y - pleft.y) / screen_width

        # Raster line and draw a vertical line for each segment
        for i in range(0, screen_width):
            height_on_screen = (height - heightmap.getpixel((int(pleft.x) & 255, int(pleft.y) & 1023))) / z * scale_height + horizon
            DrawVerticalLine(i, height_on_screen, ybuffer[i], colormap.getpixel((int(pleft.x) & 255, int(pleft.y) & 1023)), cmap, 1.0 - z / distance)
            if height_on_screen < ybuffer[i]:
                ybuffer[i] = height_on_screen
            pleft.x += dx
            pleft.y += dy

        # Go to next line and increase step size when you are far away
        z += dz
        dz += 0.2


#===================== Main loop ================================

# Open height map

height_map = Image.open("Cave-height.png")
#height_map = Image.open("D1.png")

# Open colour map

#colour_map = Image.open("C1W.png")
colour_map = Image.open("Cave-color.png")

frame = 0

player = Point(76,10)

ang = 3.14

while running:

	Render( player, ang, 30, 90, 50, 64, 320, 120, height_map, colour_map, colour_map.getpalette() )

	for event in pygame.event.get():
		if event.type == pygame.QUIT:
				running = False
		#elif event.type == pygame.KEYDOWN or event.type == pygame.KEYUP:
		#if 1:	
	keys = pygame.key.get_pressed()

	if keys[pygame.K_LEFT]:
		ang += 0.0314

	if keys[pygame.K_RIGHT]:
		ang -= 0.0314

	if keys[pygame.K_UP]:
		player.step_forward(ang)

	if keys[pygame.K_DOWN]:
		player.step_backward(ang)

	if keys[pygame.K_SPACE]:
		runDemo = not runDemo



	pygame.display.flip()
	clock.tick(20)

	frame += 1

	screen.fill((0,0,0))


