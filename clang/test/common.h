/* Shared helpers so the same test prints identically on the host and on
   SLURM16 (where int is 16 bits). */
#ifndef TEST_COMMON_H
#define TEST_COMMON_H
#include <stdint.h>
#ifdef __cplusplus
extern "C" {
#endif
int putchar(int c);
#ifdef __cplusplus
}
#endif

static void out_str(const char *s) {
  while (*s)
    putchar(*s++);
}

static void out_hex(uint64_t v, int digits) {
  for (int i = digits - 1; i >= 0; --i)
    putchar("0123456789abcdef"[(v >> (i * 4)) & 15]);
}

static void out_dec(int64_t v) {
  char buf[24];
  int n = 0;
  uint64_t u = v < 0 ? -(uint64_t)v : (uint64_t)v;
  do {
    buf[n++] = '0' + (char)(u % 10);
    u /= 10;
  } while (u);
  if (v < 0)
    putchar('-');
  while (n)
    putchar(buf[--n]);
}

#define P8(x) (out_hex((uint8_t)(x), 2), putchar(' '))
#define P16(x) (out_hex((uint16_t)(x), 4), putchar(' '))
#define P32(x) (out_hex((uint32_t)(x), 8), putchar(' '))
#define P64(x) (out_hex((uint64_t)(x), 16), putchar(' '))
#define PD(x) (out_dec((int64_t)(x)), putchar(' '))
#define NL() putchar('\n')
#define LABEL(s) (out_str(s), out_str(": "))

#endif
