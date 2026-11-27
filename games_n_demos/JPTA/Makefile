NAME = jpta

BUNDLE     = assets/bundle.bin
EXTRA_DEPS = assets/level.h assets/john.h assets/kakadu.h

include ../game.mk

ASSETS_SRC = assets/level1.tmx assets/tiles1.tsx assets/tiles1.png assets/JohnSprites.png assets/KakaduEnemies.png

assets/bundle.bin assets/level.h assets/john.h assets/kakadu.h: $(ASSETS_SRC) assets/gen-assets.py assets/tmx2bg.py
	cd assets; python3 gen-assets.py
