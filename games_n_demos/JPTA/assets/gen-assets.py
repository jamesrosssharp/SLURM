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
#	                the enemies, power ups and digits   loaded by DMA at the
#	                from KakaduEnemies.png at 5 bpp     start to KAKADU_RAM
#	  level.h     the two background maps (see tmx2bg.py), the tile palette
#	              and the collision tables
#	  john.h      John's frames: flash address, size and palette
#	  kakadu.h    the enemy and power up frames: where they are and their size
#
#	The bottom 64 rows of the second tile set (tiles 448-511) are left free
#	for John: the program copies the frame on show there by DMA. The
#	KakaduEnemies.png frames go in the top half of the program's memory
#	(words 0x4000-0x7fff), which the program doesn't use.
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
#	Collision: each tile is a 4x4 grid of 4x4 pixel blocks, solid where
#	at least half the pixels are. Sky and the cave background are open; so
#	are the trees and bushes, which are only decoration, and the ladders
#	(the floor at the foot of a ladder is the tile below it).
#

def gids(*ranges):
	out = set()
	for r in ranges:
		out |= set(range(r[0], r[1] + 1)) if isinstance(r, tuple) else {r}
	return {g - 1 for g in out}

OPEN = gids(1, 2, 17, 18, 109, 110, 125, 126, 134, 135, 150, 151, 205, 206, 221, 222,
	       (385, 392), (401, 406), (417, 448))
LADDERS = gids((291, 298), 303, 304, (307, 314), 319, 320, (397, 400), (413, 416))
OPEN |= LADDERS

pal = tiles.getpalette()
def colour(i):
	return pal[3 * i], pal[3 * i + 1], pal[3 * i + 2]
def is_open(i):
	r, g, b = colour(i)
	return (b > r + 60 and b > g + 60) or r + g + b < 100	# sky, or dark: the cave

tpx = tiles.load()
tile_mask = []
for t in range(512):
	mask = 0
	if t not in OPEN and (t // 16) * 16 < tiles.height:
		for by in range(4):
			for bx in range(4):
				n = sum(1 for y in range(4) for x in range(4)
					if not is_open(tpx[(t % 16) * 16 + bx * 4 + x, (t // 16) * 16 + by * 4 + y]))
				if n >= 8:
					mask |= 1 << (by * 4 + bx)
	tile_mask.append(mask)
ladder_bits = [0] * 32
for t in LADDERS:
	ladder_bits[t // 16] |= 1 << (t % 16)

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
#	Enemies and power ups: frames cut from KakaduEnemies.png, which has
#	them packed close together, some touching. Most frames are the biggest
#	shape in a rectangle (plus shapes wholly inside it); where neighbours
#	touch, the whole rectangle. They are packed again, three pixels to a
#	word, into a sheet 64 words (192 pixels) wide like the original, the
#	sprites' 256 nibble stride.
#

KAKADU_RAM = 0x4000		# word address
KAKADU_ROWS = 256		# the most that fits, to 0x7fff

kak = Image.open("KakaduEnemies.png")
assert kak.mode == "P"
kpx = kak.load()

def kshapes(x0, y0, w, h):
	seen, out = set(), []
	for y in range(y0, y0 + h):
		for x in range(x0, x0 + w):
			if kpx[x, y] == 0 or (x, y) in seen:
				continue
			g, todo = set(), [(x, y)]
			seen.add((x, y))
			while todo:
				a, b = todo.pop()
				g.add((a, b))
				for dx in (-1, 0, 1):
					for dy in (-1, 0, 1):
						q = (a + dx, b + dy)
						if (x0 <= q[0] < x0 + w and y0 <= q[1] < y0 + h and q not in seen
						    and kpx[q] != 0):
							seen.add(q)
							todo.append(q)
			out.append(g)
	return out

def kcut(x0, y0, w, h, plain):
	if plain:
		keep = {(x, y) for y in range(y0, y0 + h) for x in range(x0, x0 + w) if kpx[x, y]}
	else:
		gs = kshapes(x0, y0, w, h)
		big = max(gs, key=len)
		keep = set(big)
		for g in gs:
			if g is not big and all(x0 < x < x0 + w - 1 and y0 < y < y0 + h - 1 for x, y in g):
				keep |= g
	bx = min(x for x, _ in keep)
	by = min(y for _, y in keep)
	f = [[0] * (max(x for x, _ in keep) - bx + 1) for _ in range(max(y for _, y in keep) - by + 1)]
	for x, y in keep:
		f[y - by][x - bx] = kpx[x, y]
	return f

DIGIT_X = [0, 12, 21, 32, 44, 59, 71, 83, 95, 108]
COIN_X = [0, 17, 29, 33, 46, 63, 75]
HEART_X = [0, 16, 34, 50, 64, 76]
KFRAMES = [
	# name, rectangle (x, y, w, h), whole rectangle (for frames touching their neighbours)
	("FLYER_R0", (0, 0, 57, 51), 0), ("FLYER_R1", (57, 2, 56, 48), 0),	# radioactive wombats
	("FLYER_L0", (1, 146, 56, 47), 0), ("FLYER_L1", (57, 143, 57, 50), 0),
	("WOMBAT_R", (113, 0, 55, 34), 0), ("WOMBAT_L", (113, 142, 53, 36), 0),
	("BIRD_R_GLIDE", (0, 103, 36, 31), 0), ("BIRD_R_UP", (36, 103, 33, 41), 0),
	("BIRD_R_CURL", (69, 103, 31, 40), 0), ("BIRD_L_CURL", (102, 103, 31, 40), 0),
	("BIRD_L_UP", (132, 103, 34, 41), 0), ("BIRD_L_GLIDE", (144, 63, 37, 31), 0),
] + [("COIN%d" % i, (COIN_X[i], 208, COIN_X[i + 1] - COIN_X[i], 16), 1) for i in range(6)] \
  + [("HEART%d" % i, (HEART_X[i], 193, HEART_X[i + 1] - HEART_X[i], 15), 1) for i in range(5)] + [
	("STAR0", (166, 99, 25, 19), 0), ("STAR1", (166, 119, 15, 21), 0),
	("STAR2", (180, 119, 10, 20), 0), ("STAR3", (166, 139, 15, 21), 0),
	("PUFF0", (93, 207, 20, 21), 0), ("PUFF1", (113, 208, 19, 22), 0),
	("PUFF2", (132, 209, 19, 16), 0), ("PUFF3", (151, 209, 19, 12), 0),
	("SHOT0", (108, 229, 9, 9), 1), ("SHOT1", (117, 229, 11, 11), 1), ("SHOT2", (128, 228, 12, 11), 1),
] + [("DIGIT%d" % i, (DIGIT_X[i], 225, DIGIT_X[i + 1] - DIGIT_X[i], 14), 1) for i in range(9)] \
  + [("DIGIT9", (0, 240, 11, 14), 1)]

kframes = [(name, kcut(*r, plain)) for name, r, plain in KFRAMES]

# Shelf packing, tallest first, each frame starting on a word (3 pixels)
SHEET_W = 192
kplace = {}
shelf_y, shelf_h, cur_x = 0, 0, 0
for name, f in sorted(kframes, key=lambda nf: -len(nf[1])):
	fw, fh = len(f[0]), len(f)
	ww = (fw + 2) // 3 * 3
	if cur_x + ww > SHEET_W:
		shelf_y += shelf_h
		shelf_h, cur_x = 0, 0
	kplace[name] = (cur_x, shelf_y)
	cur_x += ww
	shelf_h = max(shelf_h, fh)
krows = shelf_y + shelf_h
if krows > KAKADU_ROWS:
	tmx2bg.fail("the enemy frames need %d rows, more than %d" % (krows, KAKADU_ROWS))
ksheet = [[0] * SHEET_W for _ in range(krows)]
for name, f in kframes:
	x0, y0 = kplace[name]
	for y, row in enumerate(f):
		ksheet[y0 + y][x0:x0 + len(row)] = row
kak_data = []
for row in ksheet:
	for x in range(0, SHEET_W, 3):
		kak_data.append(row[x] | row[x + 1] << 5 | row[x + 2] << 10)

#
#	Bundle and headers
#

bundle = tmx2bg.pack4(tiles, 0) + tmx2bg.pack4(tiles, 256)
john_offset = len(bundle)
for v in john_data:
	bundle += bytes((v & 0xff, v >> 8))
kak_offset = len(bundle)
for v in kak_data:
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
	f.write("\n/* Collision, for tiles 0-511: bit (y * 4 + x) is set where the 4x4 pixel\n")
	f.write(" * block x, y of the tile is solid */\n")
	f.write(c_array("tile_solid", tile_mask))
	f.write("\n/* Ladders: bit (t %% 16) of word t / 16 is set for a ladder tile t; the\n")
	f.write(" * left hand tile of each ladder is the even one */\n")
	f.write(c_array("tile_ladder", ladder_bits))

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
	f.write("\n/* The same, half way to white: for flashing while he has a star */\n")
	bright = []
	for c in rgb444(john, 32):
		ch = [(c >> k) & 15 for k in (8, 4, 0)]
		ch = [v + (15 - v + 1) // 2 for v in ch]
		bright.append(ch[0] << 8 | ch[1] << 4 | ch[2])
	f.write(c_array("john_bright_palette", bright))

with open("kakadu.h", "w") as f:
	f.write("/* kakadu.h: generated from KakaduEnemies.png by gen-assets.py, do not edit */\n\n")
	f.write("/* The frames, at 5 bpp in rows 64 words apart: copy KAKADU_WORDS words\n")
	f.write(" * from flash at KAKADU_FLASH to KAKADU_RAM (word addresses) */\n")
	f.write("#define KAKADU_FLASH\t0x%xUL\n" % (FLASH_IMAGE_WORD + (BUNDLE_OFFSET + kak_offset) // 2))
	f.write("#define KAKADU_RAM\t0x%04x\n" % KAKADU_RAM)
	f.write("#define KAKADU_WORDS\t%d\n\n" % len(kak_data))
	f.write("struct kframe {\n\tunsigned short addr;\t/* word address of the top left corner */\n")
	f.write("\tshort w, h;\t\t/* pixels */\n};\n\n")
	f.write("enum {\n")
	for name, _ in kframes:
		f.write("\tK_%s,\n" % name)
	f.write("\tK_FRAMES\n};\n\n")
	f.write("static const struct kframe kframes[K_FRAMES] = {\n")
	for name, fr in kframes:
		x0, y0 = kplace[name]
		f.write("\t{ 0x%04x, %2d, %2d },\t/* %s */\n" % (KAKADU_RAM + y0 * 64 + x0 // 3, len(fr[0]), len(fr), name))
	f.write("};\n\n")
	f.write("/* 0xRGB, 4 bits a channel; colour 0 is see-through */\n")
	f.write(c_array("kakadu_palette", rgb444(kak, 32)))
