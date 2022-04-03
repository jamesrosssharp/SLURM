
char* string = "Hello world from C compiled code!\n";

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
