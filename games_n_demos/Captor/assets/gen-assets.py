#!/usr/bin/env python3
#
#	gen-assets.py: build the assets for Captor.
#
#	Outputs
#	  sprites.bin   sprite sheet, 256x256 4bpp, packed from sprites1.png
#	                (with vertically flipped copies of the diving fighters)
#	  tiles.bin     tile set, 256x256 4bpp (bg_tiles_256x256x16.png, plus a
#	                few extra font glyphs)
#	  map1.map      the 64x1024 tile map (Background.tmx), one byte per tile
#	  title.bin, magnus.bin, ace1.bin, ace2.bin
#	                320 pixel wide pictures for the story screens
#	  bundle.bin    all of the above, placed in flash after the program
#	  bundle.h      flash (word) addresses of the bundle contents
#	  frames.h      sprite frames (parts lists and hit boxes)
#	  spawns.h      positions on the map for ground and sea targets
#	  assets.asm    palettes and the tile map buffers (legacy slurmasm)
#
#	Flash and memory layout: the flash image holds the program at offset 0
#	and the bundle at 65024 bytes (games_n_demos/game.mk). Flash word
#	address 0x80000 is the start of the image (the SPI flash DMA takes word
#	addresses). The boot loader copies the first 0xff00 words of the image to
#	memory word 0x100, which puts the sprite sheet at word 0x8000 and the tile
#	set at word 0xc000; the rest of the bundle is loaded by DMA when needed.
#

from PIL import Image, ImageDraw
from collections import Counter
import xml.etree.ElementTree as ET
import struct

FLASH_IMAGE_WORD = 0x80000
BUNDLE_OFFSET = 65024			# bytes, see game.mk
SPRITE_BASE = 0x8000			# word address of the sprite sheet
TILE_BASE = 0xc000			# word address of the tile set
MAX_PART_W = 64				# a hardware sprite is at most 64 pixels wide

#
#	Helpers
#

def pack4(img):
	"""4 bpp, 4 pixels per word, leftmost pixel in the low nibble."""
	px = img.load()
	out = bytearray()
	for y in range(img.height):
		for x in range(0, img.width, 4):
			w = 0
			for i in range(4):
				w |= (px[x + i, y] & 15) << (4 * i)
			out += struct.pack('<H', w)
	return out

def palette_asm(name, img, n=16, override=None):
	pal = img.getpalette() + [0] * 48
	s = "%s:\n" % name
	for i in range(n):
		r, g, b = pal[i * 3:i * 3 + 3]
		if override and i in override:
			r, g, b = override[i]
		s += "\tdw 0x%x%x%x%x\n" % (15, r >> 4, g >> 4, b >> 4)
	return s

#
#	Sprite sheet
#

src = Image.open("sprites1.png")
assert src.mode == "P"
spx = src.load()
sheet = Image.new("P", (256, 256), 0)
sheet.putpalette(src.getpalette())

def crop(x, y, w, h, seed=None):
	"""A rectangle of the original sheet. With seed, only the pixels
	connected to the seed pixel (8-connected) are kept."""
	img = src.crop((x, y, x + w, y + h))
	if seed is None:
		return img
	keep = set()
	stack = [seed]
	while stack:
		a, b = stack.pop()
		if (a, b) in keep or not (x <= a < x + w and y <= b < y + h) or spx[a, b] == 0:
			continue
		keep.add((a, b))
		stack += [(a + i, b + j) for i in (-1, 0, 1) for j in (-1, 0, 1)]
	ipx = img.load()
	for j in range(h):
		for i in range(w):
			if (x + i, y + j) not in keep:
				ipx[i, j] = 0
	return img

def vflip(img):
	return img.transpose(Image.FLIP_TOP_BOTTOM)

def hflip(img):
	return img.transpose(Image.FLIP_LEFT_RIGHT)

# Skyline packing, 4 pixel aligned: each frame goes as high up the sheet as
# it fits, tallest first. No gaps are needed between frames: the sprite
# hardware reads exactly the width and rows it is given.
skyline = [0] * 64	# first free row of each 4 pixel column
sheet_used = 0

def alloc(w, h):
	global sheet_used
	cols = (w + 3) // 4
	best = None
	for c in range(0, 64 - cols + 1):
		y = max(skyline[c:c + cols])
		if y + h <= 256 and (best is None or y < best[1]):
			best = (c, y)
	assert best is not None, "sprite sheet is full"
	c, y = best
	for i in range(c, c + cols):
		skyline[i] = y + h
	sheet_used = max(sheet_used, y + h)
	return c * 4, y

frames = []

def add_frame(name, img, hitbox=None, shrink=0, ox=0, width=None):
	"""Queue an image for the sheet; hitbox (x, y, w, h) relative to the
	frame (default: the image shrunk by 'shrink' on each side). With ox
	and width, the image is drawn ox pixels into a frame 'width' wide, so
	frames of different widths can share a position and hit box."""
	if hitbox is None:
		hitbox = (shrink, shrink, img.width - 2 * shrink, img.height - 2 * shrink)
	frames.append([name, img, hitbox, None, ox, width or img.width])

def pack_frames():
	"""Place the frames, tallest first, and make their parts lists."""
	def trimmed(f):
		"""The image without its empty margins, and where it was in it"""
		box = f[1].getbbox() or (0, 0, 1, 1)
		return f[1].crop(box), box[0], box[1]
	for f in sorted(frames, key=lambda f: (-trimmed(f)[0].height, -trimmed(f)[0].width)):
		img, tx, ty = trimmed(f)
		x, y = alloc(img.width, img.height)
		sheet.paste(img, (x, y))
		parts = []
		ox = 0
		while ox < img.width:
			pw = min(MAX_PART_W, img.width - ox)
			parts.append((SPRITE_BASE + y * 64 + (x + ox) // 4, pw, img.height,
				      f[4] + tx + ox, ty))
			ox += pw
		f[3] = parts

def bar(y, h):
	"""A 100 pixel long pipe from the 160 pixel ones: both ends, no middle."""
	img = Image.new("P", (100, h), 0)
	img.paste(crop(0, y, 50, h), (0, 0))
	img.paste(crop(110, y, 50, h), (50, 0))
	return img

# The player's plane: level, guns firing, and the frames of a barrel roll
add_frame("PLAYER", crop(24, 0, 35, 37), (11, 8, 13, 18))
add_frame("PLAYER_FIRE", crop(188, 0, 35, 37), (11, 8, 13, 18))
for i, (x, w) in enumerate([(60, 27), (88, 21), (112, 21), (136, 27), (164, 21), (0, 21)]):
	add_frame("PLAYER_ROLL%d" % (i + 1), crop(x, 0, w, 37), (w // 2 - 6, 8, 12, 18))

# Fighters: drawn nose up; flipped copies dive down the screen. The roll
# frames turn a diving fighter into a climbing one.
FIGHTER = [(56, 35), (92, 29), (124, 23), (24, 29), (0, 23)]
for i, (x, w) in enumerate(FIGHTER):
	add_frame("FIGHTER_DOWN%d" % i, vflip(crop(x, 37, w, 40)), (w // 2 - 10, 8, 20, 24))
for i, (x, w) in enumerate(FIGHTER):
	add_frame("FIGHTER_UP%d" % i, crop(x, 37, w, 40), (w // 2 - 10, 8, 20, 24))

# Planes that climb up from behind (their engines are at the bottom)
LEADER_HITBOX = (6, 6, 23, 26)
add_frame("LEADER", crop(152, 77, 35, 41), LEADER_HITBOX)
# The leader's barrel roll: banking over onto its back (x, width), then the
# same frames mirrored back to level. Each is drawn with its body (the
# middle of the tail, near the bottom) on the leader's.
LEADER_ROLL = [(136, 16), (124, 9), (112, 9), (101, 8), (89, 10), (72, 15), (48, 21), (24, 23)]
def body_x(img):
	ipx = img.load()
	xs = [x for x in range(img.width) if ipx[x, 37] != 0]
	return (min(xs) + max(xs) + 1) // 2
leader_body = body_x(crop(152, 77, 35, 41))
# (only the pixels joined to the tail: the sheet has strays above some)
roll = [crop(x, 77, w, 41) for (x, w) in LEADER_ROLL]
roll = [crop(x, 77, w, 41, seed=(x + body_x(img), 77 + 37)) for ((x, w), img) in zip(LEADER_ROLL, roll)]
roll += [hflip(img) for img in reversed(roll[:-1])]
for i, img in enumerate(roll):
	add_frame("LEADER_ROLL%d" % (i + 1), img, LEADER_HITBOX,
		  ox=leader_body - body_x(img), width=35)
add_frame("JET1", crop(40, 172, 34, 26), shrink=5)
add_frame("JET2", crop(76, 172, 34, 26), shrink=5)
add_frame("BOMBER", crop(112, 174, 36, 44), (4, 4, 28, 34))
# A flying wing that dives
add_frame("WING", crop(0, 170, 37, 30), shrink=6)

# Sea and ground targets
add_frame("GUNBOAT_L", crop(0, 200, 65, 25), shrink=3)
add_frame("GUNBOAT_R", hflip(crop(0, 200, 65, 25)), shrink=3)
add_frame("BATTLESHIP", crop(0, 230, 153, 26), (8, 3, 137, 20))
add_frame("BUNKER1", crop(176, 150, 50, 26), shrink=3)
add_frame("BUNKER2", crop(184, 174, 55, 28), shrink=3)
add_frame("BUNKER3", crop(184, 202, 54, 28), shrink=3)
add_frame("AAGUN", crop(220, 226, 20, 20), shrink=3)

# A worker escaping the sewage works (rescued for a power up)
add_frame("MAN1", crop(164, 145, 10, 12))
add_frame("MAN2", crop(164, 157, 10, 10))

# Explosion: a flash, a fireball, and a fading ring
add_frame("EXP1", crop(224, 0, 9, 9))
add_frame("EXP2", crop(236, 0, 19, 21))
add_frame("EXP3", crop(222, 12, 30, 32, seed=(236, 28)))
add_frame("RING1", crop(212, 40, 20, 22))
add_frame("RING2", crop(230, 40, 23, 22, seed=(240, 42)))

# Shots: the enemies' fireballs, and the player's tracer (drawn here)
add_frame("SHOT", crop(112, 216, 7, 7), shrink=1)
tracer = Image.new("P", (3, 10), 0)
for y in range(10):
	tracer.putpixel((1, y), 15 if y < 3 else 14)
	if 2 < y < 8:
		tracer.putpixel((0, y), 13)
		tracer.putpixel((2, y), 13)
add_frame("TRACER", tracer)

# Energy bar: an empty pipe, and a full one drawn over it to the energy left
add_frame("BAR_EMPTY", bar(118, 26))
add_frame("BAR_FULL", bar(145, 26))
pack_frames()

#
#	Tile set, with extra glyphs in free 8x8 cells of the font area
#

tiles = Image.open("bg_tiles_256x256x16.png")
assert tiles.mode == "P"
tpx = tiles.load()
FONT_Y = 208				# the font: 8x8 glyphs, from x = 32
FONT_COLOUR = 14

root = ET.parse("Background.tmx").getroot()
tmx = [int(v) - 1 for v in root.find("layer").find("data").text.replace("\n", "").split(",") if v.strip()]
MAP_W, MAP_H = 64, 1024
assert len(tmx) == MAP_W * MAP_H
used_tiles = set(t for t in tmx if t >= 0)

EXTRA_GLYPHS = {
	"'": ["...##...", "...##...", "..##....", "........", "........", "........", "........", "........"],
	":": ["........", "...##...", "...##...", "........", "........", "...##...", "...##...", "........"],
	",": ["........", "........", "........", "........", "........", "...##...", "...##...", "..##...."],
	"?": [".#####..", "##...##.", ".....##.", "...###..", "...##...", "........", "...##...", "........"],
}
# Extra glyphs go in the filler below the font (tiles the map never uses)
glyph_cells = {}
free = [(tx, ty) for ty in range(2, 6) for tx in range(32)
	if ((FONT_Y + ty * 8) // 16) * 16 + tx // 2 not in used_tiles]
for ch, rows in EXTRA_GLYPHS.items():
	tx, ty = free.pop(0)
	for j, row in enumerate(rows):
		for i, c in enumerate(row):
			tpx[tx * 8 + i, FONT_Y + ty * 8 + j] = FONT_COLOUR if c == '#' else 0
	glyph_cells[ch] = ty * 32 + tx

# Character -> 8x8 tile number, with the text layer's tile set address at
# the start of the font rows
charmap = {}
for i, ch in enumerate("ABCDEFGHIJKLMNOPQRSTUVWXYZ\""):
	charmap[ch] = 4 + i
for i, ch in enumerate("/-.0123456789!"):
	charmap[ch] = 32 + 4 + i
charmap.update(glyph_cells)

#
#	Map, and spawn points for ground targets (on land) and gunboats (on
#	open water), worked out from the colours of the tiles
#

def tile_colour(t):
	if t < 0:
		return None
	x0, y0 = (t % 16) * 16, (t // 16) * 16
	c, n = Counter(tpx[x0 + i, y0 + j] for i in range(16) for j in range(16)).most_common(1)[0]
	return c if n >= 230 else None	# nearly a single colour

WATER, GROUND, CONCRETE = 3, 4, 12
kind = [tile_colour(t) for t in tmx]

def block(col, row, w, h, colours):
	return all(0 <= col + i < MAP_W and 0 <= row + j < MAP_H and
		   kind[(row + j) * MAP_W + col + i] in colours
		   for i in range(w) for j in range(h))

spawns = []
last_row = MAP_H
row = MAP_H - 36
while row > 0:
	placed = False
	# a ground target where there is room for it
	for col in sorted(range(4, MAP_W - 8), key=lambda c: (c * 37 + row * 11) % MAP_W):
		if block(col, row, 4, 3, (GROUND, CONCRETE)):
			spawns.append((row, col, "GROUND"))
			placed = True
			break
	if not placed:
		for col in sorted(range(10, MAP_W - 16), key=lambda c: (c * 29 + row * 7) % MAP_W):
			if block(col, row - 1, 6, 4, (WATER,)):
				spawns.append((row, col, "BOAT"))
				placed = True
				break
	row -= 9 if placed else 3

#
#	Story pictures: 320 pixels wide, at most 204 rows (16384 words), so
#	that each fits in the sprite sheet's memory
#

def picture(name, rows=None):
	img = Image.open(name)
	assert img.mode == "P" and img.width == 320
	if rows:
		img = img.crop((0, rows[0], 320, rows[1]))
	assert img.height <= 204
	return img

title = picture("title.png", (18, 222))
# The logo: the font, four times the size, outlined in black
logo = "CAPTOR"
fx = [(charmap[c] % 32) * 8 for c in logo]
fy = [FONT_Y + (charmap[c] // 32) * 8 for c in logo]
S = 4
lw = len(logo) * 8 * S
lx, ly = (320 - lw) // 2, 14
tpix = title.load()
ink = set()
for k in range(len(logo)):
	for j in range(8):
		for i in range(8):
			if tpx[fx[k] + i, fy[k] + j]:
				for a in range(S):
					for b in range(S):
						ink.add((lx + (k * 8 + i) * S + a, ly + j * S + b))
for (x, y) in ink:
	for dx in (-2, -1, 0, 1, 2):
		for dy in (-2, -1, 0, 1, 2):
			if (x + dx, y + dy) not in ink and 0 <= x + dx < 320 and 0 <= y + dy < title.height:
				tpix[x + dx, y + dy] = 0
for (x, y) in ink:
	# yellow fading to orange
	tpix[x, y] = 15 if (y - ly) < S * 4 else 14

magnus = picture("magnus.png", (8, 212))
ace1 = picture("Ace1.png")
ace2 = picture("Ace2.png")

#
#	Output
#

def write(name, data):
	with open(name, "wb") as f:
		f.write(data)

def padded(data, size):
	assert len(data) <= size
	return bytes(data) + bytes(size - len(data))

write("sprites.bin", pack4(sheet))
write("tiles.bin", pack4(tiles))
mapdata = bytes(t if t >= 0 else 255 for t in tmx)
write("map1.map", mapdata)
for (n, img) in [("title", title), ("magnus", magnus), ("ace1", ace1), ("ace2", ace2)]:
	write(n + ".bin", pack4(img))
sheet.save("sprites_preview.png")

bundle = [
	("SPRITES", padded(pack4(sheet), 32768)),
	("TILES", padded(pack4(tiles), 32768)),
	("MAP", mapdata),
	("TITLE", padded(pack4(title), 32768)),
	("MAGNUS", padded(pack4(magnus), 32768)),
	("ACE1", padded(pack4(ace1), 32768)),
	("ACE2", padded(pack4(ace2), 32768)),
]
with open("bundle.bin", "wb") as f, open("bundle.h", "w") as h:
	h.write("/* Generated by gen-assets.py - do not edit */\n\n")
	h.write("#ifndef BUNDLE_H\n#define BUNDLE_H\n\n")
	h.write("/* Flash word addresses (for the SPI flash DMA) */\n")
	addr = FLASH_IMAGE_WORD + BUNDLE_OFFSET // 2
	for (name, data) in bundle:
		h.write("#define FLASH_%s\t0x%xUL\n" % (name, addr))
		f.write(data)
		addr += len(data) // 2
	h.write("\n#define MAP_W\t\t%d\n#define MAP_H\t\t%d\n" % (MAP_W, MAP_H))
	for (n, img) in [("TITLE", title), ("MAGNUS", magnus), ("ACE1", ace1), ("ACE2", ace2)]:
		h.write("#define %s_ROWS\t%d\n" % (n, img.height))
	h.write("\n/* The text layer's tile set: the font rows of the tile set */\n")
	h.write("#define FONT_TILESET\t0x%x\n" % (TILE_BASE + FONT_Y * 64))
	h.write("\n#endif\n")

with open("frames.h", "w") as h:
	h.write("/* Generated by gen-assets.py - do not edit */\n\n")
	h.write("#ifndef FRAMES_H\n#define FRAMES_H\n\n#include \"sprite_frame.h\"\n\n")
	for (name, img, hb, parts, ox, w) in frames:
		hh = img.height
		h.write("static const struct sprite_part %s_parts[] = {\n" % name.lower())
		for (a, pw, ph, dx, dy) in parts:
			h.write("\t{0x%04x, %d, %d, %d, %d},\n" % (a, pw, ph, dx, dy))
		h.write("};\nstatic const struct sprite_frame FRAME_%s = {%d, %s_parts, %d, %d, %d, %d, %d, %d};\n\n"
			% (name, len(parts), name.lower(), hb[0], hb[1], hb[2], hb[3], w, hh))
	h.write("/* Character -> text layer tile (see video.c) */\n")
	h.write("static const unsigned char FONT_MAP[96] = {\n\t")
	h.write(", ".join(str(charmap.get(chr(c), 255)) for c in range(32, 128)))
	h.write("\n};\n\n#endif\n")

with open("spawns.h", "w") as h:
	h.write("/* Generated by gen-assets.py - do not edit */\n\n")
	h.write("#ifndef SPAWNS_H\n#define SPAWNS_H\n\n")
	h.write("/* Ground and sea targets: map row and column of the top left corner,\n")
	h.write(" * from the bottom of the map up */\n")
	h.write("enum { SPAWN_GROUND, SPAWN_BOAT };\n")
	h.write("static const struct spawn { short row; unsigned char col, type; } SPAWNS[] = {\n")
	for (r, c, t) in spawns:
		h.write("\t{%d, %d, SPAWN_%s},\n" % (r, c, t))
	h.write("};\n#define N_SPAWNS %d\n\n#endif\n" % len(spawns))

with open("assets.asm", "w") as f:
	# colour 0 is transparent in sprites, but it is also the colour of the
	# screen where nothing is drawn: black
	f.write(palette_asm("sprites_palette", src, override={0: (0, 0, 0)}))
	# the silver squadron: the reds and browns of the fighters made grey
	f.write(palette_asm("silver_palette", src, override={
		0: (0, 0, 0), 2: (0x40, 0x40, 0x50), 3: (0x70, 0x70, 0x80), 5: (0x90, 0x90, 0xa0),
		6: (0xb0, 0xb0, 0xc0), 8: (0xa0, 0xa0, 0xb0), 11: (0xd0, 0xd0, 0xe0),
		12: (0xc0, 0xc0, 0xd0), 13: (0xe0, 0xe0, 0xf0)}))
	f.write(palette_asm("tiles_palette", tiles))
	f.write(palette_asm("text_palette", tiles, override={FONT_COLOUR: (255, 255, 255)}))
	f.write(palette_asm("title_palette", title))
	f.write(palette_asm("magnus_palette", magnus))
	f.write(palette_asm("ace1_palette", ace1))
	f.write(palette_asm("ace2_palette", ace2))
	f.write("\t.padto 0x8000\n\n")
	f.write("map_buf1:\n\t.times 64*32 db 0xff\n")
	f.write("map_buf2:\n\t.times 64*32 db 0xff\n")
	f.write("text_map:\n\t.times 128*60 db 0xff\n")

print("sprites: %d frames, sheet used to y=%d; %d spawns; glyphs %s" %
      (len(frames), sheet_used, len(spawns), glyph_cells))
