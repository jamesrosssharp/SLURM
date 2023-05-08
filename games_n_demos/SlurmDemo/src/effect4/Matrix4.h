/*

	SlurmDemo : A demo to show off SlURM16

Matrix4.h : matrix structure

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

#ifndef MATRIX4_H
#define MATRIX4_H

/* 
 *	4x4 matrix
 *
 */

struct Matrix4 {
	short x1, y1, z1, w1;
	short x2, y2, z2, w2;
	short x3, y3, z3, w3;
	short x4, y4, z4, w4;
};

/* fill in Matrix4 with a x-axis rotation matrix from given angle */
void matrix4_createRotX(struct Matrix4* mat, char xang);

/* fill in Matrix4 with a y-axis rotation matrix from given angle */
void matrix4_createRotY(struct Matrix4* mat, char yang);

/* fill in Matrix4 with a z-axis rotation matrix from given angle */
void matrix4_createRotZ(struct Matrix4* mat, char zang);

/* fill in Matrix4 with a rotation matrix from given angles */
void matrix4_createRot(struct Matrix4* mat, char xang, char yang, char zang);

/* fill in a Matrix4 with translation matrix from given 8:8 fixed point translations */
void matrix4_createTrans(struct Matrix4* mat, short xt, short yt, short zt);

/* fill in a Matrix4 with perspective projection matrix from given parameters in 8:8 fixed point */
void matrix4_createPerspective(struct Matrix4* mat, short atan_fovx, short atan_fovy, short znear, short zfar);

/* premultiply Matrix4 B by Matrix4 A storing result in A */
void matrix4_multiply(struct Matrix4* matA, struct Matrix4* matB);


#endif
