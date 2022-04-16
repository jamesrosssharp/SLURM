from PIL import Image

im = Image.open("sprites.png")

imP = im.convert('RGB').convert('P', palette=Image.ADAPTIVE, colors=15)

with open("assets.asm", "w") as theAsmFile:  
    theAsmFile.write("\t.padto 0x8000 // pad to 32kB\n")
    theAsmFile.write("pacman_sprite_sheet:\n")
    for y in range(0, 160):
        word = 0
        for x in range(0, 256):
            word >>= 4
            col = imP.getpixel((x, y)) + 1
            if (col == 0xf):
                col = 0
            word = (word & 0xfff) | ((col & 0xf) << 12)
            if ((x & 3) == 3):
                theAsmFile.write("\tdw 0x%x\n" % word)
                word = 0
    theAsmFile.write("pacman_palette:\n")

    palette = imP.getpalette()
    print (imP.getpalette())

    theAsmFile.write("\tdw 0x0\n")
    for i in range(0, int(len(palette)/3)):
        theAsmFile.write("\tdw 0x%01x%01x%01x\n" % (int(palette[i*3] / 16), int(palette[i*3+1] / 16), int(palette[i*3+2] / 16)))



