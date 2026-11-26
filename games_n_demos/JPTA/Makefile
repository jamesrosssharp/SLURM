NAME = jpta

LEGACY_ASM = assets/assets.asm
BUNDLE     = assets/bundle.bin

include ../game.mk

ASSETS_SRC = assets/JohnSprites.png

assets/assets.asm: $(ASSETS_SRC) assets/gen-assets.py
	cd assets; python3 gen-assets.py
