#!/usr/bin/python3

#
#	it2slurmsng : Convert impulse tracker module to slurmsng format
#
#	usage: python3 it2slurmsng <itmodule> <slurmsng>
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

	def write_to_file(self, file):
	   
		#	1. Magic "SA" - 2 bytes
		#	2. Bit depth - 1 byte (0 = 8 bit, 1 = 16 bit)
		#	3. Loop - 1 byte (0 = no loop, 1 = loop)
		#	4. Speed (c5) - 2 bytes
		#	5. loop start - 2 bytes
		#	6. loop end - 2 bytes
		#	7. Sample len - 2 bytes
		slmsngfile.write(b'SA')
		slmsngfile.write(struct.pack('b', self.depth))
		slmsngfile.write(struct.pack('b', self.loop))
		slmsngfile.write(struct.pack('H', int(self.c5speed * (65536 / (25125000 / 1024)))))
		slmsngfile.write(struct.pack('H', self.loop_start))
		slmsngfile.write(struct.pack('H', self.loop_end))
		
		if self.depth == 0: # 8 bit

			print("8-bit!")

			smplen = ((len(self.samples) + 1) // 2) * 2
			slmsngfile.write(struct.pack('H', smplen))

			extra = smplen - len(self.samples)

			for s in self.samples:
				slmsngfile.write(struct.pack('b', s))

			if extra:
				slmsngfile.write(b'\x00')

		else: # 16 bit

			print("Error: 16 bit samples not supported!")
			sys.exit(1)
	
			smplen = len(self.samples)*2 
			slmsngfile.write(struct.pack('H', smplen))

			for s in self.samples:
				slmsngfile.write(struct.pack('h', s))



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

	print("CVT: %02x" % smp.cvt)

	# Ignore vibrato parameters
	#uint8_t vis, vid, vir, vit;

	# Load sample data
	filep.seek(smp.sample_pointer)

	if (smp.flag & 0x2) == 0x2:
		# 16 bit
		for i in range(0, smp.length // 2):
			_samp = struct.unpack('h', binf.read(2))[0]
			smp.samples.append(_samp)
		smp.depth = 1
	else:
		# 8 bit
		for i in range(0, smp.length):
			_samp = struct.unpack('b', binf.read(1))[0]
			smp.samples.append(_samp)
		smp.depth = 0

	if (smp.flag & 0x10) == 0x10:
		smp.loop = 1
	else:
		smp.loop = 0

	print("Loading: %s" % smp.name)
	#print(smp.samples)

	return smp

class pattern:

	def __init__(self, rows):

		self.rows = rows

		# IT supports 64 channels

		self.last_note	 = [0] * 64
		self.last_sample = [0] * 64
		self.last_volume = [0] * 64
		self.last_effect = [0] * 64
		self.last_param  = [0] * 64
		self.last_mask	 = [0] * 64

		self.note	= [[0 for r in range(rows)] for i in range(64)]
		self.sample = [[0 for r in range(rows)] for i in range(64)]
		self.volume = [[0 for r in range(rows)] for i in range(64)]
		self.effect = [[0 for r in range(rows)] for i in range(64)]
		self.param	= [[0 for r in range(rows)] for i in range(64)]

		# Slurmsng patterns are always 64 rows x 8 channels

		self.slm_note	= [[0 for r in range(64)] for i in range(8)]
		self.slm_volume = [[0 for r in range(64)] for i in range(8)]
		self.slm_effect = [[0 for r in range(64)] for i in range(8)]
		self.slm_param	= [[0 for r in range(64)] for i in range(8)]
		self.slm_sample = [[0 for r in range(64)] for i in range(8)]


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

	def convert_pattern(self):

		# Convert to slurm formats
		
		# Convert note

		for i in range(0, 64):
			for j in range(0, 8):
				self.slm_note[j][i] = self.note[j][i] 
	
		# Check and convert sample

		for i in range(0, 64):
			for j in range(0, 8):
				if self.sample[j][i] > 15:
					print("Greater than 16 samples used")
					sys.exit(1)

				self.slm_sample[j][i] = self.sample[j][i]

		# convert volume 

		for i in range(0, 64):
			for j in range(0, 8):
				self.slm_volume[j][i] = self.volume[j][i] 
	
		# Convert effect

		for i in range(0, 64):
			for j in range(0, 8):
				eff = self.effect[j][i] 

				if eff == 0xff or eff == 0:
					self.slm_effect[j][i] = 0
					continue

				eff += 0x40

				if eff == ord('H'): # vibrato
					self.slm_effect[j][i] = 1 

				elif eff == ord('J'): # arpeggio
					self.slm_effect[j][i] = 2

				elif eff == ord('E'): # port. down
					self.slm_effect[j][i] = 3

				elif eff == ord('F'): # port. up
					self.slm_effect[j][i] = 4
				
				else:

					print("Unsupported effect '%c' (%x) used" % (eff, eff - 0x40))
					sys.exit(1)

		for i in range(0, 64):
			for j in range(0, 8):
				self.slm_param[j][i] = self.param[j][i] 
	

	def write_to_file(self, theFile):

		#1. 8 bit unsigned note - 1 based, 0 = no note - 1 byte
		#2. volume - impulse tracker format  - 1 byte
		#3. Hi: 4 bit sample, Lo: 4 bit effect - 1 byte
		#4. Effect param - 1 byte

		for i in range(0, 64):
			for j in range(0, 8):
				print("Vol: %d" % self.slm_volume[j][i])	
				slmsngfile.write(struct.pack('b', self.slm_note[j][i]))
				slmsngfile.write(struct.pack('b', self.slm_volume[j][i]))
				slmsngfile.write(struct.pack('b', self.slm_sample[j][i] << 4 | self.slm_effect[j][i]))
				slmsngfile.write(struct.pack('b', self.slm_param[j][i]))



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

	if _rows != 64:
		print("Rows not 64! Cannot convert to slurmsng")
		sys.exit(1)

	# Read padding

	binf.read(4)

	cur_row = 0

	patt = pattern(_rows)

	while cur_row < _rows:
		
		chanvar = struct.unpack('b', binf.read(1))[0]

		if chanvar == 0:
			cur_row += 1
			continue

		chan = (chanvar - 1) & 63

		patt.effect[chan][cur_row] = 0xff
		
		if chanvar & 0x80:
			maskvar = struct.unpack('b', binf.read(1))[0]
			patt.last_mask[chan] = maskvar
		else:
			maskvar = patt.last_mask[chan]

		if maskvar & ITNOTE_NOTE:
			note = struct.unpack('b', binf.read(1))[0]
			patt.note[chan][cur_row] = note
			patt.last_note[chan] = note
			patt.volume[chan][cur_row] = 31

		if maskvar & ITNOTE_SAMPLE:
			sample = struct.unpack('b', binf.read(1))[0]
			patt.sample[chan][cur_row] = sample
			patt.last_sample[chan] = sample
			patt.volume[chan][cur_row] = 31

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
			patt.volume[chan][cur_row] = 31
		if maskvar & ITNOTE_SAME_SAMPLE:
			patt.sample[chan][cur_row] = patt.last_sample[chan]
			patt.volume[chan][cur_row] = 31
		#if maskvar & ITNOTE_SAME_VOLUME:
		patt.volume[chan][cur_row] = patt.last_volume[chan]
		if maskvar & ITNOTE_SAME_EFFECT:
			patt.effect[chan][cur_row] = patt.last_effect[chan]
			patt.param[chan][cur_row] = patt.last_param[chan]

	print("Bytes: %d" % (filep.tell() - offset))

	return patt


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

	print("Initial speed: %d" % _is)
	print("Initial tempo: %d" % it)


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
		_patt.convert_pattern()
		patterns.append(_patt)
		 
	# Write out slurm song

	with open(slmsngFile, "wb") as slmsngfile:

		# Write out header

		slmsngfile.write(b'SLURMSNG')
		slmsngfile.write(struct.pack('b', ordnum))
		slmsngfile.write(struct.pack('b', smpnum))
		slmsngfile.write(struct.pack('b', pattnum))
		# Pad
		slmsngfile.write(b'\x00')

		slmsngfile.write(struct.pack('b', _is))
		slmsngfile.write(struct.pack('b', it))
		slmsngfile.write(b'\x00\x00')

		# Place holders for offsets (we'll fill them in later)
		slmsngfile.write(b'\x00' * 12)

		# Write out playlist 

		ploff = slmsngfile.tell()

		slmsngfile.write(b'PL')
		pllen = ((len(ordlist) + 1) // 2) * 2
		extra = pllen - len(ordlist)

		slmsngfile.write(struct.pack('h', pllen))

		for p in ordlist:
			slmsngfile.write(struct.pack('b', p))

		if extra:
			slmsngfile.write(b'\x00')

		# Write out samples

		sampoff = slmsngfile.tell()

		for sample in samples:
			sample.write_to_file(slmsngfile)

		pattoff = slmsngfile.tell()

		# Write out patterns
		slmsngfile.write(b'PATT')

		for patt in patterns:
			patt.write_to_file(slmsngfile)

		print("PLOFF: %x" % ploff)
		print("SMPOFF: %x" % sampoff)
		print("PATOFF: %x" % pattoff)

		slmsngfile.seek(16)
		slmsngfile.write(struct.pack('I', ploff))
		slmsngfile.write(struct.pack('I', sampoff))
		slmsngfile.write(struct.pack('I', pattoff))



