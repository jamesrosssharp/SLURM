#!/usr/bin/python3

import sys
import struct

binFile = sys.argv[1]
memFile = sys.argv[2]

with open(binFile, "rb") as binf:
    with open(memFile, "w") as memf:
        word = binf.read(2)
        while word != b"":
            data = struct.unpack('H', word)
            memf.write("%x\n" % data)
            word = binf.read(2)


