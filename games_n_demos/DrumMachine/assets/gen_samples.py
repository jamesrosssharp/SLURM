
import struct

files = [("Bassdrum.raw", "Bassdrum")]

with open("samples.asm", "w") as asmFil:
    for (filnam, label) in files:

        asmFil.write("%s:\n" % label)

        with open(filnam, "rb") as audioFile:
            nsamp = 0
            while 1:
                dat = audioFile.read(4)
                if dat == b'':
                    break
                samp = struct.unpack('>hh', dat)[1] 
                asmFil.write("\tdw %d\n" % samp)
                nsamp += 1
            print("Processed %d samples, %s bytes\n" % (nsamp, nsamp * 2))
