
char* str = "Hello world!\n";

void puts(char* str)
{
	char c;
	while(c = *str++)
		putc(c);
}

int main()
{
	puts(str);

	while(1)
			;
}
