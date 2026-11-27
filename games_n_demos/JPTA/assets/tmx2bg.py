#!/usr/bin/env python3
#
#	tmx2bg.py: convert a Tiled map into two raw background tile maps.
#
#	The background hardware takes one byte per tile, so a tile set can
#	hold at most 256 tiles (256x256 pixels of 16x16 tiles). Our tile set
#	is 256x512, so it is split in two:
#
#	  tiles 0-255   (the top half of the tile set)    -> background 0
#	  tiles 256-511 (the bottom half of the tile set) -> background 1, as 0-255
#
#	Each map cell is written to the background that holds its tile; the
#	same cell in the other background is 0xff, which the hardware leaves
#	empty. If the map has several layers they are merged, and a cell may
#	then use one tile from each half.
#
#	Outputs (raw, row major, one byte per tile, no header):
#	  <out>_bg0.map, <out>_bg1.map
#	and with --tiles, the two halves of the tile set at 4 bpp (four
#	pixels a word, leftmost pixel in the low nibble, as in Captor):
#	  <out>_tiles0.bin, <out>_tiles1.bin
#
#	Usage: python3 tmx2bg.py level1.tmx [-o level1] [--tiles]
#

import argparse
import os
import struct
import sys
import xml.etree.ElementTree as ET

EMPTY = 0xff			# background_controller2.v skips tile 0xff
FLIP_BITS = 0xe0000000		# Tiled's flip / rotate flags in a gid

def fail(msg):
	sys.exit("tmx2bg: " + msg)

def load_map(path):
	root = ET.parse(path).getroot()
	w, h = int(root.get("width")), int(root.get("height"))
	tilesets = root.findall("tileset")
	if len(tilesets) != 1:
		fail("expected one tile set, found %d" % len(tilesets))
	ts = tilesets[0]
	firstgid = int(ts.get("firstgid"))
	tsx = os.path.join(os.path.dirname(path), ts.get("source")) if ts.get("source") else None
	layers = []
	for layer in root.findall("layer"):
		data = layer.find("data")
		if data.get("encoding") != "csv" or data.get("compression"):
			fail("layer '%s': save the map with CSV tile layer format" % layer.get("name"))
		gids = [int(v) for v in data.text.replace("\n", "").split(",") if v.strip()]
		if len(gids) != w * h:
			fail("layer '%s' has %d tiles, expected %d" % (layer.get("name"), len(gids), w * h))
		layers.append((layer.get("name"), gids))
	if not layers:
		fail("no tile layers")
	return w, h, firstgid, tsx, layers

def stand_in(img, half):
	"""A tile pixel-identical to tile 0xff of this half, to use in its place."""
	if img is None:
		return None
	px = img.load()
	def pixels(t):
		x0, y0 = (t % 16) * 16, half * 256 + (t // 16) * 16
		return [px[x0 + x, y0 + y] if y0 + y < img.height else 0 for y in range(16) for x in range(16)]
	want = pixels(EMPTY)
	for t in range(EMPTY):
		if pixels(t) == want:
			return t
	return None

def split(w, h, firstgid, layers, img):
	bg = [bytearray([EMPTY]) * (w * h), bytearray([EMPTY]) * (w * h)]
	swaps = {}
	for name, gids in layers:
		for i, gid in enumerate(gids):
			if gid == 0:
				continue
			where = "layer '%s' x=%d y=%d" % (name, i % w, i // w)
			if gid & FLIP_BITS:
				fail("%s: flipped / rotated tile (the hardware can't flip)" % where)
			tile = gid - firstgid
			half, t = divmod(tile, 256)
			if half > 1:
				fail("%s: tile %d is past the end of a 512 tile set" % (where, tile))
			if t == EMPTY:
				if half not in swaps:
					swaps[half] = stand_in(img, half)
				if swaps[half] is None:
					fail("%s: tile %d can't be used (0x%02x means empty) and no other tile "
					     "looks the same; leave it blank in the tile set" % (where, tile, EMPTY))
				t = swaps[half]
			if bg[half][i] != EMPTY and bg[half][i] != t:
				fail("%s: two tiles for background %d in one cell" % (where, half))
			bg[half][i] = t
	for half, t in swaps.items():
		print("tile %d means empty to the hardware; used the identical tile %d instead"
		      % (half * 256 + EMPTY, half * 256 + t))
	return bg

def pack4(img, y0):
	px = img.load()
	out = bytearray()
	for y in range(y0, y0 + 256):
		for x in range(0, 256, 4):
			w = 0
			for i in range(4):
				p = px[x + i, y] if y < img.height else 0
				w |= (p & 15) << (4 * i)
			out += struct.pack("<H", w)
	return out

def tileset_image(tsx):
	from PIL import Image
	if tsx is None:
		fail("the map must use an external tile set (.tsx)")
	image = ET.parse(tsx).getroot().find("image")
	img = Image.open(os.path.join(os.path.dirname(tsx), image.get("source")))
	if img.mode != "P" or img.getextrema()[1] > 15:
		fail("%s must be a 16 colour indexed image" % image.get("source"))
	if img.width != 256 or img.height > 512:
		fail("%s must be 256 pixels wide and at most 512 high" % image.get("source"))
	return img

def main():
	ap = argparse.ArgumentParser(description="convert a Tiled map into two raw background tile maps")
	ap.add_argument("tmx")
	ap.add_argument("-o", "--out", help="output prefix (default: the map's name)")
	ap.add_argument("--tiles", action="store_true", help="also write the two halves of the tile set at 4 bpp")
	args = ap.parse_args()
	out = args.out or os.path.splitext(args.tmx)[0]

	w, h, firstgid, tsx, layers = load_map(args.tmx)
	img = tileset_image(tsx)
	bg = split(w, h, firstgid, layers, img)
	for n in range(2):
		with open("%s_bg%d.map" % (out, n), "wb") as f:
			f.write(bg[n])
		used = sum(1 for t in bg[n] if t != EMPTY)
		print("%s_bg%d.map: %dx%d, %d of %d cells used" % (out, n, w, h, used, w * h))

	if args.tiles:
		for n in range(2):
			with open("%s_tiles%d.bin" % (out, n), "wb") as f:
				f.write(pack4(img, n * 256))
			print("%s_tiles%d.bin: rows %d-%d of the tile set" % (out, n, n * 256, n * 256 + 255))

if __name__ == "__main__":
	main()
