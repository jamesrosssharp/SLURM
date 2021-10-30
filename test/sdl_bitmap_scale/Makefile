TARGET=sdl_vga

all: $(TARGET)

SRCS = sdl_vga_c.c

obj-y                   := $(addsuffix .o,$(basename $(SRCS)))

%.o: %.c Makefile
	gcc -c $< -o $@

$(TARGET):	$(obj-y)
	gcc $(obj-y) -o $@ -lSDL2 -lSDL2_image -lm 

run: $(TARGET)
	./$(TARGET)

clean:
	rm $(obj-y)
	rm sdl_vga
