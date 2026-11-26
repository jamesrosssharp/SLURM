/* stdio.c - UART output and a small printf for the SLURM16 runtime. */
#include <slurm16.h>
#include <stdio.h>

int putchar(int c) {
  __out(SLURM16_UART_TX, (unsigned char)c);
  /* Wait for the transmitter (status bit 0 = done). */
  while (!(__in(SLURM16_UART_TX) & 1))
    ;
  return (unsigned char)c;
}

int puts(const char *s) {
  while (*s)
    putchar(*s++);
  putchar('\n');
  return 0;
}

struct out {
  char *buf; /* null: write to the UART */
  size_t size;
  size_t len;
};

static void emit(struct out *o, char c) {
  if (o->buf) {
    if (o->len + 1 < o->size)
      o->buf[o->len] = c;
  } else {
    putchar(c);
  }
  o->len++;
}

static int format(struct out *o, const char *fmt, va_list ap) {
  for (; *fmt; ++fmt) {
    if (*fmt != '%') {
      emit(o, *fmt);
      continue;
    }
    ++fmt;
    int left = 0, zero = 0, width = 0, lng = 0;
    for (;; ++fmt) {
      if (*fmt == '-')
        left = 1;
      else if (*fmt == '0')
        zero = 1;
      else
        break;
    }
    while (*fmt >= '0' && *fmt <= '9')
      width = width * 10 + (*fmt++ - '0');
    while (*fmt == 'l') {
      ++lng;
      ++fmt;
    }
    char tmp[24];
    char *s = tmp;
    int n = 0, neg = 0;
    unsigned long long v = 0;
    unsigned base = 10;
    int upper = 0;
    switch (*fmt) {
    case 'd':
    case 'i': {
      long long sv = lng >= 2 ? va_arg(ap, long long)
                     : lng == 1 ? va_arg(ap, long)
                                : va_arg(ap, int);
      if (sv < 0) {
        neg = 1;
        v = -(unsigned long long)sv;
      } else {
        v = sv;
      }
      goto number;
    }
    case 'X':
      upper = 1;
      /* fallthrough */
    case 'x':
      base = 16;
      goto unsigned_number;
    case 'o':
      base = 8;
      goto unsigned_number;
    case 'p':
      base = 16;
      v = (unsigned)va_arg(ap, void *);
      goto number;
    case 'u':
    unsigned_number:
      v = lng >= 2 ? va_arg(ap, unsigned long long)
          : lng == 1 ? va_arg(ap, unsigned long)
                     : va_arg(ap, unsigned);
    number:
      do {
        unsigned d = v % base;
        tmp[n++] = d < 10 ? '0' + d : (upper ? 'A' : 'a') + d - 10;
        v /= base;
      } while (v);
      if (neg)
        tmp[n++] = '-';
      if (!left)
        for (int i = n; i < width; ++i)
          emit(o, zero ? '0' : ' ');
      for (int i = n - 1; i >= 0; --i)
        emit(o, tmp[i]);
      if (left)
        for (int i = n; i < width; ++i)
          emit(o, ' ');
      continue;
    case 'c':
      tmp[0] = (char)va_arg(ap, int);
      n = 1;
      break;
    case 's':
      s = va_arg(ap, char *);
      if (!s)
        s = "(null)";
      while (s[n])
        ++n;
      break;
    case '%':
      emit(o, '%');
      continue;
    case 0:
      --fmt;
      continue;
    default:
      emit(o, '%');
      emit(o, *fmt);
      continue;
    }
    if (!left)
      for (int i = n; i < width; ++i)
        emit(o, ' ');
    for (int i = 0; i < n; ++i)
      emit(o, s[i]);
    if (left)
      for (int i = n; i < width; ++i)
        emit(o, ' ');
  }
  if (o->buf && o->size)
    o->buf[o->len < o->size ? o->len : o->size - 1] = 0;
  return o->len;
}

int vprintf(const char *fmt, va_list ap) {
  struct out o = {0, 0, 0};
  return format(&o, fmt, ap);
}

int printf(const char *fmt, ...) {
  va_list ap;
  va_start(ap, fmt);
  int r = vprintf(fmt, ap);
  va_end(ap);
  return r;
}

int vsnprintf(char *buf, size_t n, const char *fmt, va_list ap) {
  struct out o = {buf, n, 0};
  return format(&o, fmt, ap);
}

int snprintf(char *buf, size_t n, const char *fmt, ...) {
  va_list ap;
  va_start(ap, fmt);
  int r = vsnprintf(buf, n, fmt, ap);
  va_end(ap);
  return r;
}

int sprintf(char *buf, const char *fmt, ...) {
  va_list ap;
  va_start(ap, fmt);
  int r = vsnprintf(buf, 0xffff, fmt, ap);
  va_end(ap);
  return r;
}
