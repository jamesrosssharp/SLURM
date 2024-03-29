/*

printf.c: Very basic (and crap) printf implementation

License: MIT License

Copyright 2023 J.R.Sharp

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/




#if !defined(_VA_LIST) && !defined(__VA_LIST_DEFINED)
#define _VA_LIST
#define _VA_LIST_DEFINED
typedef char *__va_list;
#endif
static float __va_arg_tmp;
typedef __va_list va_list;

#define va_start(list, start) ((void)((list) = (sizeof(start)<4 ? \
	(char *)((int *)&(start)+1) : (char *)(&(start)+1))))
#define __va_arg(list, mode, n) (\
	__typecode(mode)==1 && sizeof(mode)==4 ? \
	  (__va_arg_tmp = *(double *)(&(list += ((sizeof(double)+n)&~n))[-(int)((sizeof(double)+n)&~n)]), \
		*(mode *)&__va_arg_tmp) : \
	  *(mode *)(&(list += ((sizeof(mode)+n)&~n))[-(int)((sizeof(mode)+n)&~n)]))
#define _bigendian_va_arg(list, mode, n) (\
	sizeof(mode)==1 ? *(mode *)(&(list += 4)[-1]) : \
	sizeof(mode)==2 ? *(mode *)(&(list += 4)[-2]) : __va_arg(list, mode, n))
#define _littleendian_va_arg(list, mode, n) __va_arg(list, mode, n)
#define va_end(list) ((void)0)
#define va_arg(list, mode) _littleendian_va_arg(list, mode, 1U)
typedef void *__gnuc_va_list;


void divmodu(unsigned int a, unsigned int b, unsigned int* quotient, unsigned int* rem);

void print_hex_num(unsigned short n)
{
	static char convertBuffer[] = "0123456789abcdef";

	short i = 0;

	while (i < 4) {
		unsigned short a = (n & 0xf000U) >> 12;
		putc(convertBuffer[a]);

		n <<= 4;
		i++;
	}
}

void print_dec_num(int n)
{
	int div;
	int nlz;
	int a;
	static char convertBuffer[] = "0123456789";
	
	if (n < 0) 
	{
		putc('-');
		n = -n;
	}

	if (n == 0)
	{
		putc('0');
		return;
	}

	div = 10000;
	nlz = 0;

	while (div)
	{
		a = n / div;

		if (a != 0 || nlz)
		{
			nlz = 1;
			putc(convertBuffer[a]);
		}
		n %= div;
		div /= 10;

	}

}

unsigned int clz(unsigned int num)
{
	unsigned int n = 0x8000;
	unsigned int lz = 0;

	while (n)
	{
		if (num & n) return lz;
		n >>= 1;
		lz ++;
	}
	return lz;
}

void divmodu(unsigned int a, unsigned int b, unsigned int* quotient, unsigned int* rem)
{
	int lz;
	int i;

	*quotient = 0;
	*rem = 0;

	lz = clz(b);

	for (i = 0; i < lz - 1; i++)
		b <<= 1;

	while (lz)
	{
		*quotient <<= 1;

		if (a >= b)
		{
			a -= b;
			*quotient |= 1;
		}

		b >>= 1;
		lz --;
	}
	*rem = a;
}


int _divi2(int a, int b)
{
	unsigned int quotient;
	unsigned int rem;

	/* Signed integer divide a by b */
	int sign = 1;
	if (a < 0 && b >= 0)
	{
		sign = -1;
		a = -a;
	}

	if (b < 0 && a >= 0)
	{
		sign = -1;
		b = -b;
	}

	if (b < 0 && a < 0)
	{
		a = -a;
		b = -b;
	}

	divmodu(a, b, &quotient, &rem);

	if (sign < 0)
		return -((int)quotient);
	
	return quotient;
}

int _modi2(int a, int b)
{
	unsigned int quotient;
	unsigned int rem;

	/* Signed integer divide a by b */
	int sign = 1;
	if (a < 0 && b >= 0)
	{
		sign = -1;
		a = -a;
	}

	if (b < 0 && a >= 0)
	{
		sign = -1;
		b = -b;
	}

	if (b < 0 && a < 0)
	{
		a = -a;
		b = -b;
	}

	divmodu(a, b, &quotient, &rem);

	return rem;
}

void my_printf(char* format, ...)
{
	va_list arg;
	char c;
	va_start(arg, format);


	while (c = *format++)
	{
		if (c == '%')
		{
			c = *format++;

			if (c == '%')
				putc('%');
			else if (c == 'x') {
				int a = va_arg(arg, unsigned int);
				print_hex_num(a);
			}
			else if (c == 'd')
				print_dec_num(va_arg(arg, int));
			else if (c == 'c')
				putc(va_arg(arg, char));
			else putc('?');
		}
		else
			putc(c);
	}

	va_end(arg);

}


