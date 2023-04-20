#
#

import struct
import os
import sys


# caution: path[0] is reserved for script path (or '' in REPL)
#sys.path.insert(1, '../../../slurmPyAssetManager')
sys.path.insert(1, '../../../')

import slurmPyAssetManager as assetman

bundle_start = 65536 - 0x200

options = {
	'bundle_start' : bundle_start,
	'bundle_files' : [
			  ("../src/effect1/build/effect1.bin", "applet", "effect1_applet", 0x100),
			],
	'bundle_load_address' : 2*1024*1024 + bundle_start,
}

assetman.build(options = options, build_directory = "../build", bundle_file = "../build/applet_bundle.bin", bundle_header = "../build/applet_bundle.h")


