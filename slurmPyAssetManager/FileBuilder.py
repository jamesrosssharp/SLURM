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

import os

#
#	Adds a file to the bundle verbatim. Returns offset (in bundle) and size
#	of segment.
#
def build(bfile, build_directory, file_name, typ, name, pad_align):

	if pad_align is None:
		pad_align = 2

	offset = bfile.tell()	
	fsize = os.path.getsize(file_name) 
	size = ((fsize + pad_align - 1) // pad_align) * pad_align
	
	with open(file_name, "rb") as infile:
		filebytes = infile.read(size)
		bfile.write(filebytes)	
	for i in range(0, size - fsize):
		bfile.write(b'\0')

	return (offset, size)
