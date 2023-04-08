/*

	SlurmDemo : A demo to show off SlURM16

rtos.h: Real Time Operating System Kernel

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

#ifndef RTOS_H
#define RTOS_H

#define TASK_FLAGS_ENABLED  1	/* task is in use */
#define TASK_FLAGS_FROM_INT 2	/* task yielded in an interrupt - must restore interrupt context */
#define TASK_FLAGS_WAITING  4   /* task is waiting on a wait object */

#ifndef __ASM__

	enum wait_object_type {
		WOT_MUTEX = 0,
	};

	struct rtos_wait_object {
		unsigned char type; /* so we can have mutexes, semaphores etc. */
		unsigned char param; /* the actual lock variable */
	};

	typedef struct rtos_wait_object mutex_t;

	#define RTOS_MUTEX_INITIALIZER = {WOT_MUTEX, 0};

	extern void 	rtos_resume_task();

	extern void 	rtos_lock_mutex(mutex_t* mut);
	extern void	rtos_unlock_mutex(mutex_t* mut);
	extern void	rtos_unlock_mutex_from_isr(mutex_t* mut);

	void 		rtos_init();
	void 		rtos_set_interrupt_handler(unsigned short irq, void (*handler)());

	void 		rtos_handle_interrupt_callback(unsigned short irq);

#endif

#endif
