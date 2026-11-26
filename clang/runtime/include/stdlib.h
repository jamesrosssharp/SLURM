#ifndef _SLURM16_STDLIB_H
#define _SLURM16_STDLIB_H
#include <stddef.h>
#ifdef __cplusplus
extern "C" {
#endif
#define EXIT_SUCCESS 0
#define EXIT_FAILURE 1
void *malloc(size_t n);
void *calloc(size_t n, size_t size);
void free(void *p);
void exit(int status) __attribute__((noreturn));
void _exit(int status) __attribute__((noreturn));
void abort(void) __attribute__((noreturn));
int atexit(void (*fn)(void));
int abs(int x);
long labs(long x);
int atoi(const char *s);
#ifdef __cplusplus
}
#endif
#endif
