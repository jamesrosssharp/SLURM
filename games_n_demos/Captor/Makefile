NAME = captor

LEGACY_ASM = assets/assets.asm
BUNDLE     = assets/bundle.bin

include ../game.mk

ASSETS_SRC = assets/sprites1.png assets/bg_tiles_256x256x16.png assets/Background.tmx assets/bg_tiles.tsx

assets/assets.asm assets/bundle.bin: $(ASSETS_SRC) assets/gen-assets.py
	cd assets; python3 gen-assets.py
