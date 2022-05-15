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

    for i in range(0, 16):
        theAsmFile.write("\tdw 0x%01x%01x%01x\n" % (int(palette[i*3] / 16), int(palette[i*3+1] / 16), int(palette[i*3+2] / 16)))


with open("assets.asm", "w") as theAsmFile:  
    theAsmFile.write("\t.padto 0x8000\n\n")

    with open("sprites.bin", "wb") as theBinFile:
        im = Image.open("sprites_16.png")
        convertImage(im, theAsmFile, theBinFile, "pacman_spritesheet", im.width, im.height)
    with open("tiles.bin", "wb") as theBinFile:
        im = Image.open("bg_tiles_4.png")
        convertImage(im, theAsmFile, theBinFile, "pacman_tileset", im.width, im.height)
    with open("title.bin", "wb") as theBinFile:
        im = Image.open("title_16.png")
        convertImage(im, theAsmFile, theBinFile, "pacman_title", im.width, im.height)


    import xml.etree.ElementTree as ET
    tree = ET.parse('background.tmx')
    root = tree.getroot()

    for l in root.findall('layer'):
        theAsmFile.write("pacman_tilemap:\n")
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
                theAsmFile.write("\tdw 0x%x\n" % word)
                word = 0
            i += 1


bundle_start = 65536
bundle_files = [("title.bin","titlepic", 32768), ("sprites.bin", "spritesheet", 0), ("tiles.bin", "tileset", 0)]
bundle_load_address = 1024*1024 + bundle_start

offset = bundle_load_address
with open("bundle.h", "w") as header:
    with open("bundle.bin", "wb") as outbundle:
        for (bfile, bname, pad) in bundle_files:
            size = os.path.getsize(bfile)
            with open(bfile, "rb") as infile:
                filebytes = infile.read(size)
                outbundle.write(filebytes)
                header.write("#define %s_rom_offset = %d\n" % (bname, offset)) 
                offset += size
            if pad:
                print("Padding %d bytes" % (pad - size))
                while size < pad:
                    outbundle.write(b'\x00')
                    size += 1
                    offset += 1



