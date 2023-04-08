/*

	SlurmDemo : A demo to show off SlURM16

rtos.asm: Real Time Operating System Kernel, low level routines

License: MIT License

Copyright 2023 J.R.Sharp

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

.extern g_tasks
.extern g_runningTask 

#define __ASM__
#include "rtos.h"

// Task structure

/*
struct rtos_task_context {

	// We only preserve r1 - r15... x16 - x127 must be used with discretion in
	// the tasks themselves to avoid conflicts.
	unsigned short reg[15];
	unsigned short pc;	

	// Flags such as task from interrupt etc <- task needs to resume with iret.
	unsigned short t_flags;

	// Interrupt context <- restore if from interrupt
	unsigned short int_ctx;

	// Stack allocated for task.
	void* stack;

	// Object the 
	struct wait_object* wait_object;
};
*/

TASK_STRUCTURE_R1 equ 0
TASK_STRUCTURE_R2 equ 2
TASK_STRUCTURE_R3 equ 4
TASK_STRUCTURE_R4 equ 6
TASK_STRUCTURE_R5 equ 8
TASK_STRUCTURE_R6 equ 10
TASK_STRUCTURE_R7 equ 12
TASK_STRUCTURE_R8 equ 14
TASK_STRUCTURE_R9 equ 16
TASK_STRUCTURE_R10 equ 18
TASK_STRUCTURE_R11 equ 20
TASK_STRUCTURE_R12 equ 22
TASK_STRUCTURE_R13 equ 24
TASK_STRUCTURE_R14 equ 26
TASK_STRUCTURE_R15 equ 28
TASK_STRUCTURE_PC  equ 30
TASK_STRUCTURE_FLAGS equ 32
TASK_STRUCTURE_ICTX  equ 34
TASK_STRUCTURE_STCK  equ 36
TASK_STRUCTURE_WOBJ  equ 38

TASK_STRUCTURE_SIZE  equ 40

	.extern main
// extern void 	rtos_resume_task();
	.global rtos_resume_task
	.function rtos_resume_task
rtos_resume_task:
	// We assume we have been called in a critical section, with interrupts disabled.

	// We can trash whatever registers we want, as we never return directly to where we 
	// have come from.

	// Check if task is "from_int". If so, handle appropriately 
	ld r2, [g_runningTask]
	mov r1, g_tasks
	mul r2, TASK_STRUCTURE_SIZE
	add r1, r2	// R1 : rtos_task_context* 
	ld  r2, [r1, TASK_STRUCTURE_FLAGS]
        test r2, TASK_FLAGS_FROM_INT 	
	bnz resume_task_from_int

	// set R15 to PC of task
	ld r14, [r1, TASK_STRUCTURE_PC]

	// Restore context from task	
	ld r15, [r1, TASK_STRUCTURE_R15]
	ld r13, [r1, TASK_STRUCTURE_R13]
	ld r12, [r1, TASK_STRUCTURE_R12]
	ld r11, [r1, TASK_STRUCTURE_R11]
	ld r10, [r1, TASK_STRUCTURE_R10]
	ld r9,  [r1, TASK_STRUCTURE_R9]
	ld r8,  [r1, TASK_STRUCTURE_R8]
	ld r7,  [r1, TASK_STRUCTURE_R7]
	ld r6,  [r1, TASK_STRUCTURE_R6]
	ld r5,  [r1, TASK_STRUCTURE_R5]
	ld r4,  [r1, TASK_STRUCTURE_R4]
	ld r3,  [r1, TASK_STRUCTURE_R3]
	ld r2,  [r1, TASK_STRUCTURE_R2]
	ld r1,  [r1, TASK_STRUCTURE_R1]

	// Enable interrupts
	iret
	
resume_task_from_int:

	// Unmark task as "from_int"
	and r2, ~TASK_FLAGS_FROM_INT
	st [r1, TASK_STRUCTURE_FLAGS], r2

	// Restore interrupt context
	ld r2, [r1, TASK_STRUCTURE_ICTX]
	rsix r2
	
	// Restore task context
	ld r14, [r1, TASK_STRUCTURE_PC]

	ld r15, [r1, TASK_STRUCTURE_R15]
	ld r13, [r1, TASK_STRUCTURE_R13]
	ld r12, [r1, TASK_STRUCTURE_R12]
	ld r11, [r1, TASK_STRUCTURE_R11]
	ld r10, [r1, TASK_STRUCTURE_R10]
	ld r9,  [r1, TASK_STRUCTURE_R9]
	ld r8,  [r1, TASK_STRUCTURE_R8]
	ld r7,  [r1, TASK_STRUCTURE_R7]
	ld r6,  [r1, TASK_STRUCTURE_R6]
	ld r5,  [r1, TASK_STRUCTURE_R5]
	ld r4,  [r1, TASK_STRUCTURE_R4]
	ld r3,  [r1, TASK_STRUCTURE_R3]
	ld r2,  [r1, TASK_STRUCTURE_R2]
	ld r1,  [r1, TASK_STRUCTURE_R1]

	// Return from interrupt
	
	iret

	.endfunc


// extern void 	rtos_lock_mutex();
// extern void	rtos_unlock_mutex();
// extern void	rots_unlock_mutex_from_isr();

	.end
