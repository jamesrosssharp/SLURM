/* string.c - memory and string functions for the SLURM16 runtime. */
#include <string.h>

void *memcpy(void *dst, const void *src, size_t n) {
  unsigned char *d = dst;
  const unsigned char *s = src;
  /* Word copy when both pointers are aligned. */
  if ((((unsigned)d | (unsigned)s) & 1) == 0) {
    unsigned short *dw = (unsigned short *)d;
    const unsigned short *sw = (const unsigned short *)s;
    for (; n >= 2; n -= 2)
      *dw++ = *sw++;
    d = (unsigned char *)dw;
    s = (const unsigned char *)sw;
  }
  while (n--)
    *d++ = *s++;
  return dst;
}

void *memmove(void *dst, const void *src, size_t n) {
  unsigned char *d = dst;
  const unsigned char *s = src;
  if (d == s || n == 0)
    return dst;
  if (d < s || d >= s + n)
    return memcpy(dst, src, n);
  d += n;
  s += n;
  while (n--)
    *--d = *--s;
  return dst;
}

void *memset(void *dst, int c, size_t n) {
  unsigned char *d = dst;
  unsigned char v = (unsigned char)c;
  if (((unsigned)d & 1) == 0) {
    unsigned short w = v | (v << 8);
    unsigned short *dw = (unsigned short *)d;
    for (; n >= 2; n -= 2)
      *dw++ = w;
    d = (unsigned char *)dw;
  }
  while (n--)
    *d++ = v;
  return dst;
}

int memcmp(const void *a, const void *b, size_t n) {
  const unsigned char *x = a, *y = b;
  for (; n; --n, ++x, ++y)
    if (*x != *y)
      return *x < *y ? -1 : 1;
  return 0;
}

size_t strlen(const char *s) {
  const char *p = s;
  while (*p)
    ++p;
  return p - s;
}

int strcmp(const char *a, const char *b) {
  while (*a && *a == *b)
    ++a, ++b;
  return (unsigned char)*a - (unsigned char)*b;
}

int strncmp(const char *a, const char *b, size_t n) {
  for (; n; --n, ++a, ++b) {
    if (*a != *b)
      return (unsigned char)*a - (unsigned char)*b;
    if (!*a)
      return 0;
  }
  return 0;
}

char *strcpy(char *dst, const char *src) {
  char *d = dst;
  while ((*d++ = *src++))
    ;
  return dst;
}

char *strncpy(char *dst, const char *src, size_t n) {
  char *d = dst;
  for (; n && *src; --n)
    *d++ = *src++;
  for (; n; --n)
    *d++ = 0;
  return dst;
}

char *strchr(const char *s, int c) {
  for (;; ++s) {
    if (*s == (char)c)
      return (char *)s;
    if (!*s)
      return 0;
  }
}
