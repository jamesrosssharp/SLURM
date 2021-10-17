
# Generate tileset

from PIL import Image

im = Image.open("../tiled/Tileset.png")

imP = im.convert('RGB').convert('P', palette=Image.ADAPTIVE, colors=15)

with open("tileset.asm", "w") as theAsmFile:  
	theAsmFile.write("tileset:\n")
	for y in range(0, 48):
		word = 0
		for x in range(0, 256):
			word >>= 4
			col = imP.getpixel((x, y)) + 1
			if (col == 0xc):
				 col = 0
			word = (word & 0xfff) | ((col & 0xf) << 12)
			if ((x & 3) == 3):
				theAsmFile.write("\tdw 0x%x\n" % word)
				word = 0
	theAsmFile.write("tileset_palette:\n")

	palette = imP.getpalette()

	for i in range(0, 15):
		theAsmFile.write("\tdw 0x%01x%01x%01x\n" % (int(palette[i*3] / 16), int(palette[i*3+1] / 16), int(palette[i*3+2] / 16)))

# Generate tilemap

import xml.etree.ElementTree as ET
tree = ET.parse('../tiled/test_map2.tmx')
root = tree.getroot()

with open("tilemap.asm", "w") as tmFile:
	for l in root.findall('layer'):
		tmFile.write("tilemap_%s:\n" % l.attrib['name'])
		d = l.find('data')
		i = 0
		word = 0
		for dat in d.text.split(','):
			word >>= 8
			dat2 = int(dat) - 1
			if (dat2 < 0):
				dat2 = 255
			word = (word & 0xff)  | (dat2 << 8)
			if (i & 1 == 1):
				tmFile.write("\tdw 0x%x\n" % word)
				word = 0
			i += 1

