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

// WARNING: If you change this structure, you must change the assembly version
// of the structure
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
	void* estack;

	// Object we are waiting on - if waiting 
	struct rtos_wait_object* wait_object;

	// Ticks for performance measurements
	unsigned short ticks_start;
	unsigned short ticks_total_lo;
	unsigned short ticks_total_hi;
	
};

struct rtos_task_context g_tasks[RTOS_NUM_TASKS];
struct rtos_task_context* g_runningTask = 0;

/* Idle task */

#define STACK_CANARY 0xdead

static void rtos_idle_task()
{
	int tick = 0;
	int i;

	while (1)
	{
		tick++;

		if ((tick & 1023) == 0)
		{
			my_printf("TASKS tick = %x\r\n", __in(0x9000));
			my_printf("======================\r\n");
			
			for (i = 0; i < RTOS_NUM_TASKS; i++)
			{			
				unsigned short* sp = g_tasks[i].stack;
				int hw = 0;

				while (*sp++ == STACK_CANARY)
					hw++;

				my_printf("%d\tsp=%x\tstack=%x\t", i, g_tasks[i].reg[13 - 1], g_tasks[i].stack);
				my_printf("hw=%x\tpc=%x\tflg=%x\t", hw, g_tasks[i].pc, g_tasks[i].t_flags);
				my_printf("ticks=%x %x\r\n", 0, 0);
			}
		}

		__sleep();
	}
}

/* Task finished - mark running task as not enabled */
extern void rtos_trap_task_end();

/* RTOS Init - called before main */

extern void main();
extern unsigned short _estack[];
extern unsigned short _sstack[];
extern unsigned short _eidlestack[];
extern unsigned short _sidlestack[];


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


static void rtos_create_task(int task_id, void (*task_entry)(), unsigned short* sstack, unsigned short* estack, short flags)
{
	int i = 0;
	struct rtos_task_context* task;
	unsigned short* sp;

	task = &g_tasks[task_id];

	for (i = 0; i < 14; i++)
		task->reg[i] = 0;	// Clear all registers
	task->reg[15 - 1] = (unsigned short)rtos_trap_task_end; // If task returns, flag it as disabled and yield
	task->pc = (unsigned short)task_entry;
	task->wait_object = 0;

	/* TODO: need to allocate off the heap */
	task->stack = sstack;
	task->estack = estack;
	task->reg[13 - 1] = (unsigned short)estack;

	/* Initialize stack to our canary value */
	for (sp = sstack; sp < estack; sp++)
	{
		*sp = STACK_CANARY;
	}

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
	
	// Enable timer

	__out(0x9000, 1);
	__out(0x9001, 0);

	// Enable all interrupts

	__out(0x7000, SLURM_INTERRUPT_VSYNC | SLURM_INTERRUPT_FLASH_DMA | SLURM_INTERRUPT_AUDIO | SLURM_INTERRUPT_TIMER);

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
//	if (irq == SLURM_INTERRUPT_TIMER_IDX)
//	{
//		my_printf("Timer int!\r\n");
//	} 

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
			//if (task < g_runningTask)
			//{
				g_runningTask = task;
			//}

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


