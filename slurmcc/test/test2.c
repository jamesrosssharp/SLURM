
void print_hex_num(unsigned int n)
{
	static char convertBuffer[] = "0123456789abcdef";
	
	while (n) {
		unsigned int a = (n & 0xf000U) >> 12;
		putc(convertBuffer[a]);

		n <<= 4;
	}
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

	exit();
}
