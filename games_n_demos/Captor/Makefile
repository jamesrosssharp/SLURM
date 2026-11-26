NAME = captor

LEGACY_ASM = assets/assets.asm
BUNDLE     = assets/bundle.bin
EXTRA_DEPS = assets/frames.h assets/spawns.h assets/bundle.h

include ../game.mk

ASSETS_SRC = assets/sprites1.png assets/bg_tiles_256x256x16.png assets/Background.tmx \
	     assets/title.png assets/magnus.png assets/Ace1.png assets/Ace2.png

assets/assets.asm assets/bundle.bin assets/frames.h assets/spawns.h assets/bundle.h: $(ASSETS_SRC) assets/gen-assets.py
	cd assets; python3 gen-assets.py
