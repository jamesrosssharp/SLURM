/*
 * game_io.h: routines provided by the assembly start up code (top.asm) and
 * interrupt.asm of the games and demos that do not use SlurmOS.
 */

#ifndef GAME_IO_H
#define GAME_IO_H

void putc(char c);
void exit();

void trace_dec(short d);
void trace_char(char c);
void trace_hex(short h);

unsigned short __in(unsigned short port);
void __out(unsigned short port, unsigned short val);
void __sleep(void);

void global_interrupt_enable(void);
void global_interrupt_disable(void);

#endif
