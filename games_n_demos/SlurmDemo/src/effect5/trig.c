/*

	SlurmDemo : A demo to show off SlURM16

trig.c : trigonometric routines

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

#include "trig.h"

extern short sin_table_8_8[512];
extern short tan_table_8_8[256];
extern short cot_table_8_8[256];

short sin(unsigned short ang)
{
	return sin_table_8_8[ang & 0x1ff];
}

short cos(unsigned short ang)
{
	return sin_table_8_8[(ang + 128) & 0x1ff];
}

short tan_lo(unsigned short ang)
{
	return tan_table_8_8[(ang & 0xff) << 2];
}

short cot(unsigned short ang)
{
	return cot_table_8_8[ang & 0xff];
}
