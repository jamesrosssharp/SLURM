#include "common.h"

static uint32_t fbits(float f) {
  union {
    float f;
    uint32_t u;
  } x;
  x.f = f;
  return x.u;
}
static uint64_t dbits(double d) {
  union {
    double d;
    uint64_t u;
  } x;
  x.d = d;
  return x.u;
}

volatile float fv[] = {0.0f, 1.0f, -1.5f, 3.14159f, 1e10f, -2.5e-8f, 65536.0f,
                       0.1f};
volatile double dv[] = {0.0, 1.0, -1.5, 3.141592653589793, 1e100, -2.5e-80,
                        65536.0, 0.1};

int main(void) {
  for (int i = 0; i < 8; ++i)
    for (int j = 0; j < 8; ++j) {
      float a = fv[i], b = fv[j];
      P32(fbits(a + b)); P32(fbits(a - b)); P32(fbits(a * b));
      if (b != 0.0f)
        P32(fbits(a / b));
      putchar('0' + (a < b)); putchar('0' + (a == b)); putchar('0' + (a >= b));
      putchar(' ');
      double c = dv[i], d = dv[j];
      P64(dbits(c + d)); P64(dbits(c * d));
      if (d != 0.0)
        P64(dbits(c / d));
      putchar('0' + (c < d)); putchar('0' + (c != d));
      NL();
    }
  for (int i = 0; i < 8; ++i) {
    float a = fv[i];
    double c = dv[i];
    if (a < 2e9f && a > -2e9f) {
      P32((int32_t)a); P16((int16_t)(a / 1000.0f));
    }
    P64(dbits((double)a)); P32(fbits((float)c));
    if (c < 2e9 && c > -2e9)
      P32((int32_t)c);
    NL();
  }
  volatile int32_t iv[] = {0, 1, -1, 123456, -98765, 0x7fffffff};
  for (int i = 0; i < 6; ++i) {
    P32(fbits((float)iv[i])); P64(dbits((double)iv[i]));
    P32(fbits((float)(uint32_t)iv[i]));
  }
  NL();
  float acc = 0;
  for (int i = 1; i <= 100; ++i)
    acc += 1.0f / (float)i;
  P32(fbits(acc));
  double dacc = 1;
  for (int i = 0; i < 20; ++i)
    dacc = dacc * 1.5 + 0.25;
  P64(dbits(dacc));
  NL();
  return 0;
}
