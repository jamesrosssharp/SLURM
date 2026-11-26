NAME = bloodlust

LEGACY_ASM = assets/assets.asm
BUNDLE     = assets/bundle.bin
EXTRA_DEPS = assets/frames.h

include ../game.mk

ASSETS_SRC = assets/Sprites.png assets/Tiles.png assets/Background.tmx assets/Background2.tmx

# gen-sprites.py builds sprites2.bin and frames.h; gen-assets.py builds the
# palettes and tile maps (assets.asm) and the bundle (sprites, tiles, sprites2).
assets/frames.h assets/sprites2.bin: assets/Sprites.png assets/gen-sprites.py
	cd assets; python3 gen-sprites.py

assets/assets.asm assets/bundle.bin: $(ASSETS_SRC) assets/gen-assets.py assets/sprites2.bin
	cd assets; python3 gen-assets.py
