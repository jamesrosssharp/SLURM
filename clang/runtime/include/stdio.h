#ifndef _SLURM16_STDIO_H
#define _SLURM16_STDIO_H
#include <stdarg.h>
#include <stddef.h>
#ifdef __cplusplus
extern "C" {
#endif
#define EOF (-1)
/* Output goes to the UART. */
int putchar(int c);
int puts(const char *s);
/* Supports %d %i %u %x %X %o %c %s %p %%, the 'l' and 'll' length
   modifiers, field width and '0' / '-' flags. */
int printf(const char *fmt, ...);
int vprintf(const char *fmt, va_list ap);
int sprintf(char *buf, const char *fmt, ...);
int snprintf(char *buf, size_t n, const char *fmt, ...);
int vsnprintf(char *buf, size_t n, const char *fmt, va_list ap);
#ifdef __cplusplus
}
#endif
#endif
