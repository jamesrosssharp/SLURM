
int afunc(int a, int b, int c, int d, int e)
{
	return a + b + c + d + e;
}

int bfunc(int a, int b, int c, int d, int e)
{
	int f = a + b;
	int g = c - d;
	int h = e * 2;

	return f + g - h;

}


int main(int argc, char** argv)
{
	afunc(1,2,3,4,5);
	bfunc(1,2,3,4,5);
	return 0;
}
