/*

	SlurmDemo : A demo to show off SlURM16

Matrix4.c : matrix routines

License: MIT License

Copyright 2023 J.R.Sharp

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

#include <Matrix4.h>

extern short sin_table_8_8[256];
extern short dot4_8_8(short* a, short* b, short ainc, short binc);


short sin(char ang)
{
	return sin_table_8_8[ang];
}

short cos(char ang)
{
	return sin_table_8_8[(ang + 64) & 0xff]; 
}

void matrix4_createRotX(struct Matrix4* mat, char xang)
{
	mat->x1 = 0x0100;
	mat->y1 = 0; 
	mat->z1 = 0;
	mat->w1 = 0;
	
	mat->x2 = 0;
	mat->y2 = cos(xang);
	mat->z2 = -sin(xang);
	mat->w2 = 0;

	mat->x3 = 0;
	mat->y3 = sin(xang);
	mat->z3 = cos(xang);
	mat->w3 = 0;

	mat->x4 = 0;
	mat->y4 = 0;
	mat->z4 = 0;
	mat->w4 = 0x0100;

}

void matrix4_createRotY(struct Matrix4* mat, char yang)
{
	mat->x1 = cos(yang);
	mat->y1 = 0; 
	mat->z1 = sin(yang);
	mat->w1 = 0;
	
	mat->x2 = 0;
	mat->y2 = 0x0100;
	mat->z2 = 0;
	mat->w2 = 0;

	mat->x3 = -sin(yang);
	mat->y3 = 0;
	mat->z3 = cos(yang);
	mat->w3 = 0;

	mat->x4 = 0;
	mat->y4 = 0;
	mat->z4 = 0;
	mat->w4 = 0x0100;

}

void matrix4_createRotZ(struct Matrix4* mat, char zang)
{
	mat->x1 = cos(zang);
	mat->y1 = -sin(zang); 
	mat->z1 = 0;
	mat->w1 = 0;
	
	mat->x2 = sin(zang);
	mat->y2 = cos(zang);
	mat->z2 = 0;
	mat->w2 = 0;

	mat->x3 = 0;
	mat->y3 = 0;
	mat->z3 = 0x0100;
	mat->w3 = 0;

	mat->x4 = 0;
	mat->y4 = 0;
	mat->z4 = 0;
	mat->w4 = 0x0100;

}

void matrix4_multiply(struct Matrix4* matA, struct Matrix4* matB)
{
	short x1 = dot4_8_8(&matA->x1, &matB->x1, 2, 8);
	short y1 = dot4_8_8(&matA->x1, &matB->y1, 2, 8);
	short z1 = dot4_8_8(&matA->x1, &matB->z1, 2, 8);
	short w1 = dot4_8_8(&matA->x1, &matB->w1, 2, 8);
 
	short x2 = dot4_8_8(&matA->x2, &matB->x1, 2, 8);
	short y2 = dot4_8_8(&matA->x2, &matB->y1, 2, 8);
	short z2 = dot4_8_8(&matA->x2, &matB->z1, 2, 8);
	short w2 = dot4_8_8(&matA->x2, &matB->w1, 2, 8);
 
	short x3 = dot4_8_8(&matA->x3, &matB->x1, 2, 8);
	short y3 = dot4_8_8(&matA->x3, &matB->y1, 2, 8);
	short z3 = dot4_8_8(&matA->x3, &matB->z1, 2, 8);
	short w3 = dot4_8_8(&matA->x3, &matB->w1, 2, 8);
 
	short x4 = dot4_8_8(&matA->x4, &matB->x1, 2, 8);
	short y4 = dot4_8_8(&matA->x4, &matB->y1, 2, 8);
	short z4 = dot4_8_8(&matA->x4, &matB->z1, 2, 8);
	short w4 = dot4_8_8(&matA->x4, &matB->w1, 2, 8);
 
	matA->x1 = x1;
	matA->y1 = y1;
	matA->z1 = z1;
	matA->w1 = w1;

	matA->x2 = x2;
	matA->y2 = y2;
	matA->z2 = z2;
	matA->w2 = w2;

	matA->x3 = x3;
	matA->y3 = y3;
	matA->z3 = z3;
	matA->w3 = w3;

	matA->x4 = x4;
	matA->y4 = y4;
	matA->z4 = z4;
	matA->w4 = w4;
}

void matrix4_createRot(struct Matrix4* mat, char xang, char yang, char zang)
{
	struct Matrix4 y;
	struct Matrix4 z;

	matrix4_createRotX(mat, xang);
	matrix4_createRotY(&y, yang);
	matrix4_createRotZ(&z, zang);

	matrix4_multiply(mat, &y);
	matrix4_multiply(mat, &z);

}


void matrix4_createTrans(struct Matrix4* mat, short xt, short yt, short zt)
{

	mat->x1 = 0x0100;
	mat->y1 = 0; 
	mat->z1 = 0;
	mat->w1 = xt;
	
	mat->x2 = 0;
	mat->y2 = 0x0100;
	mat->z2 = 0;
	mat->w2 = yt;

	mat->x3 = 0;
	mat->y3 = 0;
	mat->z3 = 0x0100;
	mat->w3 = zt;

	mat->x4 = 0;
	mat->y4 = 0;
	mat->z4 = 0;
	mat->w4 = 0x0100;

}

void matrix4_createPerspective(struct Matrix4* mat, short atan_fovx, short atan_fovy, short znear, short zfar)
{

	mat->x1 = atan_fovx;
	mat->y1 = 0; 
	mat->z1 = 0;
	mat->w1 = 0;
	
	mat->x2 = 0;
	mat->y2 = atan_fovy;
	mat->z2 = 0;
	mat->w2 = 0;

	mat->x3 = 0;
	mat->y3 = 0;
	mat->z3 = 0; //-(zfar + znear)/(zfar - znear);
	mat->w3 = 0; //-2.0*znear*zfar/(zfar - znear);

	mat->x4 = 0;
	mat->y4 = 0;
	mat->z4 = 0xff00;
	mat->w4 = 0;
}

