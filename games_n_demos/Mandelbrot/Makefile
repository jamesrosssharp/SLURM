NAME = mandelbrot

LEGACY_ASM = assets/assets.asm

include ../game.mk

ASSETS_SRC = assets/Palette.png

assets/assets.asm: $(ASSETS_SRC) assets/gen-assets.py
	cd assets; python3 gen-assets.py
