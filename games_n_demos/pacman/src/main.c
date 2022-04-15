
extern void load_copper_list(short* list, int len);

short copperList[] = {
		0x6ff0,
		0x7040,
		0x60ff,
		0x7020,
		0x4100,
		0x1000,
		0x2fff		 
};


int main()
{

	load_copper_list(copperList, sizeof(copperList) / sizeof(copperList[0]));

	putc('!');
	exit();
	return 0;
}
