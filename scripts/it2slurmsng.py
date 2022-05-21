#!/usr/bin/python3

#
#   it2slurmsng : Convert impulse tracker module to slurmsng format
#
#   usage: python3 it2slurmsng <itmodule> <slurmsng>
#

import sys
import struct

def read_para(filep, length):
    para = []
    for i in range(0, length):
        para.append(struct.unpack('I', filep.read(4))[0])
    return para

class sample(object):

    def __init__(self):
        self.samples = []
        self.name = ""

    def __str__(self):
        return self.name

    def __repr__(self):
        return self.name

def load_sample(filep, offset):
   
    filep.seek(offset)
    magic = filep.read(4)

    if magic != b'IMPS':
        print("Bad sample magic!")
        sys.exit(1)

    # skip filename
    
    filep.read(13)

    smp = sample()
    
    smp.gvl = struct.unpack('b', binf.read(1))[0]
    smp.flag = struct.unpack('b', binf.read(1))[0]
    smp.vol = struct.unpack('b', binf.read(1))[0]

    smp.name = binf.read(26).decode("ascii").replace('\x20', '')

    smp.cvt = struct.unpack('b', binf.read(1))[0]
    smp.dfp = struct.unpack('b', binf.read(1))[0]
    
    smp.length = struct.unpack('I', binf.read(4))[0]
    smp.loop_start = struct.unpack('I', binf.read(4))[0]
    smp.loop_end = struct.unpack('I', binf.read(4))[0]
    smp.c5speed = struct.unpack('I', binf.read(4))[0]

    smp.susloop_start = struct.unpack('I', binf.read(4))[0]
    smp.susloop_end = struct.unpack('I', binf.read(4))[0]
    smp.sample_pointer = struct.unpack('I', binf.read(4))[0]

    # Ignore vibrato parameters
    #uint8_t vis, vid, vir, vit;

    # Load sample data
    filep.seek(smp.sample_pointer)

    if (smp.flag & 0x2) == 0x2:
        # 16 bit
        for i in range(0, smp.length // 2):
            _samp = struct.unpack('h', binf.read(2))[0]
            smp.samples.append(_samp)
    else:
        # 8 bit
        for i in range(0, smp.length):
            _samp = struct.unpack('b', binf.read(1))[0]
            smp.samples.append(_samp)
    print("Loading: %s" % smp.name)
    #print(smp.samples)

    return smp

class pattern:

    def __init__(self):
        pass

def load_pattern(filep, offset):
    pass



if len(sys.argv) != 3:
    print("Usage: it2slurmsng <itmodule> <slurmsng>")
    sys.exit(1)

itFile = sys.argv[1]
slmsngFile = sys.argv[2]

with open(itFile, "rb") as binf:
        
    magic = binf.read(4)
    if magic != b'IMPM':
        print("Unsupported file type")
        sys.exit(1)

    print("File is Impulse Tracker module!")

    # Read in song title

    title = binf.read(26)
    print("Song title: %s" % title.decode("ascii"))

    # Minor / major ticks (who cares!)

    himinor = struct.unpack('b', binf.read(1))[0]
    himajor = struct.unpack('b', binf.read(1))[0]

    #print("himajor = %d himinor = %d" % (himajor, himinor))

    # ordnum    

    ordnum = struct.unpack('h', binf.read(2))[0]

    print("ordnum = %d" % ordnum)

    # insnum

    insnum = struct.unpack('h', binf.read(2))[0]

    print("insnum = %d" % insnum)

    # smpnum

    smpnum = struct.unpack('h', binf.read(2))[0]

    print("smpnum = %d" % smpnum)

    # pattnum

    pattnum = struct.unpack('h', binf.read(2))[0]

    print("pattnum = %d" % pattnum)

    # Some weird numbers I don't really understand

    cwtv  = struct.unpack('h', binf.read(2))[0]
    cmwt   = struct.unpack('h', binf.read(2))[0]
    flags  = struct.unpack('h', binf.read(2))[0]
    special  = struct.unpack('h', binf.read(2))[0]

    # These are pretty much ignored
    
    gv = struct.unpack('b', binf.read(1))[0]
    mv = struct.unpack('b', binf.read(1))[0]
    _is = struct.unpack('b', binf.read(1))[0]
    it = struct.unpack('b', binf.read(1))[0]
    sep = struct.unpack('b', binf.read(1))[0]
    pwd = struct.unpack('b', binf.read(1))[0]

    msg_length = struct.unpack('h', binf.read(2))[0]
    msg_offset = struct.unpack('I', binf.read(4))[0]
    binf.read(4)

    chan_pan = struct.unpack('64b', binf.read(64)) 
    chan_vol = struct.unpack('64b', binf.read(64))

    # Read in order list 
    
    ordlist = []
    for i in range(0, ordnum):
        _ord = struct.unpack('b', binf.read(1))[0]
        ordlist.append(_ord)

    print("Ordlist = %s" % ordlist)

    para_ins = read_para(binf, insnum)
    para_smp = read_para(binf, smpnum)
    para_patt = read_para(binf, pattnum)

    print("para_smp = %s" % para_smp)
    print("para_patt = %s" % para_patt)

    # Load samples
    
    samples = []
    for smp in para_smp:
        _samp = load_sample(binf, smp)
        samples.append(_samp)
    
    print(samples)

    # Load patterns

    patterns = []
    for patt in para_patt:
        _patt = load_pattern(binf, patt)
        patterns.append(_patt)
    
    print(patterns)



