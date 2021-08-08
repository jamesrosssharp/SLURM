
#include <stdio.h>

int main(int argc, char** argv)
{

	int a = 5;
	int b = 3;
	int result = 0;

	while (a)
	{
		printf("a = %d, b = %d\n", a, b);
		if ((a & 0x1)) result += b;
		a >>= 1;
		b <<= 1;
	}

	printf("Result = %d\n", result);

}
