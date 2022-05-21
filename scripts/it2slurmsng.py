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

    def __init__(self, rows):

        self.rows = rows

        # IT supports 64 channels

        self.last_note   = [0] * 64
        self.last_sample = [0] * 64
        self.last_volume = [0] * 64
        self.last_effect = [0] * 64
        self.last_param  = [0] * 64
        self.last_mask   = [0] * 64

        self.note   = [[0 for r in range(rows)] for i in range(64)]
        self.sample = [[0 for r in range(rows)] for i in range(64)]
        self.volume = [[0 for r in range(rows)] for i in range(64)]
        self.effect = [[0 for r in range(rows)] for i in range(64)]
        self.param  = [[0 for r in range(rows)] for i in range(64)]


    def print_pat(self):

        for r in range(0, self.rows):
            for i in range(0, 8):
                print (("%d " % self.note[i][r]), end = '')
            print()
            

    def __str__(self):

        _str = ""

        for r in range(0, self.rows):
            for i in range(0, 8):
                _str += ("%d " % self.note[r][i])
            _str += "\n"

        return _str

ITNOTE_NOTE = 1
ITNOTE_SAMPLE = 2
ITNOTE_VOLUME = 4
ITNOTE_EFFECT = 8
ITNOTE_SAME_NOTE = 16
ITNOTE_SAME_SAMPLE = 32
ITNOTE_SAME_VOLUME = 64
ITNOTE_SAME_EFFECT = 128


def load_pattern(filep, offset):

    filep.seek(offset)

    # Read number of bytes

    _bytes = struct.unpack('H', binf.read(2))[0]

    # Read number of rows

    _rows = struct.unpack('H', binf.read(2))[0]

    print("Bytes: %d Rows: %d" % (_bytes, _rows))

    # Read padding

    binf.read(4)

    cur_row = 0

    patt = pattern(_rows)

    while cur_row < _rows:
        
        chanvar = struct.unpack('b', binf.read(1))[0]

        if chanvar == 0:
            cur_row += 1
            print("Channel break!")
            continue

        chan = (chanvar - 1) & 63

        print("Chan: %d" % chan)

        if chanvar & 0x80:
            maskvar = struct.unpack('b', binf.read(1))[0]
            patt.last_mask[chan] = maskvar
        else:
            maskvar = patt.last_mask[chan]

        if maskvar & ITNOTE_NOTE:
            note = struct.unpack('b', binf.read(1))[0]
            patt.note[chan][cur_row] = note
            patt.last_note[chan] = note

        if maskvar & ITNOTE_SAMPLE:
            sample = struct.unpack('b', binf.read(1))[0]
            patt.sample[chan][cur_row] = sample
            patt.last_sample[chan] = sample

        if maskvar & ITNOTE_VOLUME:
            volume = struct.unpack('b', binf.read(1))[0]
            patt.volume[chan][cur_row] = volume
            patt.last_volume[chan] = volume

        if maskvar & ITNOTE_EFFECT:
            effect = struct.unpack('b', binf.read(1))[0] & 0x1f
            param = struct.unpack('b', binf.read(1))[0]

            patt.effect[chan][cur_row] = effect
            patt.param[chan][cur_row] = param

            patt.last_effect[chan] = effect
            patt.last_param[chan] = param

        if maskvar & ITNOTE_SAME_NOTE:
            patt.note[chan][cur_row] = patt.last_note[chan]
        if maskvar & ITNOTE_SAME_SAMPLE:
            patt.sample[chan][cur_row] = patt.last_sample[chan]
        if maskvar & ITNOTE_SAME_VOLUME:
            patt.volume[chan][cur_row] = patt.last_volume[chan]
        if maskvar & ITNOTE_SAME_EFFECT:
            patt.effect[chan][cur_row] = patt.last_effect[chan]
            patt.param[chan][cur_row] = patt.last_param[chan]

    print("Bytes: %d" % (filep.tell() - offset))

    #print(patt)

    patt.print_pat()


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
    


