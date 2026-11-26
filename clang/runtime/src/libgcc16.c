/* libgcc16.c - integer helpers for SLURM16 not provided by compiler-rt:
   16 bit division / remainder and 32 bit shifts. */

typedef unsigned short u16;
typedef short s16;
typedef unsigned long u32;
typedef long s32;

static u16 udivmod16(u16 n, u16 d, u16 *rem) {
  u16 q = 0, r = 0;
  if (d == 0) {
    *rem = n;
    return 0xffff;
  }
  for (int i = 15; i >= 0; --i) {
    r = (r << 1) | ((n >> 15) & 1);
    n <<= 1;
    q <<= 1;
    if (r >= d) {
      r -= d;
      q |= 1;
    }
  }
  *rem = r;
  return q;
}

u16 __udivhi3(u16 n, u16 d) {
  u16 r;
  return udivmod16(n, d, &r);
}

u16 __umodhi3(u16 n, u16 d) {
  u16 r;
  udivmod16(n, d, &r);
  return r;
}

s16 __divhi3(s16 n, s16 d) {
  u16 r;
  int neg = (n < 0) ^ (d < 0);
  u16 q = udivmod16(n < 0 ? -(u16)n : (u16)n, d < 0 ? -(u16)d : (u16)d, &r);
  return neg ? -(s16)q : (s16)q;
}

s16 __modhi3(s16 n, s16 d) {
  u16 r;
  udivmod16(n < 0 ? -(u16)n : (u16)n, d < 0 ? -(u16)d : (u16)d, &r);
  return n < 0 ? -(s16)r : (s16)r;
}

/* 32 bit shifts by a variable amount. Built from 16 bit operations. */
u32 __ashlsi3(u32 a, int b) {
  u16 lo = a, hi = a >> 16;
  b &= 31;
  if (b >= 16) {
    hi = lo << (b - 16);
    lo = 0;
  } else if (b) {
    hi = (hi << b) | (lo >> (16 - b));
    lo <<= b;
  }
  return ((u32)hi << 16) | lo;
}

u32 __lshrsi3(u32 a, int b) {
  u16 lo = a, hi = a >> 16;
  b &= 31;
  if (b >= 16) {
    lo = hi >> (b - 16);
    hi = 0;
  } else if (b) {
    lo = (lo >> b) | (hi << (16 - b));
    hi >>= b;
  }
  return ((u32)hi << 16) | lo;
}

s32 __ashrsi3(s32 a, int b) {
  u16 lo = a;
  s16 hi = a >> 16;
  b &= 31;
  if (b >= 16) {
    lo = hi >> (b - 16);
    hi = hi >> 15;
  } else if (b) {
    lo = (lo >> b) | ((u16)hi << (16 - b));
    hi >>= b;
  }
  return (s32)(((u32)(u16)hi << 16) | lo);
}
