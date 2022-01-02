	.org 0x4000

// Memory locations for gfx data

SPRITE_ADDRESS equ 0x0000
TILE_SET	   equ 0x2000
TILE_MAP1	   equ 0x8000
TILE_MAP2	   equ 0xc000

// GFX Registers

GFX_BASE equ 0x5000
	
SPRITE0_X equ GFX_BASE + 0x0000
SPRITE0_Y equ GFX_BASE + 0x0100
SPRITE0_H equ GFX_BASE + 0x0200
SPRITE0_A equ GFX_BASE + 0x0300

GFX_FRAME equ GFX_BASE + 0x0f00
GFX_Y 	  equ GFX_BASE + 0x0f01
GFX_PAL   equ GFX_BASE + 0x0e00

N_SPRITES equ 9

GFX_BG0_CONTROL 	 equ GFX_BASE + 0x0d00
GFX_BG0_X 			 equ GFX_BASE + 0x0d01
GFX_BG0_Y 			 equ GFX_BASE + 0x0d02
GFX_BG0_TILEMAP_ADDR equ GFX_BASE + 0x0d03
GFX_BG0_TILESET_ADDR equ GFX_BASE + 0x0d04

GFX_BG1_CONTROL 	 equ GFX_BASE + 0x0d05
GFX_BG1_X 			 equ GFX_BASE + 0x0d06
GFX_BG1_Y 			 equ GFX_BASE + 0x0d07
GFX_BG1_TILEMAP_ADDR equ GFX_BASE + 0x0d08
GFX_BG1_TILESET_ADDR equ GFX_BASE + 0x0d09

GFX_BG2_CONTROL 	 equ GFX_BASE + 0x0d10
GFX_BG2_X 			 equ GFX_BASE + 0x0d11
GFX_BG2_Y 			 equ GFX_BASE + 0x0d12
GFX_BG2_TILEMAP_ADDR equ GFX_BASE + 0x0d13
GFX_BG2_TILESET_ADDR equ GFX_BASE + 0x0d14

GFX_CPR_LIST  		 equ GFX_BASE + 0x0400
GFX_FB_PAL 			 equ GFX_BASE + 0x0600

GFX_CPR_ENABLE 		 equ GFX_BASE + 0x0d20
GFX_CPR_Y_FLIP  	 equ GFX_BASE + 0x0d21
GFX_CPR_BGCOL 		 equ GFX_BASE + 0x0d22
GFX_CPR_ALPHA  		 equ GFX_BASE + 0x0d24

GFX_FB_CONTROL equ GFX_BASE + 0x0d30
GFX_FB_X1	   equ GFX_BASE + 0x0d31
GFX_FB_Y1	   equ GFX_BASE + 0x0d32
GFX_FB_X2	   equ GFX_BASE + 0x0d33
GFX_FB_Y2	   equ GFX_BASE + 0x0d34
GFX_FB_STRIDE  equ GFX_BASE + 0x0d39
GFX_FB_ADDR	   equ GFX_BASE + 0x0d3a

GFX_COLLISION_LIST equ GFX_BASE + 0x0700

		// Code

		mov r0, 0
		mov r1, cpr_list_1
		mov r2, cpr_list_1_end - cpr_list_1
cpr_loop:
		ld r3, [r1]
		inc r1
		out [r0, GFX_CPR_LIST], r3
		inc r0
		sub r2, 1
		bnz cpr_loop

		mov r0, 0x1
		mov r1, 0x0
		out [r1, GFX_CPR_ENABLE], r0

die:
		ba die


cpr_list_1:
		dw 0x6ff0
		dw 0x9d00
		dw 1 | (2<<1) |  (1 << 3) | (1 << 4)
		dw 0x7040
		dw 0x60ff
		dw 0x9d00
		dw 0
		dw 0x7040
		dw 0x1000
		 

cpr_list_1_end:

	.end
