#
#
#   Create the assets for the ROM cartridge for Bloodlust, and assets.asm which contains palettes etc,
#   and assets.h, which contains cartridge offsets for loading content from cartridge ROM.
#
#


from PIL import Image
import struct
import os

def convertImage(im, theAsmFile, theBinFile, name, w, h): 

    for y in range(0, h):
        word = 0
        for x in range(0, w):
            word >>= 4
            col = im.getpixel((x, y)) 
            word = (word & 0xfff) | ((col & 0xf) << 12)
            if ((x & 3) == 3):
                theBinFile.write(struct.pack('H', word))
                word = 0
    theAsmFile.write("{}_palette:\n".format(name))

    palette = im.getpalette()
    print (im.getpalette())

    for i in range(0, int(len(palette)/3)):
        theAsmFile.write("\tdw 0x%01x%01x%01x\n" % (int(palette[i*3] / 16), int(palette[i*3+1] / 16), int(palette[i*3+2] / 16)))


with open("assets.asm", "w") as theAsmFile:  

    with open("palette.bin", "wb") as theBinFile:
        im = Image.open("Palette.png")
        convertImage(im, theAsmFile, theBinFile, "mandelbrot", im.width, im.height)

