NAME = bloodlust

LEGACY_ASM = assets/assets.asm
BUNDLE     = assets/bundle.bin

include ../game.mk

ASSETS_SRC = assets/Sprites.png assets/Tiles.png assets/Background.tmx assets/Background2.tmx

assets/assets.asm: $(ASSETS_SRC) assets/gen-assets.py
	cd assets; python3 gen-assets.py
