#include "common.h"
#include <string.h>

struct __attribute__((packed)) packed {
  char c;
  int16_t s;
  int32_t l;
};

struct bits {
  unsigned a : 3;
  unsigned b : 5;
  signed c : 4;
  unsigned d : 4;
};

volatile signed char sc[] = {-128, -1, 0, 1, 127};
volatile unsigned char uc[] = {0, 1, 127, 128, 255};

int main(void) {
  for (int i = 0; i < 5; ++i) {
    PD(sc[i]); PD(uc[i]); P16(sc[i]); P16(uc[i]); P16(sc[i] + uc[i]);
    P16((int16_t)(sc[i] * 3)); PD(uc[i] >> 1); PD(sc[i] >> 1);
  }
  NL();
  static struct packed pk[3];
  for (int i = 0; i < 3; ++i) {
    pk[i].c = (char)(i + 'a');
    pk[i].s = (int16_t)(0x1234 + i);
    pk[i].l = 0x11223344 + i;
  }
  for (int i = 0; i < 3; ++i) {
    P8(pk[i].c); P16(pk[i].s); P32(pk[i].l);
  }
  const unsigned char *raw = (const unsigned char *)pk;
  for (unsigned i = 0; i < sizeof(pk); ++i)
    P8(raw[i]);
  NL();
  struct bits b = {5, 17, -3, 9};
  PD(b.a); PD(b.b); PD(b.c); PD(b.d);
  b.c = 7; b.a = 2; b.b += 10;
  PD(b.a); PD(b.b); PD(b.c); PD(b.d);
  NL();
  char buf[32];
  memset(buf, 'x', sizeof(buf));
  memcpy(buf + 3, "abcdefgh", 8);
  memmove(buf + 5, buf + 3, 8);
  buf[20] = 0;
  out_str(buf); NL();
  PD(strlen(buf)); PD(memcmp("abc", "abd", 3) < 0); PD(strcmp("b", "a") > 0);
  NL();
  int16_t arr[10];
  for (int i = 0; i < 10; ++i)
    arr[i] = (int16_t)(i * i - 20);
  int16_t *p = arr, *q = arr + 9;
  PD(q - p); PD(*q); PD(p[3]);
  NL();
  return 0;
}
