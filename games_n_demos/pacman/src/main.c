
extern void load_copper_list(short* list, int len);

short copperList[] = {
		0x6f00,
		0x7010,
		0x60f0,
		0x7010,
		0x600f,
		0x7010,
		0x6fff,
		0x7010,
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
