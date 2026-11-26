#include "common.h"
#include <stdarg.h>

struct point {
  int16_t x, y;
};
struct big {
  int32_t a;
  int16_t b[5];
  char c;
};

static int16_t fib(int16_t n) { return n < 2 ? n : fib(n - 1) + fib(n - 2); }

static int32_t sum(int16_t n, ...) {
  va_list ap;
  va_start(ap, n);
  int32_t s = 0;
  for (int16_t i = 0; i < n; ++i)
    s += va_arg(ap, int32_t);
  va_end(ap);
  return s;
}

static struct point add_points(struct point a, struct point b) {
  struct point r = {(int16_t)(a.x + b.x), (int16_t)(a.y + b.y)};
  return r;
}

static struct big make_big(int16_t k) {
  struct big r;
  r.a = (int32_t)k * 100000;
  for (int i = 0; i < 5; ++i)
    r.b[i] = k * i;
  r.c = (char)k;
  return r;
}

static int32_t big_sum(struct big b) {
  int32_t s = b.a + b.c;
  for (int i = 0; i < 5; ++i)
    s += b.b[i];
  return s;
}

static int16_t classify(int16_t v) {
  switch (v) {
  case 0: return 10;
  case 1: return 21;
  case 2: return 32;
  case 3: return 43;
  case 4: return 54;
  case 5: return 65;
  case 7: return 87;
  case 9: return 99;
  case 100: return -1;
  default: return -2;
  }
}

static int16_t twice(int16_t x) { return 2 * x; }
static int16_t square(int16_t x) { return x * x; }
static int16_t (*const ops[])(int16_t) = {twice, square, fib};

static int16_t many_args(int16_t a, int16_t b, int16_t c, int16_t d,
                         int16_t e, int32_t f, int16_t g, int64_t h) {
  return a + 2 * b + 3 * c + 4 * d + 5 * e + (int16_t)(f >> 8) + 7 * g +
         (int16_t)(h >> 40);
}

int16_t counter(void) {
  static int16_t n = 5;
  return n++;
}

char text[] = "Hello, SLURM16!";
const char *msgs[] = {"zero", "one", "two"};
int16_t matrix[4][4];

int main(void) {
  for (int16_t i = 0; i < 15; ++i)
    PD(fib(i));
  NL();
  PD(sum(3, (int32_t)1, (int32_t)100000, (int32_t)-7));
  PD(sum(0));
  NL();
  struct point p = add_points((struct point){1, 2}, (struct point){30, 40});
  PD(p.x); PD(p.y); NL();
  for (int16_t k = -3; k < 4; ++k)
    PD(big_sum(make_big(k)));
  NL();
  for (int16_t v = -2; v < 12; ++v)
    PD(classify(v));
  PD(classify(100));
  NL();
  for (int i = 0; i < 3; ++i)
    PD(ops[i](7));
  NL();
  PD(many_args(1, 2, 3, 4, 5, 0x12345, 7, 0x0000123456789abcLL));
  NL();
  PD(counter()); PD(counter()); PD(counter()); NL();
  out_str(text); NL();
  for (int i = 0; i < 3; ++i) {
    out_str(msgs[i]); putchar(' ');
  }
  NL();
  for (int i = 0; i < 4; ++i)
    for (int j = 0; j < 4; ++j)
      matrix[i][j] = (int16_t)(i * 10 + j);
  int32_t tr = 0;
  for (int i = 0; i < 4; ++i)
    for (int j = 0; j < 4; ++j)
      tr += matrix[i][j] * matrix[j][i];
  PD(tr); NL();
  int16_t i = 0, acc = 0;
  do {
    acc += i;
    if (i == 6)
      continue;
    acc ^= i << 2;
  } while (++i < 20);
  PD(acc); NL();
  return 0;
}
