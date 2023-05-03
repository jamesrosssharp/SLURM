#!/usr/bin/python3

import pygame
import random
import math

# Window dimensions
width = 320
height = 240

pixelWidth = 2
pixelHeight = 2

screen = pygame.display.set_mode((width * pixelWidth, height * pixelHeight))
clock = pygame.time.Clock()
running = True


#=================== Put pixel ===============================

def putPixel(x, y, r, g, b):

		x1 = x * pixelWidth;
		y1 = y * pixelHeight;

		for i in range (x1, x1 + pixelWidth):
			for j in range (y1, y1 + pixelHeight):
				screen.set_at((i, j), (r, g, b))

#================ Point2D ===========================

class Point2D:

	def __init__(self, xin, yin):
		self.x = xin
		self.y = yin

#================ Point3D ===========================

class Point3D:

	def __init__(self, xin, yin, zin, win):
		self.x = xin
		self.y = yin
		self.z = zin
		self.w = win

	def project(self):
		 self.x = self.x / self.w
		 self.y = self.y / self.w
		 self.z = self.z / self.w
		 self.w = self.w / self.w

	def __sub__(self, other):
         return Point3D(self.x - other.x,
                        self.y - other.y,
                        self.z - other.z,
                        self.w - other.w);

	def __add__(self, other):
         return Point3D(self.x + other.x,
                        self.y + other.y,
						self.z + other.z,
                        self.w + other.w);

	def __truediv__(self, other):
		return Point3D(self.x / other,
					   self.y / other,
					   self.z / other,
					   self.w / other)

	def norm(self):
		return math.sqrt(self.x*self.x + self.y*self.y + self.z*self.z)

	def __mul__(self, other):
		# dot product
		return self.x*other.x + self.y*other.y + self.z*other.z

	@staticmethod
	def cross(v1, v2):
		return Point3D(v1.y*v2.z - v1.z*v2.y,
					   v1.z*v2.x - v1.x*v2.z,
					   v1.x*v2.y - v1.y*v2.x,
					   1.0)

	def transform(self, matrix):
		vec = matrix * self
		self.x = vec.x
		self.y = vec.y
		self.z = vec.z
		self.w = vec.w

#================ Vertex  ===========================

class Vertex:

	def __init__(self, x, y, z):
		self.pos = Point3D(x, y, z, 1.0)
		self.col = Point3D(0.0, 0.0, 0.0, 1.0)
		# rgba => w is alpha?
		self.normal = Point3D(0.0, 0.0, 0.0, 1.0)
		self.screen = Point2D(0.0, 0.0)

	def transform(self, matrix):
		self.pos = matrix * self.pos
		return self

	def project(self):

		self.screen.x = (self.pos.x / self.pos.w) * width / 2 + width / 2
		self.screen.y = (self.pos.y / self.pos.w) * height / 2 + height / 2

		return self

	def setNormal(self, vec):
		self.normal = vec

	def shade(self, lightSource):
		lamb = 0.1
		ldiff = 1.0 - lamb
		dot = self.normal * lightSource / lightSource.norm()
		if (dot > 0):
			val = lamb + ldiff*dot
			self.col = Point3D(val, val, val, 1.0)
		else:
			self.col = Point3D(lamb, lamb, lamb, 1.0)

	def __str__(self):
		return "Pos: %f,%f,%f,%f Tex: %f,%f Col: %f,%f,%f Screen: %f,%f" % (self.pos.x, self.pos.y, self.pos.z, self.pos.w,
															  self.tex.x, self.tex.y, self.col.x, self.col.y, self.col.z,
															  self.screen.x, self.screen.y)

#================ Matrix4 ============================

class Matrix4:

	def __init__(self, x1, y1, z1, w1, x2, y2, z2, w2,
                 x3, y3, z3, w3, x4, y4, z4, w4):
		self.x1 = x1
		self.x2 = x2
		self.x3 = x3
		self.x4 = x4
		self.y1 = y1
		self.y2 = y2
		self.y3 = y3
		self.y4 = y4
		self.z1 = z1
		self.z2 = z2
		self.z3 = z3
		self.z4 = z4
		self.w1 = w1
		self.w2 = w2
		self.w3 = w3
		self.w4 = w4

	@staticmethod
	def makeIdentity():
		return Matrix4(1.0,0.0,0.0,0.0,
					   0.0,1.0,0.0,0.0,
					   0.0,0.0,1.0,0.0,
					   0.0,0.0,0.0,1.0)

	@staticmethod
	def makeRotX(rx):
		return Matrix4(1.0,0.0,0.0,0.0,
					   0.0,math.cos(rx),-math.sin(rx),0.0,
					   0.0,math.sin(rx),math.cos(rx),0.0,
					   0.0,0.0,0.0,1.0)

	@staticmethod
	def makeRotY(ry):
		return Matrix4(math.cos(ry), 0.0, math.sin(ry),0.0,
					   0.0,1.0,0.0,0.0,
					   -math.sin(ry),0.0, math.cos(ry),0.0,
					   0.0,0.0,0.0,1.0)

	@staticmethod
	def makeRotZ(rz):
		return Matrix4(math.cos(rz), -math.sin(rz),0.0,0.0,
					   math.sin(rz), math.cos(rz), 0.0,0.0,
					   0.0,0.0,1.0,0.0,
					   0.0,0.0,0.0,1.0)

	@staticmethod
	def makeRot(rx, ry, rz):
		return Matrix4.makeRotX(rx)*Matrix4.makeRotY(ry)*Matrix4.makeRotZ(rz)


	@staticmethod
	def makeScale(sx, sy, sz):
		return Matrix4(sx,0.0,0.0,0.0,
					   0.0,sy,0.0,0.0,
					   0.0,0.0,sz,0.0,
					   0.0,0.0,0.0,1.0)

	@staticmethod
	def makeTranslate(tx, ty, tz):
		return Matrix4(1.0,0.0,0.0,tx,
					   0.0,1.0,0.0,ty,
					   0.0,0.0,1.0,tz,
					   0.0,0.0,0.0,1.0)

	@staticmethod
	def makePerspective(fovx, fovy, znear, zfar):
		return Matrix4(math.atan(fovx/2.0),0.0,0.0,0.0,
					   0.0,math.atan(fovy/2.0),0.0,0.0,
					   0.0,0.0,-(zfar + znear)/(zfar - znear),-2.0*znear*zfar/(zfar - znear),
					   0.0,0.0,-1.0,0.0)


	def __mul__(self, other):
		if isinstance(other, Matrix4):

			return Matrix4(self.x1 * other.x1 + self.y1 * other.x2 + self.z1 * other.x3 + self.w1 * other.x4,
                           self.x1 * other.y1 + self.y1 * other.y2 + self.z1 * other.y3 + self.w1 * other.y4,
                           self.x1 * other.z1 + self.y1 * other.z2 + self.z1 * other.z3 + self.w1 * other.z4,
                           self.x1 * other.w1 + self.y1 * other.w2 + self.z1 * other.w3 + self.w1 * other.w4,

                           self.x2 * other.x1 + self.y2 * other.x2 + self.z2 * other.x3 + self.w2 * other.x4,
                           self.x2 * other.y1 + self.y2 * other.y2 + self.z2 * other.y3 + self.w2 * other.y4,
                           self.x2 * other.z1 + self.y2 * other.z2 + self.z2 * other.z3 + self.w2 * other.z4,
                           self.x2 * other.w1 + self.y2 * other.w2 + self.z2 * other.w3 + self.w2 * other.w4,

                           self.x3 * other.x1 + self.y3 * other.x2 + self.z3 * other.x3 + self.w3 * other.x4,
                           self.x3 * other.y1 + self.y3 * other.y2 + self.z3 * other.y3 + self.w3 * other.y4,
                           self.x3 * other.z1 + self.y3 * other.z2 + self.z3 * other.z3 + self.w3 * other.z4,
                           self.x3 * other.w1 + self.y3 * other.w2 + self.z3 * other.w3 + self.w3 * other.w4,

                           self.x4 * other.x1 + self.y4 * other.x2 + self.z4 * other.x3 + self.w4 * other.x4,
                           self.x4 * other.y1 + self.y4 * other.y2 + self.z4 * other.y3 + self.w4 * other.y4,
                           self.x4 * other.z1 + self.y4 * other.z2 + self.z4 * other.z3 + self.w4 * other.z4,
                           self.x4 * other.w1 + self.y4 * other.w2 + self.z4 * other.w3 + self.w4 * other.w4
            )


		elif isinstance(other, Point3D):

			return Point3D(self.x1 * other.x + self.y1 * other.y + self.z1 * other.z + self.w1 * other.w,
                           self.x2 * other.x + self.y2 * other.y + self.z2 * other.z + self.w2 * other.w,
                           self.x3 * other.x + self.y3 * other.y + self.z3 * other.z + self.w3 * other.w,
                           self.x4 * other.x + self.y4 * other.y + self.z4 * other.z + self.w4 * other.w)

	def __str__(self):
		return "[%f,%f,%f,%f\n%f,%f,%f,%f\n%f,%f,%f,%f\n%f,%f,%f,%f]\n" % (self.x1, self.y1, self.z1, self.w1,
										   self.x2, self.y2, self.z2, self.w2,
										   self.x3, self.y3, self.z3, self.w3,
										   self.x4, self.y4, self.z4, self.w4);
#====================================== Main stuff ======================

x_rot_plus = False
y_rot_plus = False
z_rot_plus = False
x_rot_minus = False
y_rot_minus = False
z_rot_minus = False

x_trans_plus = False
x_trans_minus = False
y_trans_plus = False
y_trans_minus = False
z_trans_plus = False
z_trans_minus = False

xr = 0.0
yr = 0.0
zr = 0.0

xt = 0.0
yt = 0.0
zt = 5.0

runDemo = True

# Create a torus

frame = 0	

while running:

	if y_rot_plus:
		yr += ANGULAR_SPEED

	if y_rot_minus:
		yr -= ANGULAR_SPEED

	if x_rot_plus:
		xr += ANGULAR_SPEED

	if x_rot_minus:
		xr -= ANGULAR_SPEED

	if runDemo:
		xr = 1.0*math.sin(frame / 10.0)
		yr = 2.0*math.sin(frame / 10.0)
		#zt = 2.5 + 1.0 * math.cos(frame / 10.0)

	N_TORUS_POINTS_PER_RIB = 6
	TORUS_RIB_RADIUS = 10.0
	N_TORUS_RIBS = 6

	rib1_points = []

	rib_point = Point3D(-1.0, 0.0, 0.0, 1.0)
	for i in range(0, N_TORUS_POINTS_PER_RIB):
		p = Matrix4.makeRot(0, 0, math.pi*2.0 / N_TORUS_POINTS_PER_RIB * i) * rib_point
		rib1_points.append(Vertex(p.x, p.y, p.z))

	torus_points = []

	for i in range(0, N_TORUS_RIBS):
		for v in rib1_points:
			p = (Matrix4.makeRot(0, math.pi*2.0 / N_TORUS_RIBS * i, 0) * Matrix4.makeTranslate(-2.0, 0.0, 0.0) ) * v.pos
			torus_points.append(Vertex(p.x, p.y, p.z)) 
	


	rotMat =  Matrix4.makeRot(xr, yr, zr)
	modelWorldView = Matrix4.makePerspective(3.0, 10.0, 0.1, 100.0) * Matrix4.makeTranslate(xt, yt, zt) * rotMat

	for v in torus_points:
		v.transform(modelWorldView)
		v.project()
		putPixel(int(v.screen.x), int(v.screen.y), 255, 1, 1)


	for event in pygame.event.get():
			if event.type == pygame.QUIT:
					running = False
			elif event.type == pygame.KEYDOWN or event.type == pygame.KEYUP:
					keys = pygame.key.get_pressed()

					if keys[pygame.K_LEFT]:
						y_rot_plus = True;
					else:
						y_rot_plus = False;

					if keys[pygame.K_RIGHT]:
						y_rot_minus = True;
					else:
						y_rot_minus = False;

					if keys[pygame.K_UP]:
						x_rot_plus = True;
					else:
						x_rot_plus = False;

					if keys[pygame.K_DOWN]:
						x_rot_minus = True;
					else:
						x_rot_minus = False;

					if keys[pygame.K_SPACE]:
						runDemo = not runDemo



	pygame.display.flip()
	clock.tick(20)

	frame += 1

	screen.fill((0,0,0))




