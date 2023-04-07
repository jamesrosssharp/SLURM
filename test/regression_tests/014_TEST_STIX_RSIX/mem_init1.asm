		.section text

TRACE_DEC_PORT  equ 0x6000
TRACE_CHAR_PORT equ 0x6001
TRACE_HEX_PORT  equ 0x6002

vector_table:
		ba start
		.times 16 ba dummy_handler
		 

start:
		# Install interrupt handlers	
		mov r1, 32
		mov r2, 0x200
		mov r3, 0
copy_loop:
		ld r4, [r2, 0]
		st [r3, 0], r4
		add r2, 2
		add r3, 2
		sub r1, 1
		bnz copy_loop

		# Enable interrupts
		
		mov r1, 1
		out [0x7000], r1	

		sti

		# Spin in a loop doing some math

		mov r1, 0
my_loop:
		add r1, 1
		add r1, 1
		add r1, 1
		add r1, 1
		add r1, 1
		add r1, 1
		add r1, 1
		add r1, 1
		add r1, 1
		add r1, 1
		add r1, 1
		add r1, 1
		add r1, 1
		add r1, 1
		add r1, 1
		add r1, 1
		out [TRACE_DEC_PORT], r1
		mov r4, 0xa
		out [TRACE_CHAR_PORT], r4
		//sleep
		ba my_loop

dummy_handler:
		stix r2
		or r2, 0xfff0
		rsix r2
		mov r2, 0xffff
		out [0x7001], r2
		iret


.end
	
