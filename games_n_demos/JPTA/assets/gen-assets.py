#
#
#   Create the assets for the ROM cartridge for Bloodlust, and assets.asm which contains palettes etc,
#   and assets.h, which contains cartridge offsets for loading content from cartridge ROM.
#
#


from PIL import Image
import struct
import os

# Convert 5 bpp image
def convertImage(im, theAsmFile, theBinFile, name, w, h): 

    for y in range(0, h):
        word = 0
        for x in range(0, w):
            word >>= 5
            col = im.getpixel((x, y)) 
            word = (word & 0x3ff) | ((col & 0x1f) << 10)
            if ((x % 3) == 2):
                theBinFile.write(struct.pack('H', word))
                word = 0
    theAsmFile.write("{}_palette:\n".format(name))

    palette = im.getpalette()
    print (im.getpalette())

    for i in range(0, 32):
        theAsmFile.write("\tdw 0x%01x%01x%01x\n" % (int(palette[i*3] / 16), int(palette[i*3+1] / 16), int(palette[i*3+2] / 16)))


with open("assets.asm", "w") as theAsmFile:  

    with open("john.bin", "wb") as theBinFile:
        im = Image.open("JohnSprites.png")
        convertImage(im, theAsmFile, theBinFile, "john_sprites", im.width, im.height)

bundle_start = 65536
bundle_files = [("john.bin", "john_spritesheet", 32768)]
bundle_load_address = 1024*1024 + bundle_start

offset = bundle_load_address
with open("bundle.h", "w") as header:
    with open("bundle.bin", "wb") as outbundle:
        for (bfile, bname, pad) in bundle_files:
            size = os.path.getsize(bfile)
            off_total = offset + pad
            with open(bfile, "rb") as infile:
                filebytes = infile.read(size)
                outbundle.write(filebytes)
                header.write("#define %s_rom_offset = %d\n" % (bname, offset)) 
                offset += size
            if pad:
                while offset < off_total:
                    outbundle.write(b'\x00')
                    offset += 1


