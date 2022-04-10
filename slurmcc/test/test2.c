
void print_hex_num(unsigned int n)
{
	static char convertBuffer[] = "0123456789abcdef";
	
	while (n) {
		unsigned int a = (n & 0xf000U) >> 12;
		putc(convertBuffer[a]);

		n <<= 4;
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

	lz = clz(b) - 1;

	for (i = 0; i < lz; i++)
		b <<= 1;

	while (lz)
	{
		if (a >= b)
		{
			a -= b;
			*quotient |= 1;
		}

		b >>= 1;
		*quotient <<= 1;
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
		return -quotient;
	
	return quotient;
}

int main()
{
	int a = 3;

	print_hex_num(a);
	putc('\n');

	a += 7;

	print_hex_num(a);
	putc('\n');

	a *= 2;

	print_hex_num(a);
	putc('\n');

	a *= 13;

	print_hex_num(a);
	putc('\n');

	a /= 5;

	print_hex_num(a);
	putc('\n');

	exit();
}
