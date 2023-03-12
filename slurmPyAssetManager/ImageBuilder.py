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

from PIL import Image
import struct

#
#	Adds an image file to bundle, after formatting appropriately
#	into 4bpp for SLURM hardware. TODO: 5bpp formatting code.
#
def build(bfile, build_directory, file_name, typ, name, pad_align):

	offset = bfile.tell()	
	
	with Image.open(file_name) as im:

		for y in range(0, im.height):
			word = 0
			for x in range(0, im.width):
				word >>= 4
				col = im.getpixel((x, y)) 
				word = (word & 0xfff) | ((col & 0xf) << 12)
				if ((x & 3) == 3):
					bfile.write(struct.pack('H', word))
					word = 0
	
	size = bfile.tell() - offset
		
	return (offset, size)

#
#	Adds a palette for an image to the bundle.
#

def build_palette(bfile, build_directory, file_name, typ, name, pad_align):

	offset = bfile.tell()	
	
	with Image.open(file_name) as im:

		palette = im.getpalette() 
		for i in range(0, int(len(palette)/3)):
			alpha = 15
			if i == 0:
				alpha = 0
			bfile.write(struct.pack('BB', 
				int(palette[i*3+1] / 16) << 4 | 
				int(palette[i*3+2] / 16),
				alpha << 4 | int(palette[i*3] /16)
			))


	
	size = bfile.tell() - offset
		
	return (offset, size)





