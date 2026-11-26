/* slurm16.h - SLURM16 hardware access helpers for C and C++. */
#ifndef SLURM16_H
#define SLURM16_H

#ifdef __cplusplus
extern "C" {
#endif

/* Read a 16 bit value from an I/O port. */
static inline unsigned short __in(unsigned short port) {
  unsigned short v;
  __asm__ volatile("in %0, [%1, 0]" : "=r"(v) : "r"(port));
  return v;
}

/* Write a 16 bit value to an I/O port. */
static inline void __out(unsigned short port, unsigned short value) {
  __asm__ volatile("out [%0, 0], %1" : : "r"(port), "r"(value) : "memory");
}

static inline void __enable_interrupts(void) { __asm__ volatile("sti"); }
static inline void __disable_interrupts(void) { __asm__ volatile("cli"); }
static inline void __sleep(void) { __asm__ volatile("sleep"); }
static inline void __nop(void) { __asm__ volatile("nop"); }

/* Load / store from the upper 64kB memory bank. */
static inline unsigned short __ld_upper(unsigned short addr) {
  unsigned short v;
  __asm__ volatile("ld.ex %0, [%1]" : "=r"(v) : "r"(addr));
  return v;
}
static inline void __st_upper(unsigned short addr, unsigned short value) {
  __asm__ volatile("st.ex [%0], %1" : : "r"(addr), "r"(value) : "memory");
}

#define SLURM16_UART_TX 0x0000

#ifdef __cplusplus
}
#endif

#endif
