#include "common.h"

static volatile int16_t s16v[] = {0, 1, -1, 2, -2, 3, 7, -7, 100, -100, 255,
                                  256, 1000, -1000, 12345, -12345, 32767,
                                  -32768};
static volatile int32_t s32v[] = {0, 1, -1, 3, -3, 65535, 65536, -65536,
                                  123456789, -123456789, 0x7fffffff,
                                  (int32_t)0x80000000, 1000000, 7};
static volatile int64_t s64v[] = {0, 1, -1, 5, -5, 0x123456789abcdefLL,
                                  -0x123456789abcdefLL, 4294967296LL, 10};

#define N(a) (int)(sizeof(a) / sizeof(a[0]))

int main(void) {
  for (int i = 0; i < N(s16v); ++i)
    for (int j = 0; j < N(s16v); ++j) {
      int16_t a = s16v[i], b = s16v[j];
      uint16_t ua = a, ub = b;
      P16(a + b); P16(a - b); P16(a * b); P16(a & b); P16(a | b); P16(a ^ b);
      if (b != 0 && !(a == -32768 && b == -1)) {
        P16(a / b); P16(a % b);
      }
      if (ub != 0) {
        P16(ua / ub); P16(ua % ub);
      }
      P16((uint16_t)((uint32_t)ua * ub >> 16));
      P16((int16_t)((int32_t)a * b >> 16));
      putchar('0' + (a < b)); putchar('0' + (a <= b)); putchar('0' + (a > b));
      putchar('0' + (a >= b)); putchar('0' + (a == b)); putchar('0' + (a != b));
      putchar('0' + (ua < ub)); putchar('0' + (ua <= ub));
      putchar('0' + (ua > ub)); putchar('0' + (ua >= ub));
      putchar(' ');
      P16(a < b ? a : b); P16(ua > ub ? ua : ub);
      NL();
    }
  for (int i = 0; i < N(s16v); ++i) {
    int16_t a = s16v[i];
    uint16_t ua = a;
    for (int s = 0; s < 16; ++s) {
      P16(a << s); P16(a >> s); P16(ua >> s);
    }
    NL();
    P16(-a); P16(~a); P16((int8_t)a); P16((uint8_t)a); P16(a << 3);
    P16(a >> 7); P16(ua >> 11); P16((uint16_t)(ua << 4 | ua >> 12));
    P16((uint16_t)(ua << 8 | ua >> 8)); P16((uint16_t)(ua << 1 | ua >> 15));
    NL();
  }
  for (int i = 0; i < N(s32v); ++i)
    for (int j = 0; j < N(s32v); ++j) {
      int32_t a = s32v[i], b = s32v[j];
      uint32_t ua = a, ub = b;
      P32(a + b); P32(a - b); P32(ua * ub); P32(a & b); P32(a | b);
      P32(a ^ b);
      if (b != 0 && !(a == (int32_t)0x80000000 && b == -1)) {
        P32(a / b); P32(a % b);
      }
      if (ub != 0) {
        P32(ua / ub); P32(ua % ub);
      }
      putchar('0' + (a < b)); putchar('0' + (a <= b)); putchar('0' + (a > b));
      putchar('0' + (a >= b)); putchar('0' + (a == b));
      putchar('0' + (ua < ub)); putchar('0' + (ua > ub));
      putchar(' ');
      NL();
    }
  for (int i = 0; i < N(s32v); ++i) {
    int32_t a = s32v[i];
    uint32_t ua = a;
    for (int s = 0; s < 32; s += 3) {
      P32(a << s); P32(a >> s); P32(ua >> s);
    }
    P32(a << 1); P32(a >> 1); P32(ua >> 1); P32(a << 16); P32(a >> 16);
    P32(ua >> 16); P32(a << 8); P32(a >> 24); P32(-a); P32(~a);
    P32((int16_t)a); P32((uint16_t)a); P32((int8_t)a);
    NL();
  }
  for (int i = 0; i < N(s64v); ++i)
    for (int j = 0; j < N(s64v); ++j) {
      int64_t a = s64v[i], b = s64v[j];
      uint64_t ua = a, ub = b;
      P64(a + b); P64(a - b); P64(ua * ub); P64(a ^ b);
      if (b != 0) {
        P64(a / b); P64(a % b); P64(ua / ub); P64(ua % ub);
      }
      putchar('0' + (a < b)); putchar('0' + (ua < ub)); putchar('0' + (a == b));
      for (int s = 0; s < 64; s += 13) {
        P64(a << s); P64(a >> s); P64(ua >> s);
      }
      NL();
    }
  return 0;
}
