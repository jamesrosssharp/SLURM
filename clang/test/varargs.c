#include "common.h"
#include <stdarg.h>

struct S {
  int16_t a;
  char b;
  int32_t c;
};

/* Mixed variadic arguments, including a struct passed by value. */
static int64_t mix(int16_t n, ...) {
  va_list ap;
  va_start(ap, n);
  int64_t s = 0;
  for (int16_t i = 0; i < n; ++i) {
    switch (va_arg(ap, int)) {
    case 0: s = s * 3 + va_arg(ap, int); break;
    case 1: s = s * 5 + va_arg(ap, long); break;
    case 2: s = s * 7 + va_arg(ap, long long); break;
    case 3: {
      struct S st = va_arg(ap, struct S);
      s = s * 11 + st.a + st.b + st.c;
      break;
    }
    case 4: s = s * 13 + (int64_t)(va_arg(ap, double) * 1000); break;
    }
  }
  va_end(ap);
  return s;
}

static int32_t forward(int16_t n, va_list ap) {
  int32_t s = 0;
  while (n--)
    s = s * 2 + va_arg(ap, int);
  return s;
}

static int32_t outer(int16_t n, ...) {
  va_list ap;
  va_start(ap, n);
  int32_t r = forward(n, ap);
  va_end(ap);
  return r;
}

int main(void) {
  struct S st = {-100, 7, 70000};
  PD(mix(0));
  PD(mix(1, 0, -5));
  PD(mix(5, 0, 300, 1, -1000000L, 3, st, 2, 123456789012LL, 4, 2.5));
  PD(outer(4, 1, 2, 3, 4));
  NL();
  return 0;
}
