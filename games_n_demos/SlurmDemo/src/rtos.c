/*

	SlurmDemo : A demo to show off SlURM16

rtos.c: Real Time Operating System Kernel

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

#include "rtos.h"
#include "rtos_config.h"
#include "printf.h"

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

struct rtos_task_context g_tasks[RTOS_NUM_TASKS];
unsigned short g_runningTask = 0;

unsigned short g_idle_task_stack[64];

/* Idle task */

static void rtos_idle_task()
{
	
	while (1)
	{
		__sleep();
	}
}

/* Task finished - mark running task as not enabled */
extern void rtos_trap_task_end();

/* RTOS Init - called before main */

extern void main();
extern short _estack[];
extern short _sstack[];

extern void exit();

void rtos_trap_task_end()
{
	int i;

	g_tasks[g_runningTask].t_flags &= ~TASK_FLAGS_ENABLED;
	
	// Find another task
	
	for (i = 0; i < RTOS_NUM_TASKS; i++)
	{
		if (g_tasks[i].t_flags & TASK_FLAGS_ENABLED)
		{
			g_runningTask = i;
			rtos_resume_task();
		}
	}

	my_printf("RTOS ERROR: No more tasks!");

	// This will exit the simulation if simulating, otherwise it will spin
	exit();
}


void rtos_create_task(int task_id, void (*task_entry)(), void* sstack, void* estack, short flags)
{
	int i = 0;
	struct rtos_task_context* task;

	task = &g_tasks[task_id];

	for (i = 0; i < 14; i++)
		task->reg[i] = 0;	// Clear all registers
	task->reg[15 - 1] = (unsigned short)rtos_trap_task_end; // If task returns, flag it as disabled and yield
	task->pc = (unsigned short)task_entry;
	task->wait_object = 0;

	/* TODO: need to allocate off the heap */
	task->stack = sstack;
	task->reg[13 - 1] = (unsigned short)estack;
	task->int_ctx = 0;
	task->t_flags = flags;

}


void rtos_init()
{
	int i = 0;

	my_printf("RTOS Init!\r\n");

	// Set up idle task - task N - 1 (lowest priority)

	rtos_create_task(RTOS_NUM_TASKS - 1, rtos_idle_task, g_idle_task_stack, g_idle_task_stack + sizeof(g_idle_task_stack), TASK_FLAGS_ENABLED);

	// Set up main task - task N - 2 (second lowest priority)

	rtos_create_task(RTOS_NUM_TASKS - 2, main, _sstack, _estack, TASK_FLAGS_ENABLED);

	// Set up the rest of the task slots

	for (i = 0; i < RTOS_NUM_TASKS - 2; i++)
	{
		rtos_create_task(i, 0, 0, 0, 0);
	}

	// Set main task as current task
	g_runningTask = RTOS_NUM_TASKS - 2;

	// Commence main task
	rtos_resume_task();
}

/* All other functions are implemented in assembler */

// DEBUG

void rtos_printy(unsigned short reg)
{
	my_printf("Reg: %x tasks: %x\r\n", reg, g_tasks);
	while (1) ;
} 

