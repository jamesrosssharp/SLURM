
char* string = "Hello world!";

extern void putc(char c);

void main()
{
	char* c = string;
	while (*c)
	{
		putc(*c++);
	}

	exit();

}
