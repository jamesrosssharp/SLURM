


	.padto 0x8000

// Sound mixing routines (located in this bank so we have easy fast to sample data)







// Pattern buffer A
pattern_A: 
	.times 64*8*4 dw 0

// Pattern buffer B
pattern_B:
	.times 64*8*4 dw 0

// Buffer for samples
music_heap:
	.times 24*1024 db 0

