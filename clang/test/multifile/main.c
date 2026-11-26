#include <stdio.h>

int add = 5;            /* clashes with the "add" opcode */
int r1(int x);          /* clashes with a register name */
int beefh = 0x1234;     /* would lex as a hex literal */
static int helper(int x) { return x * 3; }
int other(int);
int main(void) {
  int s = 0;
  for (int i = 0; i < 10; ++i)
    s += helper(i) + (i & 1 ? other(i) : 0);
  putchar(42);
  printf(" s=%d add=%d r1=%d beefh=%x in=%u\n", s, add, r1(4), beefh, 1u);
  return 0;
}
