all: malloc_test

malloc_test: malloc_test.c ../malloc.c ../malloc.h
	gcc -ggdb -I../ -DTEST -o malloc_test malloc_test.c ../malloc.c 

clean:
	rm malloc_test
