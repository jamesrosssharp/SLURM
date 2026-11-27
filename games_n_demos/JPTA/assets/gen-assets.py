#!/usr/bin/env python3
#
#	gen-assets.py: build the assets for JPTA.
#
#	Outputs
#	  bundle.bin  placed in flash after the program, at byte 65024
#	              (games_n_demos/game.mk):
#	                tiles 0-255 at 4 bpp (32K bytes)    copied by the boot
#	                tiles 256-511 at 4 bpp (32K bytes)  loader to memory words
#	                                                    0x8000 and 0xc000
#	                John's frames at 5 bpp              left in flash, loaded
#	                                                    by DMA when needed
#	  level.h     the two background maps (see tmx2bg.py) and the tile palette
#	  john.h      John's frames: flash address, size and palette
#
#	The bottom 64 rows of the second tile set (tiles 448-511) are left free
#	for John: the program copies the frame on show there by DMA.
#

import os
import sys
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import tmx2bg

FLASH_IMAGE_WORD = 0x80000		# flash word address of the image
BUNDLE_OFFSET = 65024			# bytes, see game.mk
TILESET0 = 0x8000
TILESET1 = 0xc000
FIRST_SPRITE_TILE = 448			# tiles from here on are John's
SPRITE_RAM = TILESET1 + (FIRST_SPRITE_TILE - 256) // 16 * 16 * 64
STRIDES = {256: 0, 128: 1, 64: 2, 32: 3}	# map width -> layer stride code

def words(data):
	"""Bytes to little endian words: the hardware takes the even byte from bits 7:0."""
	return [data[i] | (data[i + 1] << 8) for i in range(0, len(data), 2)]

def c_array(name, values, per_line=16, ctype="unsigned short"):
	s = "static const %s %s[%d] = {\n" % (ctype, name, len(values))
	for i in range(0, len(values), per_line):
		s += "\t" + ", ".join("0x%04x" % v for v in values[i:i + per_line]) + ",\n"
	return s + "};\n"

def rgb444(img, n):
	pal = img.getpalette()[:3 * n]
	pal += [0] * (3 * n - len(pal))
	return [(pal[i] >> 4) << 8 | (pal[i + 1] >> 4) << 4 | (pal[i + 2] >> 4) for i in range(0, 3 * n, 3)]

#
#	The level
#

w, h, firstgid, tsx, layers = tmx2bg.load_map("level1.tmx")
if w not in STRIDES:
	tmx2bg.fail("the map must be 32, 64, 128 or 256 tiles wide, not %d" % w)
tiles = tmx2bg.tileset_image(tsx)
for name, gids in layers:
	for i, gid in enumerate(gids):
		if gid and gid - firstgid >= FIRST_SPRITE_TILE:
			tmx2bg.fail("layer '%s' x=%d y=%d: tiles %d and up are kept for John's sprite"
				    % (name, i % w, i // w, FIRST_SPRITE_TILE))
bg = tmx2bg.split(w, h, firstgid, layers, tiles)

#
#	John: the frames are cut from JohnSprites.png, which has them in rows
#	about 43 pixels apart and 30-33 pixels across, close enough that a
#	rectangle around one catches bits of its neighbours. So each frame is
#	the connected shapes nearest the middle of its cell.
#

JOHN_W = 33			# pixels; 11 words at 5 bpp (3 pixels a word)
JOHN_H = 43
JOHN_WORDS = JOHN_W // 3

john = Image.open("JohnSprites.png")
assert john.mode == "P"
jpx = john.load()

def shapes(y0, y1):
	"""Connected (8-way) groups of non-zero pixels in rows y0-y1: [set of (x, y)]"""
	seen = set()
	out = []
	for y in range(y0, y1):
		for x in range(john.width):
			if jpx[x, y] == 0 or (x, y) in seen:
				continue
			group, todo = set(), [(x, y)]
			seen.add((x, y))
			while todo:
				px, py = todo.pop()
				group.add((px, py))
				for dx in (-1, 0, 1):
					for dy in (-1, 0, 1):
						q = (px + dx, py + dy)
						if (0 <= q[0] < john.width and y0 <= q[1] < y1 and q not in seen
						    and jpx[q] != 0):
							seen.add(q)
							todo.append(q)
			out.append(group)
	return out

def cut_row(y0, y1):
	"""The frames in one row of the sheet, left to right, each JOHN_W x JOHN_H
	with the figure at the left and its feet on the bottom row."""
	groups = shapes(y0, y1)
	bodies = sorted((g for g in groups if len(g) > 100), key=lambda g: min(x for x, _ in g))
	centre = [sum(x for x, _ in g) / len(g) for g in bodies]
	members = [set(g) for g in bodies]
	for g in groups:
		if len(g) <= 100:
			cx = sum(x for x, _ in g) / len(g)
			members[min(range(len(bodies)), key=lambda k: abs(centre[k] - cx))] |= g
	frames = []
	for g in members:
		x0 = min(x for x, _ in g)
		x1 = max(x for x, _ in g)
		if x1 - x0 + 1 > JOHN_W:
			tmx2bg.fail("a frame in rows %d-%d is %d pixels wide, more than %d"
				    % (y0, y1, x1 - x0 + 1, JOHN_W))
		dy = JOHN_H - (y1 - y0)
		f = [[0] * JOHN_W for _ in range(JOHN_H)]
		for x, y in g:
			f[y - y0 + dy][x - x0] = jpx[x, y]
		frames.append(f)
	return frames

rows = [cut_row(0, 43), cut_row(43, 86), cut_row(86, 128)]
walk = rows[0][0:6] + rows[1][0:2]		# the walk cycle
stand = rows[2][2]
right = walk + [stand]
left = [[r[::-1] for r in f] for f in right]	# the hardware can't flip: mirror here
john_frames = right + left

def pack5(f):
	"""5 bpp, three pixels a word in bits 4:0, 9:5, 14:10, leftmost first."""
	out = []
	for row in f:
		for x in range(0, JOHN_W, 3):
			out.append(row[x] | row[x + 1] << 5 | row[x + 2] << 10)
	return out

john_data = []
for f in john_frames:
	john_data += pack5(f)

#
#	Bundle and headers
#

bundle = tmx2bg.pack4(tiles, 0) + tmx2bg.pack4(tiles, 256)
john_offset = len(bundle)
for v in john_data:
	bundle += bytes((v & 0xff, v >> 8))
with open("bundle.bin", "wb") as f:
	f.write(bundle)

with open("level.h", "w") as f:
	f.write("/* level.h: generated from level1.tmx by gen-assets.py, do not edit */\n\n")
	f.write("#define LEVEL_W\t\t%d\t/* tiles */\n" % w)
	f.write("#define LEVEL_H\t\t%d\n" % h)
	f.write("#define LEVEL_STRIDE\t%d\t/* layer stride code for LEVEL_W */\n" % STRIDES[w])
	f.write("#define TILESET0\t0x%04x\t/* word address of tiles 0-255 */\n" % TILESET0)
	f.write("#define TILESET1\t0x%04x\t/* word address of tiles 256-511 */\n\n" % TILESET1)
	f.write("/* 0xRGB, 4 bits a channel */\n")
	f.write(c_array("tiles_palette", rgb444(tiles, 16)))
	f.write("\n/* One byte per tile, row by row, 0xff where the other background has the tile */\n")
	f.write(c_array("level_bg0", words(bg[0])))
	f.write(c_array("level_bg1", words(bg[1])))

with open("john.h", "w") as f:
	f.write("/* john.h: generated from JohnSprites.png by gen-assets.py, do not edit */\n\n")
	f.write("/* Frames of JOHN_W x JOHN_H pixels at 5 bpp, JOHN_WORDS words a row,\n")
	f.write(" * one after another in flash from JOHN_FLASH (a word address) */\n")
	f.write("#define JOHN_FLASH\t0x%xUL\n" % (FLASH_IMAGE_WORD + (BUNDLE_OFFSET + john_offset) // 2))
	f.write("#define JOHN_W\t\t%d\n" % JOHN_W)
	f.write("#define JOHN_H\t\t%d\n" % JOHN_H)
	f.write("#define JOHN_WORDS\t%d\n" % JOHN_WORDS)
	f.write("#define JOHN_FRAME_WORDS\t%d\n\n" % (JOHN_WORDS * JOHN_H))
	f.write("/* Frames: the walk cycle then standing, facing right, then the same facing left */\n")
	f.write("#define JOHN_WALK\t0\n#define JOHN_WALK_FRAMES\t%d\n" % len(walk))
	f.write("#define JOHN_STAND\t%d\n" % len(walk))
	f.write("#define JOHN_LEFT\t%d\t/* add to face left */\n" % len(right))
	f.write("#define JOHN_FRAMES\t%d\n\n" % len(john_frames))
	f.write("/* Video memory for frames on show (tiles 448-511 of the tile set): rows\n")
	f.write(" * 64 words apart, the sprite's 256 nibble stride */\n")
	f.write("#define SPRITE_RAM\t0x%04x\n\n" % SPRITE_RAM)
	f.write("/* 0xRGB, 4 bits a channel; colour 0 is see-through */\n")
	f.write(c_array("john_palette", rgb444(john, 32)))
