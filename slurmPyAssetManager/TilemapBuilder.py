#
#	slurmPyAssetManager: Tools for building asset bundles
#
#
#	License: MIT License
#	
#	Copyright 2023 J.R.Sharp
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
#

import xml.etree.ElementTree as ET
import struct

def build(bfile, build_directory, file_name, typ, name, pad_align):

	offset = bfile.tell()	
	
	tree = ET.parse(file_name)
	root = tree.getroot()

	for l in root.findall('layer'):
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
				bfile.write(struct.pack('H', word))
				word = 0
			i += 1
	size = bfile.tell() - offset
	
	return (offset, size)
