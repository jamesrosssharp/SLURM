/*
	SlurmDemo : A demo to show off SlURM16

sine_table.asm : sine table in 8:8 fixed point

License: MIT License

Copyright 2023 J.R.Sharp

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

	.section data
	.global sin_table_8_8

sin_table_8_8:
	dw 0x0
	dw 0x6
	dw 0xd
	dw 0x13
	dw 0x19
	dw 0x1f
	dw 0x26
	dw 0x2c
	dw 0x32
	dw 0x38
	dw 0x3e
	dw 0x44
	dw 0x4a
	dw 0x50
	dw 0x56
	dw 0x5c
	dw 0x62
	dw 0x68
	dw 0x6d
	dw 0x73
	dw 0x79
	dw 0x7e
	dw 0x84
	dw 0x89
	dw 0x8e
	dw 0x93
	dw 0x98
	dw 0x9d
	dw 0xa2
	dw 0xa7
	dw 0xac
	dw 0xb0
	dw 0xb5
	dw 0xb9
	dw 0xbe
	dw 0xc2
	dw 0xc6
	dw 0xca
	dw 0xce
	dw 0xd1
	dw 0xd5
	dw 0xd8
	dw 0xdc
	dw 0xdf
	dw 0xe2
	dw 0xe5
	dw 0xe7
	dw 0xea
	dw 0xec
	dw 0xef
	dw 0xf1
	dw 0xf3
	dw 0xf5
	dw 0xf7
	dw 0xf8
	dw 0xfa
	dw 0xfb
	dw 0xfc
	dw 0xfd
	dw 0xfe
	dw 0xff
	dw 0xff
	dw 0x100
	dw 0x100
	dw 0x100
	dw 0x100
	dw 0x100
	dw 0xff
	dw 0xff
	dw 0xfe
	dw 0xfd
	dw 0xfc
	dw 0xfb
	dw 0xfa
	dw 0xf8
	dw 0xf7
	dw 0xf5
	dw 0xf3
	dw 0xf1
	dw 0xef
	dw 0xed
	dw 0xea
	dw 0xe8
	dw 0xe5
	dw 0xe2
	dw 0xdf
	dw 0xdc
	dw 0xd8
	dw 0xd5
	dw 0xd1
	dw 0xce
	dw 0xca
	dw 0xc6
	dw 0xc2
	dw 0xbe
	dw 0xba
	dw 0xb5
	dw 0xb1
	dw 0xac
	dw 0xa7
	dw 0xa3
	dw 0x9e
	dw 0x99
	dw 0x94
	dw 0x8f
	dw 0x89
	dw 0x84
	dw 0x7e
	dw 0x79
	dw 0x73
	dw 0x6e
	dw 0x68
	dw 0x62
	dw 0x5c
	dw 0x57
	dw 0x51
	dw 0x4b
	dw 0x45
	dw 0x3f
	dw 0x38
	dw 0x32
	dw 0x2c
	dw 0x26
	dw 0x20
	dw 0x19
	dw 0x13
	dw 0xd
	dw 0x7
	dw 0x0
	dw 0xfffa
	dw 0xfff4
	dw 0xffee
	dw 0xffe7
	dw 0xffe1
	dw 0xffdb
	dw 0xffd5
	dw 0xffce
	dw 0xffc8
	dw 0xffc2
	dw 0xffbc
	dw 0xffb6
	dw 0xffb0
	dw 0xffaa
	dw 0xffa4
	dw 0xff9e
	dw 0xff99
	dw 0xff93
	dw 0xff8d
	dw 0xff88
	dw 0xff82
	dw 0xff7d
	dw 0xff77
	dw 0xff72
	dw 0xff6d
	dw 0xff68
	dw 0xff63
	dw 0xff5e
	dw 0xff59
	dw 0xff54
	dw 0xff50
	dw 0xff4b
	dw 0xff47
	dw 0xff43
	dw 0xff3e
	dw 0xff3a
	dw 0xff37
	dw 0xff33
	dw 0xff2f
	dw 0xff2b
	dw 0xff28
	dw 0xff25
	dw 0xff22
	dw 0xff1e
	dw 0xff1c
	dw 0xff19
	dw 0xff16
	dw 0xff14
	dw 0xff11
	dw 0xff0f
	dw 0xff0d
	dw 0xff0b
	dw 0xff09
	dw 0xff08
	dw 0xff06
	dw 0xff05
	dw 0xff04
	dw 0xff03
	dw 0xff02
	dw 0xff01
	dw 0xff01
	dw 0xff00
	dw 0xff00
	dw 0xff00
	dw 0xff00
	dw 0xff00
	dw 0xff01
	dw 0xff01
	dw 0xff02
	dw 0xff03
	dw 0xff04
	dw 0xff05
	dw 0xff06
	dw 0xff08
	dw 0xff09
	dw 0xff0b
	dw 0xff0d
	dw 0xff0f
	dw 0xff11
	dw 0xff13
	dw 0xff16
	dw 0xff18
	dw 0xff1b
	dw 0xff1e
	dw 0xff21
	dw 0xff24
	dw 0xff27
	dw 0xff2b
	dw 0xff2e
	dw 0xff32
	dw 0xff36
	dw 0xff3a
	dw 0xff3e
	dw 0xff42
	dw 0xff46
	dw 0xff4a
	dw 0xff4f
	dw 0xff54
	dw 0xff58
	dw 0xff5d
	dw 0xff62
	dw 0xff67
	dw 0xff6c
	dw 0xff71
	dw 0xff76
	dw 0xff7c
	dw 0xff81
	dw 0xff87
	dw 0xff8c
	dw 0xff92
	dw 0xff98
	dw 0xff9d
	dw 0xffa3
	dw 0xffa9
	dw 0xffaf
	dw 0xffb5
	dw 0xffbb
	dw 0xffc1
	dw 0xffc7
	dw 0xffcd
	dw 0xffd3
	dw 0xffda
	dw 0xffe0
	dw 0xffe6
	dw 0xffec
	dw 0xfff3
	dw 0xfff9

	.end
