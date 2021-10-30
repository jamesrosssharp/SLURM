
# Generate plane bitmap

from PIL import Image

im = Image.open("plane.png")

imP = im.convert('RGB').convert('P', palette=Image.ADAPTIVE, colors=15)

with open("plane.asm", "w") as theAsmFile:  
	theAsmFile.write("plane:\n")
	for y in range(0, 200):
		word = 0
		for x in range(0, 320):
			word >>= 8
			col = imP.getpixel((x, y)) 
			#if (col == 0xc):
			#	 col = 0
			word = (word & 0xff) | ((col & 0xff) << 8)
			if ((x & 1) == 1):
				theAsmFile.write("\tdw 0x%x\n" % word)
				word = 0
	theAsmFile.write("plane_palette:\n")

	palette = imP.getpalette()

	for i in range(0, 256):
		theAsmFile.write("\tdw 0x%01x%01x%01x\n" % (int(palette[i*3] / 16), int(palette[i*3+1] / 16), int(palette[i*3+2] / 16)))
