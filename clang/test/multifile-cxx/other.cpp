#include "shape.h"
int16_t other() {
  Sq q(3);
  Shape *p = &q;
  return p->area() + twice<int16_t>(1) + counter() * 100;
}
