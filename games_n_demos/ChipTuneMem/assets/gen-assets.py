#
#
#   Create the assets for the ROM cartridge for Bloodlust, and assets.asm which contains palettes etc,
#   and assets.h, which contains cartridge offsets for loading content from cartridge ROM.
#
#


from PIL import Image
import struct
import os

with open("assets.asm", "w") as theAsmFile:  

	theAsmFile.write("\t.padto 0x8000\n\n")

	theAsmFile.write("song_data:\n")

	with open("chiptune.slurmsng", "rb") as infile:
 
		word = infile.read(2)
		while word != b"":
			data = struct.unpack('H', word)
			theAsmFile.write("dw 0x%04x\n" % data)
			word = infile.read(2)



#bundle_start = 65536 - 0x200
#bundle_files = [("chiptune.slurmsng", "chiptune", 65536)]
#bundle_load_address = 1024*1024 + bundle_start

#offset = bundle_load_address
#with open("bundle.h", "w") as header:
#    with open("bundle.bin", "wb") as outbundle:
#        for (bfile, bname, pad) in bundle_files:
#            size = os.path.getsize(bfile)
#            off_total = offset + pad
#            with open(bfile, "rb") as infile:
#                filebytes = infile.read(size)
#                outbundle.write(filebytes)
#                header.write("#define %s_rom_offset_lo  0x%x\n" % (bname, offset & 0xffff)) 
#                header.write("#define %s_rom_offset_hi  0x%x\n" % (bname, (offset>>16) & 0xffff)) 
#
#                offset += size
#            if pad:
#                while offset < off_total:
#                    outbundle.write(b'\x00')
#                    offset += 1


