/* stdlib.c - heap, exit and misc functions for the SLURM16 runtime. */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* The heap grows up from the end of the program towards the stack. */
extern char _heap_start[];
extern char _sstack[];

/* A simple first-fit free list allocator. */
struct block {
  size_t size; /* bytes, including this header; low bit = in use */
};

static char *heap_end;

void *malloc(size_t n) {
  if (!heap_end)
    heap_end = _heap_start;
  n = (n + sizeof(struct block) + 1) & ~1u;
  /* First fit in the already allocated region. */
  for (char *p = _heap_start; p < heap_end;) {
    struct block *b = (struct block *)p;
    size_t sz = b->size & ~1u;
    if (!(b->size & 1)) {
      /* Coalesce with following free blocks. */
      while (p + sz < heap_end && !(((struct block *)(p + sz))->size & 1))
        sz += ((struct block *)(p + sz))->size;
      b->size = sz;
      if (sz >= n) {
        if (sz - n >= sizeof(struct block) + 2) {
          ((struct block *)(p + n))->size = sz - n;
          sz = n;
        }
        b->size = sz | 1;
        return b + 1;
      }
    }
    p += sz;
  }
  /* Keep a small gap below the stack region. */
  if ((size_t)(_sstack - heap_end) < n)
    return 0;
  struct block *b = (struct block *)heap_end;
  b->size = n | 1;
  heap_end += n;
  return b + 1;
}

void free(void *ptr) {
  if (ptr)
    ((struct block *)ptr - 1)->size &= ~1u;
}

void *calloc(size_t n, size_t size) {
  size_t total = n * size;
  if (size && total / size != n)
    return 0;
  void *p = malloc(total);
  if (p)
    memset(p, 0, total);
  return p;
}

#define MAX_ATEXIT 16
static void (*atexit_fns[MAX_ATEXIT])(void);
static int atexit_count;

int atexit(void (*fn)(void)) {
  if (atexit_count == MAX_ATEXIT)
    return -1;
  atexit_fns[atexit_count++] = fn;
  return 0;
}

void exit(int status) {
  while (atexit_count)
    atexit_fns[--atexit_count]();
  _exit(status);
}

void abort(void) {
  puts("abort()");
  _exit(134);
}

void __assert_fail(const char *expr, const char *file, int line) {
  printf("%s:%d: assertion failed: %s\n", file, line, expr);
  abort();
}

int abs(int x) { return x < 0 ? -x : x; }
long labs(long x) { return x < 0 ? -x : x; }

int atoi(const char *s) {
  int neg = 0, v = 0;
  while (*s == ' ' || *s == '\t')
    ++s;
  if (*s == '-' || *s == '+')
    neg = *s++ == '-';
  while (*s >= '0' && *s <= '9')
    v = v * 10 + (*s++ - '0');
  return neg ? -v : v;
}
