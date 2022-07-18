
import struct

files = [("Bassdrum.raw", "Bassdrum", "f"), ("909.snare.2.raw", "Snare", "f"), ("ClosedHihat.raw", "ClosedHihat", "f")]

with open("samples.asm", "w") as asmFil:
    for (filnam, label, typey) in files:

        asmFil.write("%s:\n" % label)

        with open(filnam, "rb") as audioFile:
            nsamp = 0
            while 1:
                if typey == "f":
                    dat = audioFile.read(4)
                    if dat == b'':
                        break
                    samp = struct.unpack('f', dat)[0]*32768.0 
                else:
                    dat = audioFile.read(2)
                    if dat == b'':
                        break 
                    samp = struct.unpack('h', dat)[0] 
                
                asmFil.write("\tdw %d\n" % (samp))
                nsamp += 1
            print("Processed %d samples, %s bytes\n" % (nsamp, nsamp * 2))



