#!/usr/bin/env python
#
#	Python code based on Chris Hecker's article on perspective correct texture mapping
#
# -*- coding: utf-8 -*-

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

	def __init__(self, x, y, z, u, v):
		self.pos = Point3D(x, y, z, 1.0)
		self.tex = Point2D(u, v)
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

#================ Triangle Rasterizer ==========================

class Gradients:

	def __init__(self, vertices):

		self.OneOverdX = 1.0 / (((vertices[1].screen.x - vertices[2].screen.x) * \
								 (vertices[0].screen.y - vertices[2].screen.y))  -
								 ((vertices[0].screen.x - vertices[2].screen.x) * \
								 (vertices[1].screen.y - vertices[2].screen.y)))
		self.OneOverdY = - self.OneOverdX;

		self.aOneOverZ = [0.0, 0.0, 0.0]
		self.aUOverZ = [0.0, 0.0, 0.0]
		self.aVOverZ = [0.0, 0.0, 0.0]

		for i in range (0,3):
			self.OneOverZ = 1.0 / vertices[i].pos.w
			self.aOneOverZ[i] = self.OneOverZ
			self.aUOverZ[i] = vertices[i].tex.x * self.OneOverZ
			self.aVOverZ[i] = vertices[i].tex.y * self.OneOverZ

		self.dOneOverZdX = self.OneOverdX * (((self.aOneOverZ[1] - self.aOneOverZ[2]) * \
								(vertices[0].screen.y - vertices[2].screen.y)) - \
								((self.aOneOverZ[0] - self.aOneOverZ[2]) *
								(vertices[1].screen.y - vertices[2].screen.y)))

		self.dOneOverZdY = self.OneOverdY * (((self.aOneOverZ[1] - self.aOneOverZ[2]) * \
						(vertices[0].screen.x - vertices[2].screen.x)) - \
						((self.aOneOverZ[0] - self.aOneOverZ[2]) *
						(vertices[1].screen.x - vertices[2].screen.x)))

		self.dUOverZdX = self.OneOverdX * (((self.aUOverZ[1] - self.aUOverZ[2]) * \
						(vertices[0].screen.y - vertices[2].screen.y)) - \
						((self.aUOverZ[0] - self.aUOverZ[2]) *
						(vertices[1].screen.y - vertices[2].screen.y)))

		self.dUOverZdY = self.OneOverdY * (((self.aUOverZ[1] - self.aUOverZ[2]) * \
						(vertices[0].screen.x - vertices[2].screen.x)) - \
						((self.aUOverZ[0] - self.aUOverZ[2]) *
						(vertices[1].screen.x - vertices[2].screen.x)))

		self.dVOverZdX = self.OneOverdX * (((self.aVOverZ[1] - self.aVOverZ[2]) * \
						(vertices[0].screen.y - vertices[2].screen.y)) - \
						((self.aVOverZ[0] - self.aVOverZ[2]) *
						(vertices[1].screen.y - vertices[2].screen.y)))

		self.dVOverZdY = self.OneOverdY * (((self.aVOverZ[1] - self.aVOverZ[2]) * \
						(vertices[0].screen.x - vertices[2].screen.x)) - \
						((self.aVOverZ[0] - self.aVOverZ[2]) *
						(vertices[1].screen.x - vertices[2].screen.x)))

		self.dRdX = self.OneOverdX * (((vertices[1].col.x - vertices[2].col.x) * \
						(vertices[0].screen.y - vertices[2].screen.y)) - \
						((vertices[0].col.x - vertices[2].col.x) *
						(vertices[1].screen.y - vertices[2].screen.y)))

		self.dRdY = self.OneOverdY * (((vertices[1].col.x - vertices[2].col.x) * \
						(vertices[0].screen.x - vertices[2].screen.x)) - \
						((vertices[0].col.x - vertices[2].col.x) *
						(vertices[1].screen.x - vertices[2].screen.x)))

		self.dGdX = self.OneOverdX * (((vertices[1].col.y - vertices[2].col.y) * \
						(vertices[0].screen.y - vertices[2].screen.y)) - \
						((vertices[0].col.y - vertices[2].col.y) *
						(vertices[1].screen.y - vertices[2].screen.y)))

		self.dGdY = self.OneOverdY * (((vertices[1].col.y - vertices[2].col.y) * \
						(vertices[0].screen.x - vertices[2].screen.x)) - \
						((vertices[0].col.y - vertices[2].col.y) *
						(vertices[1].screen.x - vertices[2].screen.x)))

		self.dBdX = self.OneOverdX * (((vertices[1].col.z - vertices[2].col.z) * \
						(vertices[0].screen.y - vertices[2].screen.y)) - \
						((vertices[0].col.z - vertices[2].col.z) *
						(vertices[1].screen.y - vertices[2].screen.y)))

		self.dBdY = self.OneOverdY * (((vertices[1].col.z - vertices[2].col.z) * \
						(vertices[0].screen.x - vertices[2].screen.x)) - \
						((vertices[0].col.z - vertices[2].col.z) *
						(vertices[1].screen.x - vertices[2].screen.x)))

class Edge:

	def __init__(self, gradients, vertices, top, bottom):

		self.y = math.ceil(vertices[top].screen.y)
		yend = math.ceil(vertices[bottom].screen.y)

		self.height = yend - self.y
		yprestep = self.y - vertices[top].screen.y
		realHeight = vertices[bottom].screen.y - vertices[top].screen.y

		realWidth =  vertices[bottom].screen.x - vertices[top].screen.x

		if realHeight == 0.0:
			self.xstep = 0
			self.x = math.ceil(vertices[top].screen.x)

		else:
			self.xstep = realWidth / realHeight
			self.x = ((realWidth * yprestep)/realHeight) + vertices[top].screen.x


		xprestep = self.x - vertices[top].screen.x
		self.oneOverZ = gradients.aOneOverZ[top] + yprestep * gradients.dOneOverZdY + \
						xprestep * gradients.dOneOverZdX
		self.oneOverZStep = self.xstep * gradients.dOneOverZdX + gradients.dOneOverZdY

		self.UOverZ = gradients.aUOverZ[top] + yprestep * gradients.dUOverZdY + \
						xprestep * gradients.dUOverZdX
		self.UOverZStep = self.xstep * gradients.dUOverZdX + gradients.dUOverZdY

		self.VOverZ = gradients.aVOverZ[top] + yprestep * gradients.dVOverZdY + \
						xprestep * gradients.dVOverZdX
		self.VOverZStep = self.xstep * gradients.dVOverZdX + gradients.dVOverZdY

		self.R = vertices[top].col.x + yprestep * gradients.dRdY + \
						xprestep * gradients.dRdX
		self.RStep = self.xstep * gradients.dRdX + gradients.dRdY

		self.G = vertices[top].col.y + yprestep * gradients.dGdY + \
						xprestep * gradients.dGdX
		self.GStep = self.xstep * gradients.dGdX + gradients.dGdY

		self.B = vertices[top].col.z + yprestep * gradients.dBdY + \
						xprestep * gradients.dBdX
		self.BStep = self.xstep * gradients.dBdX + gradients.dBdY

	def step(self):

		self.x += self.xstep
		self.y += 1
		self.height -= 1
		self.UOverZ += self.UOverZStep
		self.VOverZ += self.VOverZStep
		self.oneOverZ += self.oneOverZStep
		self.R += self.RStep
		self.G += self.GStep
		self.B += self.BStep
		return self.height

def getTexel(U, V, texture):
	uint = int(math.floor(U * 8))
	vint = int(math.floor(V * 8))

	if texture == 0:
		col = (255.0,0,0)
	elif texture == 1:
		col = (0,255.0,0)
	elif texture == 2:
		col = (255.0,255.0,0)
	elif texture == 3:
		col = (0,0,255.0)
	elif texture == 4:
		col = (255.0,0,255.0)
	elif texture == 5:
		col = (0,255.0,255.0)

	if (((uint % 2) ^ (vint % 2)) == 0):
		return (255.0, 255.0, 255.0)
	else:
		return col

def drawScanLine(left, right, gradients, texture):

	XStart = math.ceil(left.x)
	XPrestep = XStart - left.x

	Width = math.ceil(right.x) - XStart

	OneOverZ = left.oneOverZ + XPrestep * gradients.dOneOverZdX

	UOverZ = left.UOverZ + XPrestep * gradients.dUOverZdX
	VOverZ = left.VOverZ + XPrestep * gradients.dVOverZdX

	# don't bother prestepping lighting - it doesn't need to be that accurate
	R = left.R
	G = left.G
	B = left.B

	while (Width > 0):
		Z = 1.0 / OneOverZ
		U = UOverZ * Z
		V = VOverZ * Z

		(r, g, b) = getTexel(U, V, texture)

		r = r*R
		g = g*G
		b = b*B

		putPixel(int(XStart), int(left.y), r, g, b)
		XStart += 1
		Width -= 1

		OneOverZ += gradients.dOneOverZdX

		UOverZ += gradients.dUOverZdX
		VOverZ += gradients.dVOverZdX

		R += gradients.dRdX
		G += gradients.dGdX
		B += gradients.dBdX


def rasteriseTriangle(vertices, texture):

	Top = 0
	Middle = 1
	Bottom = 2
	MiddleCompare = 0
	BottomCompare = 0

	Y0 = vertices[0].screen.y
	Y1 = vertices[1].screen.y
	Y2 = vertices[2].screen.y

	if (Y0 < Y1):
		if (Y2 < Y0):
			Top = 2
			Middle = 0
			Bottom = 1
			MiddleCompare = 0
			BottomCompare = 1
		else:
			Top = 0
			if (Y1 < Y2):
				Middle = 1
				Bottom = 2
				MiddleCompare = 1
				BottomCompare = 2
			else:
				Middle = 2
				Bottom = 1
				MiddleCompare = 2
				BottomCompare = 1
	else:
		if (Y2 < Y1):
			Top = 2
			Middle = 1
			Bottom = 0
			MiddleCompare = 1
			BottomCompare = 0
		else:
			Top = 1
			if (Y0 < Y2):
				Middle = 0
				Bottom = 2
				MiddleCompare = 3
				BottomCompare = 2
			else:
				Middle = 2
				Bottom = 0
				MiddleCompare = 2
				BottomCompare = 3

	gradients = Gradients(vertices)

	TopToBottom = Edge(gradients, vertices, Top, Bottom)
	TopToMiddle = Edge(gradients, vertices, Top, Middle)
	MiddleToBottom = Edge(gradients, vertices, Middle, Bottom)

	if	(BottomCompare < MiddleCompare):
		MiddleIsLeft = False
		pLeft = TopToBottom
		pRight = TopToMiddle
	else:
		MiddleIsLeft = True
		pLeft = TopToMiddle
		pRight = TopToBottom

	Height = TopToMiddle.height

	while (Height > 0):

		drawScanLine(pLeft, pRight, gradients, texture)
		TopToMiddle.step()
		TopToBottom.step()
		Height -= 1

	Height = MiddleToBottom.height

	if	MiddleIsLeft:
		pLeft = MiddleToBottom
		pRight = TopToBottom
	else:
		pLeft = TopToBottom
		pRight = MiddleToBottom

	while (Height > 0):

		drawScanLine(pLeft, pRight, gradients, texture)
		MiddleToBottom.step()
		TopToBottom.step()
		Height -= 1

#================ Main loop =========================



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
zt = 2.5

ANGULAR_SPEED = 0.05

lightSource = Point3D(0.7, 0.7, -10.0, 1.0)
lightSource = lightSource / lightSource.norm()

runDemo = True
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
		xr = 4.0*math.sin(frame / 10.0)
		yr = 2.0*math.sin(frame / 10.0)
		zt = 2.5 + 1.0 * math.cos(frame / 10.0)


	# make vertices for all six faces of the cube
	# vertices need to be distinct so that texture coordinates will
	# be distinct

	v1 = Vertex(-0.5,-0.5,-0.5,0.0,0.0)
	v2 = Vertex(-0.5, 0.5,-0.5,0.0,1.0)
	v3 = Vertex( 0.5, 0.5,-0.5,1.0,1.0)
	v4 = Vertex( 0.5, -0.5,-0.5,1.0,0.0)

	v5 = Vertex(-0.5,-0.5, 0.5, 1.0,0.0)
	v6 = Vertex(-0.5, 0.5, 0.5, 1.0,1.0)
	v7 = Vertex( 0.5, 0.5, 0.5, 0.0,1.0)
	v8 = Vertex( 0.5,-0.5, 0.5, 0.0,0.0)

	v9  = Vertex(-0.5,-0.5, 0.5, 0.0,0.0)
	v10 = Vertex(-0.5, 0.5, 0.5, 0.0,1.0)
	v11 = Vertex(-0.5, 0.5,-0.5, 1.0,1.0)
	v12 = Vertex(-0.5,-0.5,-0.5, 1.0,0.0)

	v13 = Vertex(0.5,-0.5, 0.5,  1.0,0.0)
	v14 = Vertex(0.5, 0.5, 0.5,  1.0,1.0)
	v15 = Vertex(0.5, 0.5,-0.5,  0.0,1.0)
	v16 = Vertex(0.5,-0.5,-0.5,  0.0,0.0)

	v17 = Vertex(-0.5, 0.5, 0.5, 0.0,0.0)
	v18 = Vertex(0.5,  0.5, 0.5, 0.0,1.0)
	v19 = Vertex(0.5,  0.5,-0.5, 1.0,1.0)
	v20 = Vertex(-0.5, 0.5,-0.5, 1.0,0.0)

	v21 = Vertex(-0.5,-0.5,0.5,  0.0,0.0)
	v22 = Vertex(0.5, -0.5,0.5,  0.0,1.0)
	v23 = Vertex(0.5, -0.5,-0.5, 1.0,1.0)
	v24 = Vertex(-0.5,-0.5,-0.5, 1.0,0.0)

	# calculate the face normals

	fn1 = Point3D.cross(v2.pos - v1.pos,   v3.pos - v1.pos)
	fn2 = Point3D.cross(v8.pos - v7.pos,   v8.pos - v6.pos)
	fn3 = Point3D.cross(v10.pos - v9.pos,  v11.pos - v9.pos)
	fn4 = Point3D.cross(v16.pos - v15.pos, v16.pos - v14.pos)
	fn5 = Point3D.cross(v18.pos - v17.pos, v19.pos - v17.pos)
	fn6 = Point3D.cross(v24.pos - v23.pos, v24.pos - v22.pos)

	# calculate the vertex normals

	# shared vertices: v1 (f1) = v12 (f3) = v24 (f6) => vn1
	#				   v2 (f1) = v11 (f3) = v20 (f5) => vn2
	#				   v3 (f1) = v15 (f4) = v19 (f5) => vn3
	#				   v4 (f1) = v16 (f4) = v23 (f6) => vn4
	#				   v5 (f2) = v9  (f3) = v21 (f6) => vn5
	#				   v6 (f2) = v10 (f3) = v17 (f5) => vn6
	#				   v7 (f2) = v14 (f4) = v18 (f5) => vn7
	#				   v8 (f2) = v13 (f4) = v22 (f6) => vn8

	vn1 = (fn1 + fn3 + fn6) / 3.0
	vn2 = (fn1 + fn3 + fn5) / 3.0
	vn3 = (fn1 + fn4 + fn5) / 3.0
	vn4 = (fn1 + fn4 + fn6) / 3.0
	vn5 = (fn2 + fn3 + fn6) / 3.0
	vn6 = (fn2 + fn3 + fn5) / 3.0
	vn7 = (fn2 + fn4 + fn5) / 3.0
	vn8 = (fn2 + fn4 + fn6) / 3.0

	# make unit normals
	vn1 = vn1 / vn1.norm()
	vn2 = vn2 / vn2.norm()
	vn3 = vn3 / vn3.norm()
	vn4 = vn4 / vn4.norm()
	vn5 = vn5 / vn5.norm()
	vn6 = vn6 / vn6.norm()
	vn7 = vn7 / vn7.norm()
	vn8 = vn8 / vn8.norm()

	rotMat =  Matrix4.makeRot(xr, yr, zr)
	modelWorldView = Matrix4.makePerspective(3.0, 10.0, 0.1, 100.0) * Matrix4.makeTranslate(xt, yt, zt) * rotMat

	for v in [vn1, vn2, vn3, vn4, vn5, vn6, vn7, vn8]:
		# vertex normals don't need to be translated or projected
		v.transform(rotMat)

	v1.setNormal(vn1)
	v2.setNormal(vn2)
	v3.setNormal(vn3)
	v4.setNormal(vn4)
	v5.setNormal(vn5)
	v6.setNormal(vn6)
	v7.setNormal(vn7)
	v8.setNormal(vn8)

	v9.setNormal(vn5)
	v10.setNormal(vn6)
	v11.setNormal(vn2)
	v12.setNormal(vn1)
	v13.setNormal(vn8)
	v14.setNormal(vn7)
	v15.setNormal(vn3)
	v16.setNormal(vn4)

	v17.setNormal(vn6)
	v18.setNormal(vn7)
	v19.setNormal(vn3)
	v20.setNormal(vn2)
	v21.setNormal(vn5)
	v22.setNormal(vn8)
	v23.setNormal(vn4)
	v24.setNormal(vn1)

	for v in [v1, v2, v3, v4, v5, v6, v7, v8, v9, v10, v11, v12, v13, v14, v15, v16,
		  v17, v18, v19, v20, v21, v22, v23, v24]:
		v.transform(modelWorldView)
		v.project()
		v.shade(lightSource)

	rasteriseTriangle([v1, v2, v3], 0)
	rasteriseTriangle([v1, v3, v4], 0)

	rasteriseTriangle([v8, v7, v6], 1)
	rasteriseTriangle([v8, v6, v5], 1)

	rasteriseTriangle([v9, v10, v11], 2)
	rasteriseTriangle([v9, v11, v12], 2)

	rasteriseTriangle([v16, v15, v14], 3)
	rasteriseTriangle([v16, v14, v13], 3)

	rasteriseTriangle([v17, v18, v19], 4)
	rasteriseTriangle([v17, v19, v20], 4)

	rasteriseTriangle([v24, v23, v22], 5)
	rasteriseTriangle([v24, v22, v21], 5)

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





