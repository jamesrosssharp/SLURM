#
#

import struct
import os
import sys


# caution: path[0] is reserved for script path (or '' in REPL)
#sys.path.insert(1, '../../../slurmPyAssetManager')
sys.path.insert(1, '../../../')

import slurmPyAssetManager as assetman

bundle_start = 65536 - 0x200

options = {
	'bundle_start' : bundle_start,
	'bundle_files' : [("../build/demo.slurmsng", "chiptune", "demo_song", 0x100),
			  ("images_out/SlurmBG256X256.png", "image", "bg_tiles", 0x100),
		          ("images_out/SlurmSprite256x75.png", "image", "slurm_sprite", 0x100),
			  ("tiled/SlurmTiledBG.tmx", "tilemap", "bg_tilemap", 0x10000),
			  ("images_out/SlurmBG256X256.png", "image_palette", "bg_tilemap_pal", 2),
		          ("images_out/SlurmSprite256x75.png", "image_palette", "slurm_sprite_pal", 2),
			  ("../src/effect1/build/effect1.bin", "applet", "effect1_applet", 0x100),
			],
	'bundle_load_address' : 1024*1024 + bundle_start,
}

assetman.build(options = options, build_directory = "../build", bundle_file = "../build/bundle.bin", bundle_header = "../build/bundle.h")


