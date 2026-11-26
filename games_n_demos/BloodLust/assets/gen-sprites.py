#!/usr/bin/env python3
#
#	gen-sprites.py: build the second sprite sheet (sprites2.bin) and the
#	sprite frame table (frames.h) for BloodLust.
#
#	Sprite sheets are 256 pixel wide, 4 bpp images in video memory:
#
#	  Sprites.png   -> word 0x8000 (spritesheet)
#	  Tiles.png     -> word 0xc000 (tileset)
#	  sprites2.bin  -> word 0xe000 (generated here)
#
#	The boot loader copies the program and the bundle that follows it in
#	flash to memory starting at word 0x100, which puts the bundle at word
#	0x8000.
#
#	sprites2 holds what the original sheet lacks: mirrored copies of sprites
#	that face the wrong way (the game scrolls to the left), a font, the
#	pre-rendered text used by the game, and small particles.
#
#	A hardware sprite is at most 63 pixels wide and starts on a 4 pixel
#	boundary, so every frame is described as a list of parts, each at most
#	60 pixels wide.
#

from PIL import Image
import struct

SHEET1_BASE = 0x8000
SHEET2_BASE = 0xe000
MAX_PART_W = 60

src = Image.open("Sprites.png")
assert src.mode == "P"
sheet2 = Image.new("P", (256, 128), 0)
sheet2.putpalette(src.getpalette())

# Palette indices (see Sprites.png)
RED, ORANGE, YELLOW, WHITE, DARK = 8, 12, 14, 15, 2

#
#	Frames: name -> list of parts (sheet, x, y, w, h, dx, dy), plus a hitbox
#

frames = []

def add_frame(name, parts, hitbox=None):
	"""parts: list of (sheet, x, y, w, h, dx, dy) with x, w multiples of 4"""
	if hitbox is None:
		x0 = min(p[5] for p in parts)
		y0 = min(p[6] for p in parts)
		x1 = max(p[5] + p[3] for p in parts)
		y1 = max(p[6] + p[4] for p in parts)
		hitbox = (x0, y0, x1 - x0, y1 - y0)
	frames.append((name, parts, hitbox))

def rect_parts(sheet, x, y, w, h, dx=0, dy=0):
	"""Split a rectangle of a sheet into 4 pixel aligned parts <= 60 wide."""
	ax = x & ~3
	aw = ((x + w + 3) & ~3) - ax
	parts = []
	ox = 0
	while ox < aw:
		pw = min(MAX_PART_W, aw - ox)
		parts.append((sheet, ax + ox, y, pw, h, dx + ox - (x - ax), dy))
		ox += pw
	return parts

def add_rect(name, sheet, x, y, w, h, hitbox_shrink=0):
	parts = rect_parts(sheet, x, y, w, h)
	s = hitbox_shrink
	add_frame(name, parts, (s, s, w - 2 * s, h - 2 * s))

#
#	sheet2 allocator: simple shelf packing
#

shelf = {"x": 0, "y": 0, "h": 0}

def alloc(w, h):
	w = (w + 3) & ~3
	if shelf["x"] + w > 256:
		shelf["x"] = 0
		shelf["y"] += shelf["h"]
		shelf["h"] = 0
	x, y = shelf["x"], shelf["y"]
	assert y + h <= 128, "sprites2 sheet is full"
	shelf["x"] += w
	shelf["h"] = max(shelf["h"], h)
	return x, y

def place(img, name, hitbox_shrink=0):
	x, y = alloc(img.width, img.height)
	sheet2.paste(img, (x, y))
	add_rect(name, 2, x, y, img.width, img.height, hitbox_shrink)

def crop(x, y, w, h):
	return src.crop((x, y, x + w, y + h))

def mirror(img):
	return img.transpose(Image.FLIP_LEFT_RIGHT)

#
#	Sheet 1 frames (original art)
#

add_rect("BUG", 1, 2, 0, 18, 14, 2)
add_rect("BOOMERANG", 1, 34, 0, 14, 13, 2)
add_rect("ORB", 1, 145, 34, 19, 23, 5)
add_rect("DRAGON1", 1, 120, 1, 71, 30, 6)
add_rect("DRAGON2", 1, 195, 1, 61, 31, 6)
add_rect("DRAGON3", 1, 177, 33, 66, 26, 6)
add_rect("GIANT1", 1, 0, 32, 30, 55, 4)
add_rect("GIANT2", 1, 34, 32, 27, 54, 4)
add_rect("GIANT3", 1, 65, 32, 37, 55, 4)
# Digits 0-9 (y = 97, x as drawn)
digit_x = [1, 18, 33, 50, 65, 82, 98, 112, 132, 147]
digit_w = [9, 5, 9, 8, 9, 8, 8, 10, 6, 8]

# Lightning bolts: the demon's lightning strike (exact bounds of the art)
BOLTS = [(116, 66, 115, 28), (114, 117, 62, 26), (112, 150, 47, 25)]

def in_bolt(x, y):
	return any(bx <= x < bx + bw and by <= y < by + bh for (bx, by, bw, bh) in BOLTS)

def clean_parts(x, y, w, h, own):
	"""Parts covering the pixels of a sheet 1 rectangle for which own(x, y)
	is true, and no other (non transparent) pixels. Rows are grouped into
	bands; a new band starts where widening the band to the next row would
	take in a foreign pixel."""
	px = src.load()
	def row_range(r):
		xs = [c for c in range(x, x + w) if px[c, r] and own(c, r)]
		return (min(xs) & ~3, (max(xs) + 4) & ~3) if xs else None
	def clean(x0, x1, r0, r1):
		return not any(px[c, r] and not own(c, r)
			       for r in range(r0, r1) for c in range(x0, min(x1, 256)))
	parts = []
	band = None		# [x0, x1, first row, end row]
	def flush():
		if band:
			parts.extend(rect_parts(1, band[0], band[2], band[1] - band[0],
						band[3] - band[2], band[0] - x, band[2] - y))
	for r in range(y, y + h):
		rr = row_range(r)
		if rr is None:
			continue
		if band:
			x0, x1 = min(band[0], rr[0]), max(band[1], rr[1])
			if band[3] == r and clean(x0, x1, band[2], r + 1):
				band[0], band[1], band[3] = x0, x1, r + 1
				continue
			flush()
		assert clean(rr[0], rr[1], r, r + 1), "foreign pixels inside a row at %d" % r
		band = [rr[0], rr[1], r, r + 1]
	flush()
	return parts

for i, (bx, by, bw, bh) in enumerate(BOLTS):
	add_frame("LIGHTNING%d" % (i + 1), clean_parts(bx, by, bw, bh, in_bolt),
		  (0, 8, bw, bh - 16))

# Demon boss: everything in its box except the lightning bolts drawn beside
# and above its arm
not_bolt = lambda x, y: not in_bolt(x, y)
add_frame("DEMON_IDLE", clean_parts(160, 117, 96, 139, not_bolt), (24, 10, 56, 70))
add_frame("DEMON_ATTACK", clean_parts(0, 113, 152, 143, not_bolt), (60, 10, 60, 70))

#
#	Sheet 2 frames (generated)
#

# The game scrolls to the left. The player's jet already faces left; its
# bolt is mirrored to match.
place(crop(82, 0, 30, 11), "PLAYER", 3)
place(mirror(crop(113, 39, 19, 8)), "BOLT", 0)
# The enemy airship faces right, flying with the dragons.
place(crop(55, 3, 24, 22), "AIRSHIP", 4)

# Digits, copied into 12 pixel cells so they can be drawn one per sprite
for d in range(10):
	cell = Image.new("P", (12, 12), 0)
	cell.paste(crop(digit_x[d], 97, digit_w[d], 12), ((12 - digit_w[d]) // 2, 0))
	place(cell, "DIGIT%d" % d)

# Embers: small glowing particles for the foreground parallax layer
for i, (a, b) in enumerate([(YELLOW, ORANGE), (ORANGE, RED), (WHITE, YELLOW)]):
	e = Image.new("P", (4, 4), 0)
	for (px, py) in [(1, 0), (0, 1), (2, 1), (1, 2), (2, 2), (1, 1)]:
		e.putpixel((px, py), b)
	e.putpixel((1, 1), a)
	place(e, "EMBER%d" % i)

# Small jet icon for the lives display (every other pixel of the player)
icon = crop(82, 0, 30, 11).resize((15, 6), Image.NEAREST)
place(icon, "LIFE")

#
#	Font: 5x7 glyphs, drawn 2x, with the fire colours of the digits
#

GLYPHS = {
	'A': ["01110", "10001", "10001", "11111", "10001", "10001", "10001"],
	'B': ["11110", "10001", "10001", "11110", "10001", "10001", "11110"],
	'C': ["01110", "10001", "10000", "10000", "10000", "10001", "01110"],
	'D': ["11100", "10010", "10001", "10001", "10001", "10010", "11100"],
	'E': ["11111", "10000", "10000", "11110", "10000", "10000", "11111"],
	'G': ["01110", "10001", "10000", "10111", "10001", "10001", "01111"],
	'I': ["01110", "00100", "00100", "00100", "00100", "00100", "01110"],
	'L': ["10000", "10000", "10000", "10000", "10000", "10000", "11111"],
	'M': ["10001", "11011", "10101", "10101", "10001", "10001", "10001"],
	'N': ["10001", "10001", "11001", "10101", "10011", "10001", "10001"],
	'O': ["01110", "10001", "10001", "10001", "10001", "10001", "01110"],
	'P': ["11110", "10001", "10001", "11110", "10000", "10000", "10000"],
	'R': ["11110", "10001", "10001", "11110", "10100", "10010", "10001"],
	'S': ["01111", "10000", "10000", "01110", "00001", "00001", "11110"],
	'T': ["11111", "00100", "00100", "00100", "00100", "00100", "00100"],
	'U': ["10001", "10001", "10001", "10001", "10001", "10001", "01110"],
	'V': ["10001", "10001", "10001", "10001", "10001", "01010", "00100"],
	'W': ["10001", "10001", "10001", "10101", "10101", "10101", "01010"],
	'X': ["10001", "10001", "01010", "00100", "01010", "10001", "10001"],
	'Y': ["10001", "10001", "01010", "00100", "00100", "00100", "00100"],
	'H': ["10001", "10001", "10001", "11111", "10001", "10001", "10001"],
	'K': ["10001", "10010", "10100", "11000", "10100", "10010", "10001"],
	'!': ["00100", "00100", "00100", "00100", "00100", "00000", "00100"],
	' ': ["00000"] * 7,
}

def fire_colour(row, rows):
	"""Yellow at the top, through orange, to red at the bottom."""
	f = row / max(1, rows - 1)
	if f < 0.25:
		return YELLOW
	if f < 0.55:
		return ORANGE
	return RED

def render_text(text, scale):
	gw = 6 * scale
	img = Image.new("P", (len(text) * gw, 7 * scale + 1), 0)
	for i, ch in enumerate(text):
		g = GLYPHS[ch]
		for gy, row in enumerate(g):
			for gx, bit in enumerate(row):
				if bit != '1':
					continue
				for sy in range(scale):
					for sx in range(scale):
						x = i * gw + gx * scale + sx
						y = gy * scale + sy
						img.putpixel((x, y), fire_colour(y, 7 * scale))
						# drop shadow
						if x + 1 < img.width and img.getpixel((x + 1, y + 1)) == 0:
							img.putpixel((x + 1, y + 1), DARK)
	# remove trailing blank column
	return img

TEXTS = [
	("SCORE", "SCORE", 2),
	("STAGE", "STAGE", 2),
	("GAME_OVER", "GAME OVER", 2),
	("PRESS_A", "PRESS A", 2),
	("WARNING", "WARNING!", 2),
	("GET_READY", "GET READY", 2),
	("TITLE", "BLOODLUST", 3),
]

for (name, text, scale) in TEXTS:
	place(render_text(text, scale), "TEXT_" + name)

#
#	Output: sprites2.bin
#

def write_sheet(img, path):
	with open(path, "wb") as f:
		for y in range(img.height):
			word = 0
			for x in range(img.width):
				word >>= 4
				word = (word & 0xfff) | ((img.getpixel((x, y)) & 0xf) << 12)
				if (x & 3) == 3:
					f.write(struct.pack('<H', word))
					word = 0

write_sheet(sheet2, "sprites2.bin")
sheet2.save("sprites2_preview.png")

#
#	Output: frames.h
#

with open("frames.h", "w") as h:
	h.write("/* Generated by gen-sprites.py - do not edit */\n\n")
	h.write("#ifndef FRAMES_H\n#define FRAMES_H\n\n")
	h.write("#include \"sprite_frame.h\"\n\n")
	for (name, parts, hb) in frames:
		h.write("static const struct sprite_part %s_parts[] = {\n" % name.lower())
		for (sheet, x, y, w, hh, dx, dy) in parts:
			base = SHEET1_BASE if sheet == 1 else SHEET2_BASE
			addr = base + y * 64 + x // 4
			h.write("\t{0x%04x, %d, %d, %d, %d},\n" % (addr, w, hh, dx, dy))
		h.write("};\n")
		h.write("static const struct sprite_frame FRAME_%s = {%d, %s_parts, %d, %d, %d, %d};\n\n"
				% (name, len(parts), name.lower(), hb[0], hb[1], hb[2], hb[3]))
	h.write("static const struct sprite_frame* const FRAME_DIGITS[10] = {\n")
	h.write(",\n".join("\t&FRAME_DIGIT%d" % d for d in range(10)))
	h.write("\n};\n\n#endif\n")

print("sprites2: %d frames, sheet used to y=%d" % (len(frames), shelf["y"] + shelf["h"]))
