# 0 "main.c"
# 0 "<built-in>"
# 0 "<command-line>"
# 1 "/usr/include/stdc-predef.h" 1 3 4
# 0 "<command-line>" 2
# 1 "main.c"



typedef char *__va_list;

static float __va_arg_tmp;
typedef __va_list va_list;
# 22 "main.c"
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
        ((void)((arg) = (sizeof(format)<4 ? (char *)((int *)&(format)+1) : (char *)(&(format)+1))));


        while (c = *format++)
        {
                if (c == '%')
                {
                        c = *format++;

                        if (c == '%')
                                trace_char('%');
                        else if (c == 'x') {
                                int a = ( __typecode(unsigned int)==1 && sizeof(unsigned int)==4 ? (__va_arg_tmp = *(double *)(&(arg += ((sizeof(double)+1U)&~1U))[-(int)((sizeof(double)+1U)&~1U)]), *(unsigned int *)&__va_arg_tmp) : *(unsigned int *)(&(arg += ((sizeof(unsigned int)+1U)&~1U))[-(int)((sizeof(unsigned int)+1U)&~1U)]));
                                print_hex_num(a);
                        }
                        else if (c == 'd')
                                print_dec_num(( __typecode(int)==1 && sizeof(int)==4 ? (__va_arg_tmp = *(double *)(&(arg += ((sizeof(double)+1U)&~1U))[-(int)((sizeof(double)+1U)&~1U)]), *(int *)&__va_arg_tmp) : *(int *)(&(arg += ((sizeof(int)+1U)&~1U))[-(int)((sizeof(int)+1U)&~1U)])));
                        else trace_char('?');
                }
                else
                        trace_char(c);
        }

        ((void)0);

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
