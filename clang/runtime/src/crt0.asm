// crt0.asm - SLURM16 C runtime start up (slurmasm-ng syntax)
//
//  - installs the interrupt vector table at address 0
//  - sets up the stack
//  - zeroes .bss
//  - runs static constructors (.init_array)
//  - calls main(), then _exit(return value)
//
// Interrupt handlers may be provided by defining (global) functions named
// __slurm16_irq_hsync, __slurm16_irq_vsync, __slurm16_irq_audio,
// __slurm16_irq_flash, ... in assembly; the weak defaults below just iret.

	.section vectors
__slurm16_vectors:
	ba _start
	ba __slurm16_irq_hsync
	ba __slurm16_irq_vsync
	ba __slurm16_irq_audio
	ba __slurm16_irq_flash
	ba __slurm16_irq_gpio
	ba __slurm16_irq_timer
	.times 9 ba __slurm16_irq_default

	.section text
	.function _start
_start:
	// Copy the vector table to address 0 (16 vectors x 2 words)
	mov r1, r0
	mov r2, __slurm16_vectors
	mov r3, 32
_start.copy_vectors:
	ld r4, [r2, 0]
	st [r1, 0], r4
	add r1, 2
	add r2, 2
	sub r3, 1
	bnz _start.copy_vectors

	// Stack
	mov r13, _estack

	// Zero .bss
	mov r1, _szero
	mov r2, _ezero
_start.zero_bss:
	cmp r1, r2
	bgeu _start.zero_done
	st [r1, 0], r0
	add r1, 2
	ba _start.zero_bss
_start.zero_done:

	// Static constructors
	mov r10, __init_array_start
_start.init:
	cmp r10, __init_array_end
	bgeu _start.init_done
	ld r1, [r10, 0]
	bl [r1]
	add r10, 2
	ba _start.init
_start.init_done:

	mov r4, r0
	mov r5, r0
	bl main
	mov r4, r2
	bl _exit
	.endfunc

	// void _exit(int status): stop the CPU. The status is left in r2 (the
	// simulator reports it as the exit code).
	.function _exit
_exit:
	mov r2, r4
	cli
_exit.halt:
	sleep
	ba _exit.halt
	.endfunc

	.function __slurm16_irq_default
__slurm16_irq_default:
__slurm16_irq_hsync:
__slurm16_irq_vsync:
__slurm16_irq_audio:
__slurm16_irq_flash:
__slurm16_irq_gpio:
__slurm16_irq_timer:
	iret
	.endfunc

	.global _start
	.global _exit
	.global __slurm16_vectors
	.weak __slurm16_irq_hsync
	.weak __slurm16_irq_vsync
	.weak __slurm16_irq_audio
	.weak __slurm16_irq_flash
	.weak __slurm16_irq_gpio
	.weak __slurm16_irq_timer
	.end
