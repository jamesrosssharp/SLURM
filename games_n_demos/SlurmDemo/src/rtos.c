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

#include <slurminterrupt.h>

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
	struct rtos_wait_object* wait_object;
};

struct rtos_task_context g_tasks[RTOS_NUM_TASKS];
struct rtos_task_context* g_runningTask = 0;

/* Idle task */

static void rtos_idle_task()
{
	int tick = 0;
	
	while (1)
	{
		tick++;

		if ((tick & 255) == 0)
			my_printf("Idle task!\r\n");

		__sleep();
	}
}

/* Task finished - mark running task as not enabled */
extern void rtos_trap_task_end();

/* RTOS Init - called before main */

extern void main();
extern short _estack[];
extern short _sstack[];
extern short _eidlestack[];
extern short _sidlestack[];


extern void exit();

void (*g_irq_handlers[16])() = {0};

void rtos_trap_task_end()
{
	int i;

	g_runningTask->t_flags &= ~TASK_FLAGS_ENABLED;
	
	// Find another task
	
	for (i = 0; i < RTOS_NUM_TASKS; i++)
	{
		if (g_tasks[i].t_flags & TASK_FLAGS_ENABLED && !g_tasks[i].t_flags & TASK_FLAGS_WAITING)
		{
			g_runningTask = &g_tasks[i];
			rtos_resume_task();
		}
	}

	my_printf("RTOS ERROR: No more tasks!");

	// This will exit the simulation if simulating, otherwise it will spin
	exit();
}


static void rtos_create_task(int task_id, void (*task_entry)(), void* sstack, void* estack, short flags)
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

void rtos_add_task(int task_id, void (*task_entry)(), void* sstack, void* estack)
{
	global_interrupt_disable();
	rtos_create_task(task_id, task_entry, sstack, estack, TASK_FLAGS_ENABLED);  
	global_interrupt_enable();
}

void rtos_init()
{
	// We assume we are in a critical section with interrupts disabled.

	int i = 0;

	my_printf("RTOS Init!\r\n");

	// Set up idle task - task N - 1 (lowest priority)

	rtos_create_task(RTOS_NUM_TASKS - 1, rtos_idle_task, _sidlestack, _eidlestack, TASK_FLAGS_ENABLED);

	// Set up main task - task N - 2 (second lowest priority)

	rtos_create_task(RTOS_NUM_TASKS - 2, main, _sstack, _estack, TASK_FLAGS_ENABLED);

	// Set up the rest of the task slots

	for (i = 0; i < RTOS_NUM_TASKS - 2; i++)
	{
		rtos_create_task(i, 0, 0, 0, 0);
	}

	// Zero out all IRQ handlers

	for (i = 0; i < NUM_SLURM_INTERRUPTS; i++)
	{
		g_irq_handlers[i] = 0;
	}

	// Enable all interrupts

	__out(0x7000, SLURM_INTERRUPT_VSYNC | SLURM_INTERRUPT_FLASH_DMA | SLURM_INTERRUPT_AUDIO);

	// Set main task as current task
	g_runningTask = &g_tasks[RTOS_NUM_TASKS - 2];

	// Commence main task
	rtos_resume_task();
}


void rtos_set_interrupt_handler(unsigned short irq, void (*handler)())
{
	// Simple assignment is atomic on slurm16 platform
	g_irq_handlers[irq] = handler;
}

void rtos_handle_interrupt_callback(unsigned short irq)
{
	if (g_irq_handlers[irq])
		g_irq_handlers[irq]();	
}

void rtos_reschedule_wait_object(struct rtos_wait_object* wobj)
{

	int i;
	struct rtos_task_context* task;

	g_runningTask->wait_object 	= wobj;
	g_runningTask->t_flags 		|= TASK_FLAGS_WAITING; 
		
	// Find a suitable task to run next

	task = g_tasks;

	for (i = 0; i < RTOS_NUM_TASKS; i++)
	{
		if ((task->t_flags & TASK_FLAGS_ENABLED) && !(task->t_flags & TASK_FLAGS_WAITING))
		{
			//my_printf("Yield: %x -> %x\n", g_runningTask, i);
			g_runningTask = task;
			break;	
		}

		task++;
	}	

	// Yield
	rtos_resume_task();
}

int	rtos_reschedule_wait_object_released(struct rtos_wait_object* wobj)
{

	int i;
	struct rtos_task_context* task;
	int ret = 0;

	// Awaken any sleeping tasks waiting on this object
	
	task = g_tasks;

	for (i = 0; i < RTOS_NUM_TASKS; i++)
	{
		if ((task->t_flags & TASK_FLAGS_ENABLED) && (task->t_flags & TASK_FLAGS_WAITING) && (task->wait_object == wobj))
		{
			task->t_flags &= ~TASK_FLAGS_WAITING;


			// Check if this new task is a higher priority than the running task, otherwise don't reschedule.
			if (task < g_runningTask)
			{
				//my_printf("Yield: %x -> %x\r\n", g_runningTask, i);
				g_runningTask = task;
			}
			//else
			//	my_printf("Returning to same task - %x %x\r\n", g_runningTask, g_runningTask->pc);

			ret = 1;
			break;
		}

		task ++;
	}
	return ret;
}

/* All other functions are implemented in assembler */

// DEBUG

void rtos_printy(unsigned short reg)
{
	my_printf("Reg: %x tasks: %x\r\n", reg, g_tasks);
	while (1) ;
} 


