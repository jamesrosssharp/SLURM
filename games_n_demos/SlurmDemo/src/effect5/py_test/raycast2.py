
#!/usr/bin/python3

import pygame
import random
import math
import sys
from PIL import Image
import numpy as np

SQUARE_WIDTH = 16
SQUARE_SHIFT = 4
# Window dimensions
width = 640
height = 240

pixelWidth = 2
pixelHeight = 2

my_drawmap = False

SINETABLE_SIZE = 1024

screen = pygame.display.set_mode((width * pixelWidth, height * pixelHeight))
clock = pygame.time.Clock()
running = True

#=================== Put pixel ===============================

class Point:

	def __init__(self, x, y):
		self._x = x
		self._y = y

	def step_forward(self, ang, sine_table):

		self._y -= 4*my_sin(ang, sine_table)
		self._x += 4*my_cos(ang, sine_table)

	def step_backward(self, ang, sine_table):

		self._y += 4*my_sin(ang, sine_table)
		self._x -= 4*my_cos(ang, sine_table)

	def x(self):
		return round(self._x)
	
	def y(self):
		return round(self._y)	



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


def DrawVLine(x, y1, y2, colour):

	if y1 < 0:
		y1 = 0
	if y2 > 240:
		y2 = 240

	for y in range(int(y1), int(y2)):
		putPixel(x, y, colour[0], colour[1], colour[2])

def my_sin(ang, sine_table):
	return sine_table[ang & (SINETABLE_SIZE - 1)]

def my_cos(ang, sine_table):
	return sine_table[(ang + SINETABLE_SIZE//4) & (SINETABLE_SIZE - 1)]


def dist(x1, y1, x2, y2):
	a = x2 - x1
	b = y2 - y1
	return math.sqrt(a*a + b*b)

def fire_ray(p, phi_ray, sx, height_map, sine_table, tan_table, cot_table):

	up = False
	right = False

	if (0 < phi_ray < SINETABLE_SIZE // 2):
		up = True

	if (phi_ray > SINETABLE_SIZE * 3 // 4) or (phi_ray < (SINETABLE_SIZE // 4)):
		right = True

	ray1_x_prestep = 0
	ray1_y_prestep = 0
	ray1_x_step = 0
	ray1_y_step = 0

	ray2_x_prestep = 0
	ray2_y_prestep = 0
	ray2_x_step = 0
	ray2_y_step = 0

	# Ray1 looks at horizontal lines
	if up:
		ray1_y_prestep = ((p.y() >> SQUARE_SHIFT) << SQUARE_SHIFT) - p.y() - 1 
		ray1_x_prestep = -ray1_y_prestep * cot_table[phi_ray & (SINETABLE_SIZE - 1)]

		ray1_y_step = -SQUARE_WIDTH
		ray1_x_step = SQUARE_WIDTH * cot_table[phi_ray & (SINETABLE_SIZE - 1)]

	else:
		ray1_y_prestep = (((p.y() >> SQUARE_SHIFT) << SQUARE_SHIFT) + SQUARE_WIDTH) - p.y() 
		ray1_x_prestep = -ray1_y_prestep * cot_table[phi_ray & (SINETABLE_SIZE - 1)]

		ray1_y_step = SQUARE_WIDTH
		ray1_x_step = -SQUARE_WIDTH * cot_table[phi_ray & (SINETABLE_SIZE - 1)]

	# Ray2 looks at vertical lines
	if not right:
		ray2_x_prestep = ((p.x() >> SQUARE_SHIFT) << SQUARE_SHIFT) - p.x() - 1
		ray2_y_prestep = -ray2_x_prestep * tan_table[phi_ray & (SINETABLE_SIZE - 1)]

		ray2_x_step = -SQUARE_WIDTH
		ray2_y_step = SQUARE_WIDTH * tan_table[phi_ray & (SINETABLE_SIZE - 1)]

	else:
		ray2_x_prestep = (((p.x() >> SQUARE_SHIFT) << SQUARE_SHIFT) + SQUARE_WIDTH) - p.x() 
		ray2_y_prestep = -ray2_x_prestep * tan_table[phi_ray & (SINETABLE_SIZE - 1)]

		ray2_x_step = SQUARE_WIDTH
		ray2_y_step = -SQUARE_WIDTH * tan_table[phi_ray & (SINETABLE_SIZE - 1)]

	#print("Phi ray: %f %d" % (phi_ray / SINETABLE_SIZE * 360, phi_ray))

	x1 = x2 = p.x()
	y1 = y2 = p.y()
	
	x1 += ray1_x_prestep
	y1 += ray1_y_prestep
	
	x2 += ray2_x_prestep
	y2 += ray2_y_prestep

	#if sx == 160:
	#	print("%f %f %f %f" % (x1, y1, x2, y2))	

	found1 = False
	found2 = False
	
	i = 0
	while i < 20:


		if not (0 <= round(x1) < 32*SQUARE_WIDTH):
			break

		if not (0 <= round(y1) < 32*SQUARE_WIDTH):
			break
		
		if my_drawmap:
			putPixel(int(x1), int(y1), 0, 255, 0)
		
		if height_map.getpixel((round(x1) >> SQUARE_SHIFT, round(y1) >> SQUARE_SHIFT)):
			found1 = True
			break

		x1 += ray1_x_step
		y1 += ray1_y_step

		i += 1

	i = 0
	while i < 20:


		if x2 < 0 or round(x2) >= 32*SQUARE_WIDTH:
			break

		if y2 < 0 or round(y2) >= 32*SQUARE_WIDTH:
			break

		if my_drawmap:
			putPixel(int(x2), int(y2), 255, 255, 255)
		
		if height_map.getpixel((round(x2) >> SQUARE_SHIFT, round(y2) >> SQUARE_SHIFT)):
			found2 = True
			break

		x2 += ray2_x_step
		y2 += ray2_y_step

		i += 1

	d1 = dist(round(x1), round(y1), p.x(), p.y())
	d2 = dist(round(x2), round(y2), p.x(), p.y())

	if not found1:
		d1 = 1000000.0
	if not found2:
		d2 = 1000000.0

	return min(d1, d2)



def Render(p, phi, screen_width, screen_height, height_map, sine_table, tan_table, cot_table):

	# phi = player viewing angle

	phi_start = (phi + (SINETABLE_SIZE // 8))
	phi_end   = (phi - (SINETABLE_SIZE // 8)) 

	phi_step = (phi_end - phi_start) / screen_width

	phi_ray = phi_start

	for sx in range(0, screen_width):

		phi_ray += phi_step

		d = fire_ray(p, int(phi_ray) & (SINETABLE_SIZE - 1), sx, height_map, sine_table, tan_table, cot_table)

		if d < 1.0:
			d = 1.0
		h = 600 / d;


		y1 = 120 - h
		y2 = 120 + h

		DrawVLine(320 + sx, y1, y2, (0, 0, 255)) 	


def DrawMap(p, my_map):

	for x in range(0, 32*SQUARE_WIDTH):
		for y in range(32*SQUARE_WIDTH):
			if my_map.getpixel((x>>SQUARE_SHIFT, y>>SQUARE_SHIFT)):
				putPixel(x, y, 0, 0, 255)

	putPixel(p.x(), p.y(), 255, 0, 0)



#===================== Main loop ================================

# Open level map

my_map = Image.open("Map.png")

frame = 0

player = Point(20*SQUARE_WIDTH + 0.5 * SQUARE_WIDTH,20*SQUARE_WIDTH + 0.5 * SQUARE_WIDTH)

ang = 0

sine_table = [math.sin(x*math.pi*2/SINETABLE_SIZE) for x in range(0, SINETABLE_SIZE)]
tan_table = [math.tan(x*math.pi*2/SINETABLE_SIZE) for x in range(0, SINETABLE_SIZE)]
cot_table = [math.tan(x*math.pi*2/SINETABLE_SIZE)  for x in range(0, SINETABLE_SIZE)]

for i in range(0, SINETABLE_SIZE):
	if cot_table[i] != 0.0:
		cot_table[i] = 1.0 / cot_table[i]
	else:	
		cot_table[i] = 100.0


while running:

	if my_drawmap:
		DrawMap(player, my_map)

	Render( player, ang, 320, 240, my_map, sine_table, tan_table, cot_table )

	for event in pygame.event.get():
		if event.type == pygame.QUIT:
				running = False
		#elif event.type == pygame.KEYDOWN or event.type == pygame.KEYUP:
		#if 1:	
	keys = pygame.key.get_pressed()

	if keys[pygame.K_LEFT]:
		ang += 5

	if keys[pygame.K_RIGHT]:
		ang -= 5

	if keys[pygame.K_UP]:
		player.step_forward(ang, sine_table)

	if keys[pygame.K_DOWN]:
		player.step_backward(ang, sine_table)

	if keys[pygame.K_SPACE]:
		runDemo = not runDemo

	ang &= SINETABLE_SIZE - 1

	pygame.display.flip()
	clock.tick(20)

	frame += 1

	screen.fill((0,0,0))


