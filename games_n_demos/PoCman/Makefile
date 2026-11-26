NAME = pocman

# pocman_sound.c and pocman_title.c are #included by main.c
C_SRC      = src/main.c
EXTRA_DEPS = src/pocman_sound.c src/pocman_title.c

LEGACY_ASM = assets/assets.asm
BUNDLE     = assets/bundle.bin

include ../game.mk

ASSETS_SRC = assets/sprites.png assets/bg_tiles.png assets/background.tmx

assets/assets.asm: $(ASSETS_SRC) assets/gen-assets.py
	cd assets; python3 gen-assets.py
