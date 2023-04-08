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
	ld r1, [g_runningTask]
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
	.global   rtos_lock_mutex
	.function rtos_lock_mutex

rtos_lock_mutex:
	ret

	.endfunc

// extern void	rtos_unlock_mutex();


// extern void	rtos_unlock_mutex_from_isr();

	.global   rtos_unlock_mutex_from_isr
	.function rtos_unlock_mutex_from_isr

rtos_unlock_mutex_from_isr:
	ret	

	.endfunc

// rtos_handle_interrupt

	.global rtos_handle_interrupt
	.function rtos_handle_interrupt

rtos_handle_interrupt:
	// We have been called in interrupt context (interrupts are now disabled)
	// with previous value of r1 on [r13,-2]
	//
	// We need to preserve more registers to get a handle to the current task
	//
	// Preserve current task context

	st [r13, -4], r2
	ld r2, [g_runningTask]

	st [r2, TASK_STRUCTURE_R3], r3
	st [r2, TASK_STRUCTURE_R4], r4
	st [r2, TASK_STRUCTURE_R5], r5
	st [r2, TASK_STRUCTURE_R6], r6
	st [r2, TASK_STRUCTURE_R7], r7
	st [r2, TASK_STRUCTURE_R8], r8
	st [r2, TASK_STRUCTURE_R9], r9
	st [r2, TASK_STRUCTURE_R10], r10
	st [r2, TASK_STRUCTURE_R11], r11
	st [r2, TASK_STRUCTURE_R12], r12
	st [r2, TASK_STRUCTURE_R13], r13
	st [r2, TASK_STRUCTURE_R14], r14
	st [r2, TASK_STRUCTURE_R15], r15

	ld r3, [r13, -4]
	st [r2, TASK_STRUCTURE_R2], r3
	ld r3, [r13, -2]
	st [r2, TASK_STRUCTURE_R1], r3
	
	// All registers preserved - store interrupt context

	stix r3
	st [r2, TASK_STRUCTURE_ICTX], r3

	// Mark current task as "from_int"

	ld r3, [r2, TASK_STRUCTURE_FLAGS]
	or r3, TASK_FLAGS_FROM_INT
	st [r2, TASK_STRUCTURE_FLAGS], r3

	// Important - mark contents of r14 as task pc

	st [r2, TASK_STRUCTURE_PC], r14

	// Branch to handler - running task may change

	.extern rtos_handle_interrupt_callback
	mov r4, r1 // Interrupt index
	bl rtos_handle_interrupt_callback
	
	// Resume next task - may be same task, or new task
	ba rtos_resume_task

	.endfunc

	.end
