NAME = chiptunemem

LEGACY_ASM = assets/assets.asm
BUNDLE     = assets/bundle.bin
EXTRA_DEPS = assets/bundle.h

include ../game.mk

assets/chiptune.slurmsng: assets/chiptune.it
	python3 assets/it2slurmsng.py assets/chiptune.it assets/chiptune.slurmsng

assets/assets.asm assets/bundle.bin assets/bundle.h: assets/chiptune.slurmsng assets/gen-assets.py
	cd assets; python3 gen-assets.py
