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

    for i in range(0, 16):
        theAsmFile.write("\tdw 0x%01x%01x%01x\n" % (int(palette[i*3] / 16), int(palette[i*3+1] / 16), int(palette[i*3+2] / 16)))


with open("assets.asm", "w") as theAsmFile:  

    with open("sprites.bin", "wb") as theBinFile:
        im = Image.open("sprites1.png")
        convertImage(im, theAsmFile, theBinFile, "bloodlust_sprites", im.width, im.height)
    with open("tiles.bin", "wb") as theBinFile:
        im = Image.open("bg_tiles_256x256x16.png")
        convertImage(im, theAsmFile, theBinFile, "bloodlust_tiles", im.width, im.height)

    theAsmFile.write("\t.padto 0x8000\n\n")
    theAsmFile.write("tilemap_buf1: .times 64*32 db 0\n")
    theAsmFile.write("tilemap_buf2: .times 64*32 db 0\n")
    
    import xml.etree.ElementTree as ET
    tree = ET.parse('Background.tmx')
    root = tree.getroot()

    with open("map1.map", "wb") as theBinFile: 
        for l in root.findall('layer'):
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
                    theBinFile.write(struct.pack('H', word))
                    word = 0
                i += 1


bundle_start = 65536
bundle_files = [("sprites.bin", "spritesheet"), ("tiles.bin", "tileset"), ("map1.map", "level1")]
bundle_load_address = 1024*1024 + bundle_start

offset = bundle_load_address
with open("bundle.h", "w") as header:
    with open("bundle.bin", "wb") as outbundle:
        for (bfile, bname) in bundle_files:
            size = os.path.getsize(bfile)
            with open(bfile, "rb") as infile:
                filebytes = infile.read(size)
                outbundle.write(filebytes)
                header.write("#define %s_rom_offset = %d\n" % (bname, offset)) 
                offset += size
