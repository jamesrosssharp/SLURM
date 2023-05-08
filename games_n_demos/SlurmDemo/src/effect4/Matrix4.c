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

