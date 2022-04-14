
struct TestStruct {
	int a;
	int b;
	char c;
	char d;
};

struct TestStruct fillStruct(struct TestStruct struc)
{
	struc.a = 4;
	struc.b = 5;
	struc.c = 'A';
	struc.d = 'B';

	return struc;
}

int main(int argc, char** argv)
{
	struct TestStruct struc;

	struc = fillStruct(struc);

	trace_dec(struc.a);
	trace_dec(struc.b);
	trace_char(struc.c);
	trace_char(struc.d);

	return 0;
}
