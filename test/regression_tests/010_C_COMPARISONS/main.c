#if !defined(_VA_LIST) && !defined(__VA_LIST_DEFINED)
#define _VA_LIST
#define _VA_LIST_DEFINED
typedef char *__va_list;
#endif
static float __va_arg_tmp;
typedef __va_list va_list;

#define va_start(list, start) ((void)((list) = (sizeof(start)<4 ? \
	(char *)((int *)&(start)+1) : (char *)(&(start)+1))))
#define __va_arg(list, mode, n) (\
	__typecode(mode)==1 && sizeof(mode)==4 ? \
	  (__va_arg_tmp = *(double *)(&(list += ((sizeof(double)+n)&~n))[-(int)((sizeof(double)+n)&~n)]), \
		*(mode *)&__va_arg_tmp) : \
	  *(mode *)(&(list += ((sizeof(mode)+n)&~n))[-(int)((sizeof(mode)+n)&~n)]))
#define _bigendian_va_arg(list, mode, n) (\
	sizeof(mode)==1 ? *(mode *)(&(list += 4)[-1]) : \
	sizeof(mode)==2 ? *(mode *)(&(list += 4)[-2]) : __va_arg(list, mode, n))
#define _littleendian_va_arg(list, mode, n) __va_arg(list, mode, n)
#define va_end(list) ((void)0)
#define va_arg(list, mode) _littleendian_va_arg(list, mode, 1U)
typedef void *__gnuc_va_list;



extern void trace_char(char c);
extern void trace_dec(short d);
extern void trace_hex(short h);
extern void putc(char c);


void print_hex_num(short num)
{
	trace_hex(num);
}

void print_dec_num(short num)
{
	trace_dec(num);
}


void my_printf(char* format, ...)
{
        va_list arg;
        char c;
        va_start(arg, format);


        while (c = *format++)
        {
                if (c == '%')
                {
                        c = *format++;

                        if (c == '%')
                                trace_char('%');
                        else if (c == 'x') {
                                int a = va_arg(arg, unsigned int);
                                print_hex_num(a);
                        }
                        else if (c == 'd')
                                print_dec_num(va_arg(arg, int));
                        else trace_char('?');
                }
                else
                        trace_char(c);
        }

        va_end(arg);

}


void is_greater_than(int a, int b)
{
	if (a > b)
		my_printf("%d is greater than %d\n", a, b);
	else
		my_printf("%d is not greater than %d\n", a, b);	
}

void is_less_than(int a, int b)
{
	if (a < b)
		my_printf("%d is less than %d\n", a, b);
	else
		my_printf("%d is not less than %d\n", a, b);	
}

void is_greater_than_equal(int a, int b)
{
	if (a >= b)
		my_printf("%d is greater thani or equal to %d\n", a, b);
	else
		my_printf("%d is not greater than or equal to %d\n", a, b);	
}

void is_less_than_equal(int a, int b)
{
	if (a <= b)
		my_printf("%d is less than or equal to %d\n", a, b);
	else
		my_printf("%d is not less than or equal to %d\n", a, b);	
}

void is_greater_than_u(unsigned int a, unsigned int b)
{
	if (a > b)
		my_printf("%x is greater than %x\n", a, b);
	else
		my_printf("%x is not greater than %x \n", a, b);	
}

void is_less_than_u(unsigned int a, unsigned int b)
{
	if (a < b)
		my_printf("%x is less than %x\n", a, b);
	else
		my_printf("%x is not less than %x\n", a, b);	
}

void is_greater_than_equal_u(unsigned int a, unsigned int b)
{
	if (a >= b)
		my_printf("%x is greater or equal to %x\n", a, b);
	else
		my_printf("%x is not greater or equal to %x\n", a, b);	
}

void is_less_than_equal_u(unsigned int a, unsigned int b)
{
	if (a <= b)
		my_printf("%x is less than or equal to %x\n", a, b);
	else
		my_printf("%x is not less than or equal to %x\n", a, b);	
}



int main()
{
	short a = 3;
	short b = 5;
	unsigned int c = 3;
	unsigned int d = 5;

	is_greater_than(a, b);
	is_less_than(a, b);
	is_greater_than_equal(a, b);
	is_less_than_equal(a, b);


	a = 32767;
	b = -32768;

	is_greater_than(a, b);
	is_less_than(a, b);
	is_greater_than_equal(a, b);
	is_less_than_equal(a, b);


	a = 768;
	b = 768;

	is_greater_than(a, b);
	is_less_than(a, b);
	is_greater_than_equal(a, b);
	is_less_than_equal(a, b);

	is_greater_than_u(c, d);
	is_less_than_u(c, d);
	is_greater_than_equal_u(c, d);
	is_less_than_equal_u(c, d);

	c = 65535;
	d = 1;

	is_greater_than_u(c, d);
	is_less_than_u(c, d);
	is_greater_than_equal_u(c, d);
	is_less_than_equal_u(c, d);

	c = 768;
	d = 768;

	is_greater_than_u(c, d);
	is_less_than_u(c, d);
	is_greater_than_equal_u(c, d);
	is_less_than_equal_u(c, d);


	while(1)
			;
}
