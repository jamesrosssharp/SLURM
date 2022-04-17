from PIL import Image

def convertImage(im, theAsmFile, name, w, h): 

    for y in range(0, h):
        word = 0
        for x in range(0, w):
            word >>= 4
            col = im.getpixel((x, y)) + 1
            if (col == 0xf):
                col = 0
            word = (word & 0xfff) | ((col & 0xf) << 12)
            if ((x & 3) == 3):
                theAsmFile.write("\tdw 0x%x\n" % word)
                word = 0
    theAsmFile.write("{}_palette:\n".format(name))

    palette = im.getpalette()
    print (im.getpalette())

    theAsmFile.write("\tdw 0x0\n")
    for i in range(0, int(len(palette)/3)):
        theAsmFile.write("\tdw 0x%01x%01x%01x\n" % (int(palette[i*3] / 16), int(palette[i*3+1] / 16), int(palette[i*3+2] / 16)))


with open("assets.asm", "w") as theAsmFile:  
    im = Image.open("sprites.png")

    imP = im.convert('RGB').convert('P', palette=Image.ADAPTIVE, colors=15)

    theAsmFile.write("\t.padto 0x8000 // pad to 32kB\n")
    theAsmFile.write("pacman_sprite_sheet:\n")
   
    convertImage(imP, theAsmFile, "pacman_spritesheet", 256, 160)

    im = Image.open("bg_tiles.png")
    imP = im.convert('RGB').convert('P', palette=Image.ADAPTIVE, colors=15)
    
    theAsmFile.write("\tpacman_tileset:\n")
    convertImage(imP, theAsmFile, "pacman_tileset", 256, 16)

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



