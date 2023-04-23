/*

	SlurmDemo : A demo to show off SlURM16

malloc.c: Real Time Operating System Kernel, heap allocator

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

/*
 *	Linked list structure:
 *
 *	----------------------------------------------------------------------------------------------
 *	|| heap || heap block | unsused block || heap block | used block || heap block | unused block ||
 *           ------->  ------------------------------------------------------> -------------------\
 *                  <-----------------------------------------------------------------------------/  
 */

#include <malloc.h>

struct heap_block 
{
	struct heap_block* next;

	// Size includes this struct
	unsigned short size;
};

struct heap 
{
	unsigned short n_blocks_allocated;
	unsigned short n_bytes_allocated;
	unsigned short total_bytes;
	struct heap_block* root;
};

#ifndef TEST

	extern unsigned char _heap_start[];
	extern unsigned char _heap_end[];

#else

	unsigned short heap[16384];
	unsigned short* _heap_start = &heap[0];
	unsigned short* _heap_end = &heap[16383];

#endif


void  my_init_heap()
{
	struct heap_block* f;
	struct heap* h = (struct heap*)_heap_start;
		
	h->total_bytes = _heap_end - _heap_start;
	h->n_blocks_allocated = 0;
	h->n_bytes_allocated = 0;

	my_printf("Heap total bytes: %x %x %x\r\n", h->total_bytes, _heap_end, _heap_start);
	
	f = (struct heap_block*)(h + 1);

	h->root = f;

	f->next = NULL;	
	f->size = h->total_bytes - sizeof(struct heap);

}

void* my_malloc(unsigned short bytes)
{

	struct heap* h = (struct heap*)_heap_start;
	void *block_ptr = NULL;
	
	// Traverse singly linked list until end looking for a big enough block.

	struct heap_block* f = h->root;
	struct heap_block** prev_ptr = &h->root;

	bytes += 1;
	bytes &= 0xfffe;

	my_printf("malloc: %d bytes\r\n", bytes);
	
	while (1)
	{
		if (f->size > (bytes + 2*sizeof(struct heap_block)))
		{
			struct heap_block* f_new = (struct heap_block*)((uintptr_t)f + sizeof(struct heap_block) + bytes);
			
			my_printf("-> found block %x\r\n", f);
		
			block_ptr = (void*)((uintptr_t)f + sizeof(struct heap_block));

			if (f->next == NULL)
				f_new->next = NULL;
			else
				f_new->next = f->next;

			*prev_ptr = f_new;
			f_new->size = f->size - sizeof(struct heap_block) - bytes;
			f->size = bytes + sizeof(struct heap_block);
				
			h->n_bytes_allocated += f->size;
			h->n_blocks_allocated ++; 
	
			break;
		}
		
		// At end of list
		if (f->next == NULL) return NULL;

		prev_ptr = &f->next;
		f = f->next;
	}

	return block_ptr;

}

void  my_free(void* ptr)
{

	struct heap* h = (struct heap*)_heap_start;
	
	// Find the last free block before the block we are freeing

	struct heap_block* f = h->root;
	struct heap_block* prev = NULL;
	struct heap_block* b = (struct heap_block*)((uintptr_t)ptr - sizeof(struct heap_block));

	while ((void*)f < ptr)
	{
		prev = f;
		f = f->next;
	}

	// If the block we are freeing is contiguous with prev AND f, coalesce all three blocks

	if (prev != NULL)
	{

		void *end_of_low_block = (void*)((uintptr_t)prev + (uintptr_t)prev->size);
		void *end_of_free_block = (void*)((uintptr_t)b + (uintptr_t)b->size);

		if (b == end_of_low_block && end_of_free_block == f)
		{
			prev->size += b->size + f->size;
			prev->next = f->next;
			h->n_blocks_allocated --;
			h->n_bytes_allocated -= b->size;
	
			return;
		}
		else if (b == end_of_low_block)
		{
			prev->size += b->size; 
			h->n_blocks_allocated--;
			h->n_bytes_allocated -= b->size;
			return;	
		}

	}


	// If current free block is adjacent to block we are freeing, coalesce the blocks.
	{
		void *end_of_block = (void*)((uintptr_t)b + (uintptr_t)b->size);

		if (end_of_block == (void*)f)
		{
			if (prev == NULL)
				h->root = b;
			else	
				prev->next = b;
	
			h->n_blocks_allocated--;
			h->n_bytes_allocated -= b->size;
		
			b->next = f->next;
			b->size += f->size;
			return;
		}

	}

	// Else, reinsert the block into the linked list

	if (prev == NULL)
		h->root = b;
	else	
		prev->next = b;
	b->next = f;

	h->n_blocks_allocated--;
	h->n_bytes_allocated -= b->size;

		
}

#ifdef TEST
void print_heap()
{

	struct heap* h = (struct heap*)_heap_start;
	struct heap_block* f = h->root;

	my_printf("Heap->root: %p size: %d %d\r\n", h->root, h->n_bytes_allocated, h->n_blocks_allocated);
	
	while (1)
	{
		my_printf("Block: %p (%d) %p -> %p %c\r\n", f, f->size, (uintptr_t)f + f->size, f->next, ((uintptr_t)f + f->size) == f->next ? '!' : ' ');

		if (f->next == NULL)
			break;

		f = f->next;
	}

}
#endif
