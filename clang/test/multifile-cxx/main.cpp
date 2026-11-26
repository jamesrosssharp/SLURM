#include "shape.h"
#include <stdio.h>
int16_t other();
int main() {
  Sq q(5);
  Shape *p = &q;
  int16_t a = p->area();
  int16_t b = twice<int16_t>(21);
  int16_t c = counter();
  int16_t d = other();
  int16_t e = counter();
  printf("%d %d %d %d %d\n", a, b, c, d, e);
  return 0;
}
