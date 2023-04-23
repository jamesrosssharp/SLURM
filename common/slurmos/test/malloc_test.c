#include <stdio.h>
#include <malloc.h>
#include <stdlib.h>
#include <string.h>

int main(int argc, char** argv)
{
	void *ptrs[32] = {0};


	my_init_heap();

	print_heap();	


	for (int i = 0; i < 1024; i ++)
	{
		int d = rand() % 64;
		int idx = d % 32;

		if (d >= 32)
		{
			// Malloc ?			

			if (ptrs[idx] == 0)
			{
				int size = rand() % 1024;
				ptrs[idx] = my_malloc(size);

				if (ptrs[idx])
				{
					memset(ptrs[idx], 0, size);
				}
			}

		}
		else
		{
			// Free ?
			
			if (ptrs[idx])
			{
				my_free(ptrs[idx]);
				ptrs[idx] = 0;
			}

		}
		printf("=================");
		print_heap();

	}

	for (int i = 0; i < 32; i++)
	{
		if (ptrs[i])
		{
			my_free(ptrs[i]);
			printf("-------------");
			print_heap();
		}

	}

}
