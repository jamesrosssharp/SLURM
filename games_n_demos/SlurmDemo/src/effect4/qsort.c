/*

	SlurmDemo : A demo to show off SlURM16

qsort.c : implementation of Quick sort

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

#include "qsort.h"

#define swap(a, b)	{	\
	void* t = *(a);	\
	*(a) = *(b);	\
	*(b) = t;		\
}	

int partition(void** array, int low, int high, compare_func cfunc)
{

 // select the rightmost element as pivot
  void* pivot = array[high];
  
  // pointer for greater element
  int i = (low - 1);

  int j;

  // traverse each element of the array
  // compare them with the pivot
  for (j = low; j < high; j++) {
    if (cfunc(array[j], pivot) < 0) {
	
      // if element smaller than pivot is found
      // swap it with the greater element pointed by i
      i++;
      
      // swap element at i with element at j
      swap(&array[i], &array[j]);
    }
  }

  // swap the pivot element with the greater element at i
  swap(&array[i + 1], &array[high]);
  
  // return the partition point
  return (i + 1);

}

void qsort(void** array, int low, int high, compare_func cfunc, int depth)
{
	//if (depth > 10)
	//	return;

	if (low < high) {
    
		// find the pivot element such that
		// elements smaller than pivot are on left of pivot
		// elements greater than pivot are on right of pivot
		int pi = partition(array, low, high, cfunc);

		// recursive call on the left of pivot
		qsort(array, low, pi - 1, cfunc, depth + 1);

		// recursive call on the right of pivot
		qsort(array, pi + 1, high, cfunc, depth + 1);
	}
}
