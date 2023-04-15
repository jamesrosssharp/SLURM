		.section text

TRACE_DEC_PORT  equ 0x6000
TRACE_CHAR_PORT equ 0x6001
TRACE_HEX_PORT  equ 0x6002

vector_table:
		ba start
		.times 16 dw 0
		 

start:
		mov r1, 0x8000
		mov r2, 0x55aa
		st.ex [r1], r2
		add r1, 2
		stb.ex [r1], r2
		add r1, 1
		stb.ex [r1], r2
		mov r1, 0x8000
		ld.ex r3, [r1]		
		out [r0, TRACE_HEX_PORT], r3
		add r1, 2
		ldb.ex r3, [r1]		
		out [r0, TRACE_HEX_PORT], r3
		add r1, 1
		ldbsx.ex r3, [r1]
		out [r0, TRACE_HEX_PORT], r3
die:
		ba die





.end
	
