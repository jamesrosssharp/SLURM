
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
width = 640
height = 240

pixelWidth = 2
pixelHeight = 2

my_drawmap = False

SINETABLE_SIZE = 512

screen = pygame.display.set_mode((width * pixelWidth, height * pixelHeight))
clock = pygame.time.Clock()
running = True

fish_eye_table = []

texture = None
texture2 = None

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

def DrawTexturedVLine(x, y1, y2, u, idx, colour):

	v1 = 0
	v2 = 31

	dv = (v2 - v1) / (y2 - y1)
	v = v1
	
	if y1 < 0:
		v = dv * -y1
		y1 = 0


	for y in range(int(y1), min(int(y2), 240)):
		if idx == 1:
			col = texture.getpixel((u & 31, round(v) & 31))
		else:
			col = texture2.getpixel((u & 31, round(v) & 31))
		#print ("%d %d" % (u & 15, y & 15))
	
		if (y > 0):
			putPixel(x, y, col[0], col[1], col[2])
			putPixel(x + 1, y, col[0], col[1], col[2])
			putPixel(x + 2, y, col[0], col[1], col[2])
			putPixel(x + 3, y, col[0], col[1], col[2])
		v += dv




def my_sin(ang, sine_table):
	return sine_table[ang & (SINETABLE_SIZE - 1)]

def my_cos(ang, sine_table):
	return sine_table[(ang + SINETABLE_SIZE//4) & (SINETABLE_SIZE - 1)]


def dist(x1, y1, x2, y2):
	a = x2 - x1
	b = y2 - y1
	return math.sqrt(a*a + b*b)

def fire_ray(p, p_ang, phi_ray, sx, height_map, sine_table, tan_table, cot_table):

	up = False
	right = False

	phi_ray &= (SINETABLE_SIZE - 1)

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

	col1 = 0
	col2 = 0

	# Ray1 looks at horizontal lines
	if up:
		ray1_y_prestep = ((p.y() >> SQUARE_SHIFT) << SQUARE_SHIFT) - p.y() 
		ray1_x_prestep = -ray1_y_prestep * cot_table[phi_ray]

		ray1_y_step = -SQUARE_WIDTH
		ray1_x_step = SQUARE_WIDTH * cot_table[phi_ray]

	else:
		ray1_y_prestep = ((((p.y() +  (SQUARE_WIDTH - 1)) >> SQUARE_SHIFT) << SQUARE_SHIFT)) - p.y()
		ray1_x_prestep = -ray1_y_prestep * cot_table[phi_ray]

		ray1_y_step = SQUARE_WIDTH
		ray1_x_step = -SQUARE_WIDTH * cot_table[phi_ray]

	# Ray2 looks at vertical lines
	if not right:
		ray2_x_prestep = ((p.x() >> SQUARE_SHIFT) << SQUARE_SHIFT) - p.x() 
		ray2_y_prestep = -ray2_x_prestep * tan_table[phi_ray]

		ray2_x_step = -SQUARE_WIDTH
		ray2_y_step = SQUARE_WIDTH * tan_table[phi_ray]

	else:
		ray2_x_prestep = ((((p.x() + SQUARE_WIDTH - 1) >> SQUARE_SHIFT) << SQUARE_SHIFT)) - p.x() 
		ray2_y_prestep = -ray2_x_prestep * tan_table[phi_ray]

		ray2_x_step = SQUARE_WIDTH
		ray2_y_step = -SQUARE_WIDTH * tan_table[phi_ray]


	#print("Phi ray: %f %d" % (phi_ray / SINETABLE_SIZE * 360, phi_ray))

	x1 = x2 = p.x()
	y1 = y2 = p.y()
	
	x1 += ray1_x_prestep
	y1 += ray1_y_prestep
	
	x2 += ray2_x_prestep
	y2 += ray2_y_prestep

	found1 = False
	found2 = False
	
	i = 0
	while i < 20 and not found1 and not found2:

	
		while (right and x1 <= x2) or (not right and x1 >= x2): 
			if not (0 <= round(x1) < 32*SQUARE_WIDTH):
				break

			if not (0 <= round(y1) < 32*SQUARE_WIDTH):
				break
			
			if my_drawmap:
				putPixel(int(x1), int(y1), 0, 255, 0)
			if up:
				col1 = height_map.getpixel((int(x1) >> SQUARE_SHIFT, int(y1 - (SQUARE_WIDTH - 1)) >> SQUARE_SHIFT))
			else:
				col1 = height_map.getpixel((int(x1) >> SQUARE_SHIFT, int(y1) >> SQUARE_SHIFT))

			if col1 != 0:
				found1 = True
				break

			x1 += ray1_x_step
			y1 += ray1_y_step


		while (up and y2 >= y1) or (not up and y2 <= y1):

			if x2 < 0 or round(x2) >= 32*SQUARE_WIDTH:
				break

			if y2 < 0 or round(y2) >= 32*SQUARE_WIDTH:
				break

			if my_drawmap:
				putPixel(int(x2), int(y2), 255, 255, 255)
			
			if not right:
				col2 = height_map.getpixel((int(x2 - (SQUARE_WIDTH - 1) ) >> SQUARE_SHIFT, int(y2) >> SQUARE_SHIFT))
			else:
				col2 = height_map.getpixel((int(x2 ) >> SQUARE_SHIFT, int(y2) >> SQUARE_SHIFT))

			if col2 != 0:
				found2 = True
				break

			x2 += ray2_x_step
			y2 += ray2_y_step

		i += 1

	d1 = my_cos(p_ang, sine_table)*(x1 - p.x()) - my_sin(p_ang, sine_table)*(y1 - p.y())
	d2 = my_cos(p_ang, sine_table)*(x2 - p.x()) - my_sin(p_ang, sine_table)*(y2 - p.y())

	if not found1:
		d1 = 1000000.0
	if not found2:
		d2 = 1000000.0

	if d1 < d2:
		horiz = True
		u = round(x1) 
		d = d1
		col = col1
	else:
		horiz = False
		u = round(y2) 
		d = d2
		col = col2

	return (d, u, horiz, col)




def Render(p, phi, screen_width, screen_height, height_map, sine_table, tan_table, cot_table):

	# phi = player viewing angle

	phi_start = phi + 40 # (phi + (SINETABLE_SIZE // 12))
	phi_end   = phi - 40 #(phi - (SINETABLE_SIZE // 12)) 

	phi_step = (phi_end - phi_start) / screen_width

	phi_ray = phi_start

	for sx in range(0, screen_width, 4):


		(d, u, horiz, col) = fire_ray(p, phi & (SINETABLE_SIZE - 1), int(phi_ray) & (SINETABLE_SIZE - 1), sx, height_map, sine_table, tan_table, cot_table)

		if d < 5.0:
			d = 5.0
		h = 100 * SQUARE_WIDTH / d 

		y1 = 120 - h
		y2 = 120 + h

		if horiz:
		#	DrawVLine(320 + sx, y1, y2, (0, 0, 255)) 	
			DrawTexturedVLine(320 + sx, y1, y2, u, col, (1.0, 1.0, 1.0))
			#DrawTexturedVLine(320 + sx + 1, y1, y2, u, col, (1.0, 1.0, 1.0))
			#DrawTexturedVLine(320 + sx + 2, y1, y2, u, col, (1.0, 1.0, 1.0))
			#DrawTexturedVLine(320 + sx + 3, y1, y2, u, col, (1.0, 1.0, 1.0))
		else:
		#	DrawVLine(320 + sx, y1, y2, (100, 100, 255)) 	
			DrawTexturedVLine(320 + sx, y1, y2, u, col, (0.9, 0.9, 0.9))
			#DrawTexturedVLine(320 + sx + 1, y1, y2, u, col, (0.9, 0.9, 0.9))
			#DrawTexturedVLine(320 + sx + 2, y1, y2, u, col, (0.9, 0.9, 0.9))
			#DrawTexturedVLine(320 + sx + 3, y1, y2, u, col, (0.9, 0.9, 0.9))

		phi_ray += 4*phi_step

def DrawMap(p, my_map):

	for x in range(0, 32*SQUARE_WIDTH):
		for y in range(32*SQUARE_WIDTH):
			if my_map.getpixel((x>>SQUARE_SHIFT, y>>SQUARE_SHIFT)):
				putPixel(x, y, 0, 0, 255)

	putPixel(p.x(), p.y(), 255, 0, 0)



#===================== Main loop ================================

# Open level map

my_map = Image.open("Map.png")

texture = Image.open("Brick32.png")
texture2 = Image.open("Brick32_2.png")

frame = 0

player = Point(2*SQUARE_WIDTH + 0.5 * SQUARE_WIDTH,2*SQUARE_WIDTH + 0.5 * SQUARE_WIDTH)

ang = 0

sine_table = [math.sin(x*math.pi*2/SINETABLE_SIZE) for x in range(0, SINETABLE_SIZE)]
tan_table = [math.tan(x*math.pi*2/SINETABLE_SIZE) for x in range(0, SINETABLE_SIZE)]
cot_table = [math.tan(x*math.pi*2/SINETABLE_SIZE)  for x in range(0, SINETABLE_SIZE)]
fish_eye_table = [math.cos(((x*math.pi/3)/320) - math.pi / 6) for x in range(0, 320)]

for i in range(0, SINETABLE_SIZE):
	if cot_table[i] != 0.0:
		cot_table[i] = 1.0 / cot_table[i]
	else:	
		cot_table[i] = 100000.0


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


