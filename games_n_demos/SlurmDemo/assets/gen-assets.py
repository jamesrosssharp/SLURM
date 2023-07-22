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
		          ("images_out/Blocks.png", "image", "blocks", 0x100),
			  ("tiled/SlurmTiledBG.tmx", "tilemap", "bg_tilemap", 0x10000),
			  ("images_out/SlurmBG256X256.png", "image_palette", "bg_tilemap_pal", 2),
		          ("images_out/SlurmSprite256x75.png", "image_palette", "slurm_sprite_pal", 2),
		          ("images_out/Blocks.png", "image_palette", "blocks_pal", 2),
		          ("images_out/rc-map-tiles.png", "image", "rc_map_tiles", 2),
		          ("images_out/Brick32.png", "image", "brick_texture", 2),
		          ("images_out/Brick32-2.png", "image", "brick_texture2", 2),
		          ("images_out/Brick32.png", "image_palette", "rc_pal", 2),
			  ("images_out/tunnel_distance_table.bin", "lut", "distance_table", 2),
			  ("images_out/tunnel_angle_table.bin", "lut", "angle_table", 2),
			  ("images_out/color_table.bin", "lut", "color_table", 2),
			  ("images_out/tunnel_shade_table.bin", "lut", "shade_table", 2),
			  ("images_out/texture2.png", "image", "tunnel_texture2", 2),
		          ("images_out/texture2.png", "image_palette", "tunnel_pal", 2),
			  
			],
	'bundle_load_address' : 1024*1024 + bundle_start,
}

assetman.build(options = options, build_directory = "../build", bundle_file = "../build/bundle.bin", bundle_header = "../build/bundle.h")


