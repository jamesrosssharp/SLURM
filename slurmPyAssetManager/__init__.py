#
#	slurmPyAssetManager: Tools for building asset bundles
#
#	TODO: Add slurmsng generation to this set of tools
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

import sys
import slurmPyAssetManager.BundleBuilder as builder
import traceback

def build(options = None, build_directory = None, bundle_file = None, bundle_header = None):

	print("Building bundle {}...".format(bundle_file))

	try:
		builder.build(build_directory = build_directory, bundle_file = bundle_file, bundle_header = bundle_header, options = options)
	except:
		print("\nError building bundle. :(")
		print("-----------:(------------\n")
		traceback.print_exc()
		print("\n-----------:(------------\n")
		sys.exit(1)

	print("Built bundle. See you!")
	print("======================")
	print()
