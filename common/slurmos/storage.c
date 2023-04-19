/*

storage.c: Routines for queueing the flash controller

License: MIT License

Copyright 2023 J.R.Sharp

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

#include <slurmflash.h>
#include <slurminterrupt.h>
#include "storage.h"
#include "rtos.h"
#include "printf.h"

extern unsigned short _sstoragestack[];
extern unsigned short _estoragestack[];

static mutex_t storage_int_mutex 	  = RTOS_MUTEX_INITIALIZER; /* Interrupt mutex - wake up queue runner */
static mutex_t storage_wait_mutex 	  = RTOS_MUTEX_INITIALIZER; /* Synch call wait for queue mutex */
static mutex_t storage_q_wait_read_mutex  = RTOS_MUTEX_INITIALIZER; /* Queue empty - wait on queue push mutex */
static mutex_t storage_q_wait_write_mutex = RTOS_MUTEX_INITIALIZER; /* Queue full - wait on queue pop mutex */
static mutex_t storage_q_mutex 		  = RTOS_MUTEX_INITIALIZER; /* Lock queue - prevent race between multiple queue writers */

struct storage_q_item {
	unsigned short 		flash_offset_lo;
	unsigned short 		flash_offset_hi;
	unsigned short 		word_address;
	unsigned short 		count_minus_one;
	storage_callback_t 	cb;
	void* 			user_data;
};

// Power of two
#define STORAGE_Q_SIZE 8

static struct storage_q_item storage_q[STORAGE_Q_SIZE];
static int storage_q_head = 0;
static int storage_q_tail = 0;

static void storage_interrupt()
{
	//my_printf("Storage interrupt!\r\n");
	rtos_unlock_mutex_from_isr(&storage_int_mutex);
}

static void storage_task()
{
	while (1)
	{
		unsigned short q_items;
		struct storage_q_item* q_p;

		// Check queue

		q_items = (storage_q_head - storage_q_tail) & (STORAGE_Q_SIZE - 1); 

		while (q_items < 1)
		{
			//my_printf("No queue items, sleeping\r\n");
			rtos_lock_mutex(&storage_q_wait_read_mutex);
			//my_printf("Woke up again\r\n");

			q_items = (storage_q_head - storage_q_tail) & (STORAGE_Q_SIZE - 1); 
		}

		// We now have a queue item pointed to by tail.
		// Load the registers.
			
		q_p = &storage_q[storage_q_tail];

		__out(SPI_FLASH_ADDR_LO, q_p->flash_offset_lo);
		__out(SPI_FLASH_ADDR_HI, q_p->flash_offset_hi);
		__out(SPI_FLASH_DMA_ADDR, q_p->word_address);
		__out(SPI_FLASH_DMA_COUNT, q_p->count_minus_one);
		
		// Fire
		__out(SPI_FLASH_CMD, 1);

		rtos_lock_mutex(&storage_int_mutex);

		//my_printf("Storage complete!\r\n");

		// Call callback

		if (q_p->cb)
			q_p->cb(q_p->user_data);

		// Advance queue tail

		storage_q_tail = (storage_q_tail + 1) & (STORAGE_Q_SIZE - 1);

		// Signal any threads waiting on the queue

		// This should be a counting semaphore
		if (q_items == STORAGE_Q_SIZE - 1)
			rtos_unlock_mutex(&storage_q_wait_write_mutex);
	}
}

void storage_init(int storage_task_id)
{
	rtos_lock_mutex(&storage_int_mutex);
	
	rtos_set_interrupt_handler(SLURM_INTERRUPT_FLASH_DMA_IDX, storage_interrupt);
	rtos_add_task(storage_task_id, storage_task, _sstoragestack, _estoragestack);
	
	rtos_lock_mutex(&storage_wait_mutex);
	rtos_lock_mutex(&storage_q_wait_read_mutex);
	rtos_lock_mutex(&storage_q_wait_write_mutex);

	my_printf("Storage init'd\r\n");
}

static void storage_dummy_callback(void* arg)
{
	(void)arg;

	rtos_unlock_mutex(&storage_wait_mutex);

}

void storage_load_synch(unsigned short base_lo, unsigned short base_hi, 
		  unsigned short offset_lo, unsigned short offset_hi, 
		  unsigned short address_lo, unsigned short address_hi, 
		  short count)
{
	my_printf("Storage load synch!\r\n");
	storage_load_asynch(base_lo, base_hi, offset_lo, offset_hi, address_lo, address_hi, count, storage_dummy_callback, 0);
	rtos_lock_mutex(&storage_wait_mutex);
}

static void storage_fill_q_item(struct storage_q_item* q_p, 
		  unsigned short base_lo, unsigned short base_hi, 
		  unsigned short offset_lo, unsigned short offset_hi, 
		  unsigned short address_lo, unsigned short address_hi, 
		  short count, storage_callback_t cb, void* user_data)
{
	q_p->flash_offset_lo = calculate_flash_offset_lo(base_lo, base_hi, offset_lo, offset_hi);
	q_p->flash_offset_hi = calculate_flash_offset_hi(base_lo, base_hi, offset_lo, offset_hi);
	q_p->word_address = (address_hi ? 0x8000U : 0x0000U) | (address_lo >> 1);
	q_p->count_minus_one = count - 1;
	q_p->cb = cb;
	q_p->user_data = user_data;
}

void storage_load_asynch(unsigned short base_lo, unsigned short base_hi, 
		  unsigned short offset_lo, unsigned short offset_hi, 
		  unsigned short address_lo, unsigned short address_hi, 
		  short count, storage_callback_t cb, void* user_data)
{
	unsigned short queue_space = 0;
	struct storage_q_item* q_p;

	// Lock queue mutex
	rtos_lock_mutex(&storage_q_mutex);

		queue_space = (storage_q_tail - storage_q_head - 1) & (STORAGE_Q_SIZE - 1); 
		
		if (queue_space < 1)
		{
			// Unlock access to queue
			rtos_unlock_mutex(&storage_q_mutex);

			// Wait for some space
			rtos_lock_mutex(&storage_q_wait_write_mutex);

			// Reacquire queue access
			rtos_lock_mutex(&storage_q_mutex);
		}

		// Write into queue
		
		q_p = &storage_q[storage_q_head];

		storage_fill_q_item(q_p, base_lo, base_hi, offset_lo, offset_hi, address_lo, address_hi, count, cb, user_data);

		// Advance head
		storage_q_head = (storage_q_head + 1) & (STORAGE_Q_SIZE - 1);


		if (queue_space == STORAGE_Q_SIZE - 1)
			rtos_unlock_mutex(&storage_q_wait_read_mutex);

	rtos_unlock_mutex(&storage_q_mutex);
	
	// Unlock storage read wait mutex

}


