SLURMSNG
========

"SLURMSNG" is a simple format for tracked music. The idea is to convert Impulse tracker format modules and extract pattern and playlist data to embed. 
Patterns are stored with a kind of mask compression in IT, so these
will be properly unpacked. They will occupy more flash space, but won't incur any run time overhead to decode them and they
can simply be DMA'd into some double-buffers.

Patterns are always 8 channels.

Header
------

1. Magic - 8 bytes, "SLURMSNG"
2. Num samples - 1 byte
3. Playlist size - 1 byte
4. Num patterns - 1 byte
5. Pad - 1 byte
6. Samples offset - 4 bytes
7. Playlist offset - 4 bytes
8. Pattern data offset - 4 bytes
	
Samples
-------

Samples should occupy max 20kB. For "Num samples" entries, each entry has the following header:

1. Magic "SA" - 2 bytes
2. Bit depth - 1 byte (0 = 8 bit, 1 = 16 bit)
3. Loop - 1 byte (0 = no loop, 1 = loop)
3. Speed (c5) - 2 bytes
4. loop start - 2 bytes
5. loop end - 2 bytes
6. Sample len - 2 bytes

"Sample len" bytes of audio data follows. "Sample len" is always a multiple of two. Max 16 samples are allowed.

Playlist
--------

1. Magic "PL" - 2 bytes
2. Chunk len - 2 bytes

Followed by "Chunk len" bytes of which the first "Playlist size" bytes are the playlist entries.


Pattern Data
------------

1. Magic "PATT" - 4 bytes

Followed by:-

"Num patterns" pattern entries. Each pattern consists of 8 channel x 64 entries of the following format, 2048 bytes in total:

1. 8 bit unsigned note - 1 based, 0 = no note - 1 byte
2. Hi: 4 bit volume high, Lo: volume low - 1 byte
3. Hi: 4 bit sample, Lo: 4 bit effect - 1 byte
4. Effect param - 1 byte

Volume column
-------------

Effect column
-------------



