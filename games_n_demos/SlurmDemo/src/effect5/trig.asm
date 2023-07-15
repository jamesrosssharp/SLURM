/*

	SlurmDemo : A demo to show off SlURM16

trig.asm : trig. tables

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
	.global sin_table_2_14
sin_table_2_14:
	dw 0x0
	dw 0xc9
	dw 0x192
	dw 0x25b
	dw 0x324
	dw 0x3ec
	dw 0x4b5
	dw 0x57d
	dw 0x645
	dw 0x70d
	dw 0x7d5
	dw 0x89c
	dw 0x963
	dw 0xa29
	dw 0xaf0
	dw 0xbb5
	dw 0xc7b
	dw 0xd40
	dw 0xe04
	dw 0xec8
	dw 0xf8b
	dw 0x104e
	dw 0x1110
	dw 0x11d1
	dw 0x1292
	dw 0x1352
	dw 0x1411
	dw 0x14cf
	dw 0x158d
	dw 0x164a
	dw 0x1706
	dw 0x17c1
	dw 0x187b
	dw 0x1934
	dw 0x19ec
	dw 0x1aa4
	dw 0x1b5a
	dw 0x1c0f
	dw 0x1cc3
	dw 0x1d76
	dw 0x1e28
	dw 0x1ed8
	dw 0x1f88
	dw 0x2036
	dw 0x20e3
	dw 0x218f
	dw 0x2239
	dw 0x22e3
	dw 0x238a
	dw 0x2431
	dw 0x24d6
	dw 0x2579
	dw 0x261c
	dw 0x26bc
	dw 0x275c
	dw 0x27f9
	dw 0x2895
	dw 0x2930
	dw 0x29c9
	dw 0x2a61
	dw 0x2af6
	dw 0x2b8a
	dw 0x2c1d
	dw 0x2cae
	dw 0x2d3d
	dw 0x2dca
	dw 0x2e55
	dw 0x2edf
	dw 0x2f67
	dw 0x2fed
	dw 0x3071
	dw 0x30f4
	dw 0x3174
	dw 0x31f3
	dw 0x3270
	dw 0x32ea
	dw 0x3363
	dw 0x33da
	dw 0x344f
	dw 0x34c2
	dw 0x3532
	dw 0x35a1
	dw 0x360e
	dw 0x3678
	dw 0x36e1
	dw 0x3747
	dw 0x37ab
	dw 0x380d
	dw 0x386d
	dw 0x38cb
	dw 0x3926
	dw 0x3980
	dw 0x39d7
	dw 0x3a2c
	dw 0x3a7f
	dw 0x3acf
	dw 0x3b1d
	dw 0x3b69
	dw 0x3bb3
	dw 0x3bfa
	dw 0x3c3f
	dw 0x3c81
	dw 0x3cc2
	dw 0x3d00
	dw 0x3d3b
	dw 0x3d75
	dw 0x3dac
	dw 0x3de0
	dw 0x3e12
	dw 0x3e42
	dw 0x3e6f
	dw 0x3e9a
	dw 0x3ec3
	dw 0x3ee9
	dw 0x3f0d
	dw 0x3f2e
	dw 0x3f4d
	dw 0x3f69
	dw 0x3f83
	dw 0x3f9b
	dw 0x3fb0
	dw 0x3fc3
	dw 0x3fd3
	dw 0x3fe0
	dw 0x3fec
	dw 0x3ff4
	dw 0x3ffb
	dw 0x3fff
	dw 0x4000
	dw 0x3fff
	dw 0x3ffb
	dw 0x3ff5
	dw 0x3fed
	dw 0x3fe2
	dw 0x3fd5
	dw 0x3fc5
	dw 0x3fb2
	dw 0x3f9e
	dw 0x3f87
	dw 0x3f6d
	dw 0x3f51
	dw 0x3f32
	dw 0x3f11
	dw 0x3eee
	dw 0x3ec8
	dw 0x3ea0
	dw 0x3e75
	dw 0x3e48
	dw 0x3e19
	dw 0x3de7
	dw 0x3db3
	dw 0x3d7c
	dw 0x3d43
	dw 0x3d08
	dw 0x3cca
	dw 0x3c8a
	dw 0x3c48
	dw 0x3c03
	dw 0x3bbc
	dw 0x3b73
	dw 0x3b27
	dw 0x3ad9
	dw 0x3a89
	dw 0x3a37
	dw 0x39e2
	dw 0x398b
	dw 0x3932
	dw 0x38d7
	dw 0x3879
	dw 0x381a
	dw 0x37b8
	dw 0x3754
	dw 0x36ee
	dw 0x3686
	dw 0x361c
	dw 0x35af
	dw 0x3541
	dw 0x34d0
	dw 0x345e
	dw 0x33e9
	dw 0x3373
	dw 0x32fa
	dw 0x3280
	dw 0x3203
	dw 0x3185
	dw 0x3105
	dw 0x3082
	dw 0x2ffe
	dw 0x2f79
	dw 0x2ef1
	dw 0x2e67
	dw 0x2ddc
	dw 0x2d4f
	dw 0x2cc0
	dw 0x2c30
	dw 0x2b9e
	dw 0x2b0a
	dw 0x2a74
	dw 0x29dd
	dw 0x2944
	dw 0x28aa
	dw 0x280e
	dw 0x2770
	dw 0x26d1
	dw 0x2631
	dw 0x258f
	dw 0x24eb
	dw 0x2446
	dw 0x23a0
	dw 0x22f8
	dw 0x224f
	dw 0x21a5
	dw 0x20fa
	dw 0x204d
	dw 0x1f9f
	dw 0x1eef
	dw 0x1e3f
	dw 0x1d8d
	dw 0x1cda
	dw 0x1c26
	dw 0x1b71
	dw 0x1abb
	dw 0x1a04
	dw 0x194c
	dw 0x1893
	dw 0x17d9
	dw 0x171e
	dw 0x1662
	dw 0x15a5
	dw 0x14e8
	dw 0x142a
	dw 0x136b
	dw 0x12ab
	dw 0x11ea
	dw 0x1129
	dw 0x1067
	dw 0xfa4
	dw 0xee1
	dw 0xe1d
	dw 0xd59
	dw 0xc94
	dw 0xbcf
	dw 0xb09
	dw 0xa43
	dw 0x97d
	dw 0x8b6
	dw 0x7ee
	dw 0x727
	dw 0x65f
	dw 0x597
	dw 0x4cf
	dw 0x406
	dw 0x33e
	dw 0x275
	dw 0x1ac
	dw 0xe3
	dw 0x1a
	dw 0xff51
	dw 0xfe88
	dw 0xfdbf
	dw 0xfcf7
	dw 0xfc2e
	dw 0xfb65
	dw 0xfa9d
	dw 0xf9d5
	dw 0xf90d
	dw 0xf845
	dw 0xf77e
	dw 0xf6b7
	dw 0xf5f0
	dw 0xf52a
	dw 0xf464
	dw 0xf39f
	dw 0xf2da
	dw 0xf216
	dw 0xf152
	dw 0xf08e
	dw 0xefcc
	dw 0xef09
	dw 0xee48
	dw 0xed87
	dw 0xecc7
	dw 0xec08
	dw 0xeb49
	dw 0xea8c
	dw 0xe9cf
	dw 0xe913
	dw 0xe858
	dw 0xe79d
	dw 0xe6e4
	dw 0xe62c
	dw 0xe574
	dw 0xe4be
	dw 0xe409
	dw 0xe354
	dw 0xe2a1
	dw 0xe1ef
	dw 0xe13e
	dw 0xe08f
	dw 0xdfe0
	dw 0xdf33
	dw 0xde87
	dw 0xdddd
	dw 0xdd33
	dw 0xdc8b
	dw 0xdbe5
	dw 0xdb3f
	dw 0xda9c
	dw 0xd9f9
	dw 0xd958
	dw 0xd8b9
	dw 0xd81b
	dw 0xd77f
	dw 0xd6e4
	dw 0xd64b
	dw 0xd5b3
	dw 0xd51d
	dw 0xd489
	dw 0xd3f6
	dw 0xd365
	dw 0xd2d6
	dw 0xd248
	dw 0xd1bd
	dw 0xd133
	dw 0xd0aa
	dw 0xd024
	dw 0xcfa0
	dw 0xcf1d
	dw 0xce9c
	dw 0xce1d
	dw 0xcda0
	dw 0xcd25
	dw 0xccac
	dw 0xcc35
	dw 0xcbc0
	dw 0xcb4d
	dw 0xcadc
	dw 0xca6d
	dw 0xca00
	dw 0xc996
	dw 0xc92d
	dw 0xc8c6
	dw 0xc862
	dw 0xc7ff
	dw 0xc79f
	dw 0xc741
	dw 0xc6e5
	dw 0xc68c
	dw 0xc634
	dw 0xc5df
	dw 0xc58c
	dw 0xc53b
	dw 0xc4ed
	dw 0xc4a1
	dw 0xc457
	dw 0xc40f
	dw 0xc3ca
	dw 0xc387
	dw 0xc346
	dw 0xc308
	dw 0xc2cc
	dw 0xc293
	dw 0xc25b
	dw 0xc227
	dw 0xc1f4
	dw 0xc1c4
	dw 0xc196
	dw 0xc16b
	dw 0xc142
	dw 0xc11c
	dw 0xc0f8
	dw 0xc0d6
	dw 0xc0b7
	dw 0xc09a
	dw 0xc080
	dw 0xc068
	dw 0xc053
	dw 0xc040
	dw 0xc02f
	dw 0xc021
	dw 0xc016
	dw 0xc00d
	dw 0xc006
	dw 0xc002
	dw 0xc000
	dw 0xc001
	dw 0xc004
	dw 0xc00a
	dw 0xc012
	dw 0xc01c
	dw 0xc02a
	dw 0xc039
	dw 0xc04b
	dw 0xc05f
	dw 0xc076
	dw 0xc090
	dw 0xc0ab
	dw 0xc0ca
	dw 0xc0ea
	dw 0xc10d
	dw 0xc133
	dw 0xc15b
	dw 0xc185
	dw 0xc1b2
	dw 0xc1e1
	dw 0xc213
	dw 0xc247
	dw 0xc27d
	dw 0xc2b5
	dw 0xc2f0
	dw 0xc32e
	dw 0xc36e
	dw 0xc3b0
	dw 0xc3f4
	dw 0xc43b
	dw 0xc484
	dw 0xc4cf
	dw 0xc51d
	dw 0xc56c
	dw 0xc5be
	dw 0xc613
	dw 0xc669
	dw 0xc6c2
	dw 0xc71d
	dw 0xc77a
	dw 0xc7da
	dw 0xc83b
	dw 0xc89f
	dw 0xc905
	dw 0xc96d
	dw 0xc9d7
	dw 0xca43
	dw 0xcab1
	dw 0xcb21
	dw 0xcb93
	dw 0xcc08
	dw 0xcc7e
	dw 0xccf6
	dw 0xcd70
	dw 0xcdec
	dw 0xce6b
	dw 0xceeb
	dw 0xcf6d
	dw 0xcff0
	dw 0xd076
	dw 0xd0fd
	dw 0xd187
	dw 0xd212
	dw 0xd29f
	dw 0xd32d
	dw 0xd3bd
	dw 0xd44f
	dw 0xd4e3
	dw 0xd578
	dw 0xd60f
	dw 0xd6a8
	dw 0xd742
	dw 0xd7de
	dw 0xd87b
	dw 0xd91a
	dw 0xd9ba
	dw 0xda5c
	dw 0xdaff
	dw 0xdba4
	dw 0xdc4a
	dw 0xdcf2
	dw 0xdd9b
	dw 0xde45
	dw 0xdef0
	dw 0xdf9d
	dw 0xe04b
	dw 0xe0fa
	dw 0xe1aa
	dw 0xe25c
	dw 0xe30e
	dw 0xe3c2
	dw 0xe477
	dw 0xe52d
	dw 0xe5e4
	dw 0xe69c
	dw 0xe755
	dw 0xe80f
	dw 0xe8ca
	dw 0xe985
	dw 0xea42
	dw 0xeaff
	dw 0xebbe
	dw 0xec7d
	dw 0xed3c
	dw 0xedfd
	dw 0xeebe
	dw 0xef80
	dw 0xf042
	dw 0xf105
	dw 0xf1c9
	dw 0xf28d
	dw 0xf352
	dw 0xf417
	dw 0xf4dd
	dw 0xf5a3
	dw 0xf66a
	dw 0xf730
	dw 0xf7f8
	dw 0xf8bf
	dw 0xf987
	dw 0xfa4f
	dw 0xfb17
	dw 0xfbe0
	dw 0xfca8
	dw 0xfd71
	dw 0xfe3a
	dw 0xff03

	.global tan_table_16_16
tan_table_16_16:
	dw 0x0 // 
	dw 0x0 // 0.000000
	dw 0x324 // 
	dw 0x0 // 0.012266
	dw 0x648 // 
	dw 0x0 // 0.024536
	dw 0x96d // 
	dw 0x0 // 0.036813
	dw 0xc92 // 
	dw 0x0 // 0.049102
	dw 0xfb8 // 
	dw 0x0 // 0.061405
	dw 0x12e0 // 
	dw 0x0 // 0.073727
	dw 0x1609 // 
	dw 0x0 // 0.086071
	dw 0x1933 // 
	dw 0x0 // 0.098441
	dw 0x1c60 // 
	dw 0x0 // 0.110841
	dw 0x1f8f // 
	dw 0x0 // 0.123275
	dw 0x22c0 // 
	dw 0x0 // 0.135747
	dw 0x25f4 // 
	dw 0x0 // 0.148260
	dw 0x292b // 
	dw 0x0 // 0.160818
	dw 0x2c66 // 
	dw 0x0 // 0.173427
	dw 0x2fa4 // 
	dw 0x0 // 0.186089
	dw 0x32e5 // 
	dw 0x0 // 0.198809
	dw 0x362b // 
	dw 0x0 // 0.211591
	dw 0x3975 // 
	dw 0x0 // 0.224440
	dw 0x3cc4 // 
	dw 0x0 // 0.237360
	dw 0x4017 // 
	dw 0x0 // 0.250355
	dw 0x4370 // 
	dw 0x0 // 0.263430
	dw 0x46cf // 
	dw 0x0 // 0.276590
	dw 0x4a33 // 
	dw 0x0 // 0.289840
	dw 0x4d9d // 
	dw 0x0 // 0.303184
	dw 0x510e // 
	dw 0x0 // 0.316627
	dw 0x5486 // 
	dw 0x0 // 0.330176
	dw 0x5806 // 
	dw 0x0 // 0.343835
	dw 0x5b8c // 
	dw 0x0 // 0.357609
	dw 0x5f1b // 
	dw 0x0 // 0.371505
	dw 0x62b2 // 
	dw 0x0 // 0.385528
	dw 0x6652 // 
	dw 0x0 // 0.399685
	dw 0x69fb // 
	dw 0x0 // 0.413980
	dw 0x6dad // 
	dw 0x0 // 0.428422
	dw 0x716a // 
	dw 0x0 // 0.443016
	dw 0x7530 // 
	dw 0x0 // 0.457770
	dw 0x7902 // 
	dw 0x0 // 0.472691
	dw 0x7cdf // 
	dw 0x0 // 0.487785
	dw 0x80c9 // 
	dw 0x0 // 0.503061
	dw 0x84be // 
	dw 0x0 // 0.518527
	dw 0x88c1 // 
	dw 0x0 // 0.534191
	dw 0x8cd1 // 
	dw 0x0 // 0.550062
	dw 0x90ef // 
	dw 0x0 // 0.566148
	dw 0x951c // 
	dw 0x0 // 0.582459
	dw 0x9958 // 
	dw 0x0 // 0.599005
	dw 0x9da5 // 
	dw 0x0 // 0.615796
	dw 0xa202 // 
	dw 0x0 // 0.632842
	dw 0xa671 // 
	dw 0x0 // 0.650155
	dw 0xaaf1 // 
	dw 0x0 // 0.667747
	dw 0xaf85 // 
	dw 0x0 // 0.685629
	dw 0xb42d // 
	dw 0x0 // 0.703814
	dw 0xb8ea // 
	dw 0x0 // 0.722316
	dw 0xbdbc // 
	dw 0x0 // 0.741149
	dw 0xc2a5 // 
	dw 0x0 // 0.760328
	dw 0xc7a5 // 
	dw 0x0 // 0.779867
	dw 0xccbf // 
	dw 0x0 // 0.799784
	dw 0xd1f2 // 
	dw 0x0 // 0.820096
	dw 0xd740 // 
	dw 0x0 // 0.840820
	dw 0xdcab // 
	dw 0x0 // 0.861977
	dw 0xe233 // 
	dw 0x0 // 0.883585
	dw 0xe7da // 
	dw 0x0 // 0.905667
	dw 0xeda2 // 
	dw 0x0 // 0.928246
	dw 0xf38b // 
	dw 0x0 // 0.951344
	dw 0xf999 // 
	dw 0x0 // 0.974988
	dw 0xffcc // 
	dw 0x0 // 0.999204
	dw 0x626 // 
	dw 0x1 // 1.024021
	dw 0xcaa // 
	dw 0x1 // 1.049470
	dw 0x1359 // 
	dw 0x1 // 1.075582
	dw 0x1a36 // 
	dw 0x1 // 1.102392
	dw 0x2144 // 
	dw 0x1 // 1.129938
	dw 0x2884 // 
	dw 0x1 // 1.158258
	dw 0x2ff9 // 
	dw 0x1 // 1.187394
	dw 0x37a7 // 
	dw 0x1 // 1.217391
	dw 0x3f90 // 
	dw 0x1 // 1.248298
	dw 0x47b9 // 
	dw 0x1 // 1.280166
	dw 0x5024 // 
	dw 0x1 // 1.313051
	dw 0x58d6 // 
	dw 0x1 // 1.347012
	dw 0x61d2 // 
	dw 0x1 // 1.382115
	dw 0x6b1e // 
	dw 0x1 // 1.418428
	dw 0x74be // 
	dw 0x1 // 1.456028
	dw 0x7eb8 // 
	dw 0x1 // 1.494994
	dw 0x8911 // 
	dw 0x1 // 1.535417
	dw 0x93d0 // 
	dw 0x1 // 1.577392
	dw 0x9efb // 
	dw 0x1 // 1.621023
	dw 0xaa9b // 
	dw 0x1 // 1.666424
	dw 0xb6b6 // 
	dw 0x1 // 1.713720
	dw 0xc357 // 
	dw 0x1 // 1.763047
	dw 0xd087 // 
	dw 0x1 // 1.814554
	dw 0xde50 // 
	dw 0x1 // 1.868407
	dw 0xecbf // 
	dw 0x1 // 1.924786
	dw 0xfbe0 // 
	dw 0x1 // 1.983892
	dw 0xbc3 // 
	dw 0x2 // 2.045946
	dw 0x1c77 // 
	dw 0x2 // 2.111195
	dw 0x2e0f // 
	dw 0x2 // 2.179913
	dw 0x409e // 
	dw 0x2 // 2.252407
	dw 0x543b // 
	dw 0x2 // 2.329021
	dw 0x68ff // 
	dw 0x2 // 2.410141
	dw 0x7f07 // 
	dw 0x2 // 2.496204
	dw 0x9674 // 
	dw 0x2 // 2.587703
	dw 0xaf69 // 
	dw 0x2 // 2.685201
	dw 0xca12 // 
	dw 0x2 // 2.789341
	dw 0xe69f // 
	dw 0x2 // 2.900859
	dw 0x546 // 
	dw 0x3 // 3.020606
	dw 0x264a // 
	dw 0x3 // 3.149569
	dw 0x49f5 // 
	dw 0x3 // 3.288896
	dw 0x70a0 // 
	dw 0x3 // 3.439938
	dw 0x9ab3 // 
	dw 0x3 // 3.604287
	dw 0xc8aa // 
	dw 0x3 // 3.783841
	dw 0xfb1b // 
	dw 0x3 // 3.980874
	dw 0x32b9 // 
	dw 0x4 // 4.198136
	dw 0x7062 // 
	dw 0x4 // 4.438990
	dw 0xb524 // 
	dw 0x4 // 4.707583
	dw 0x254 // 
	dw 0x5 // 5.009096
	dw 0x599f // 
	dw 0x5 // 5.350086
	dw 0xbd2d // 
	dw 0x5 // 5.738975
	dw 0x2fd0 // 
	dw 0x6 // 6.186763
	dw 0xb546 // 
	dw 0x6 // 6.708095
	dw 0x52aa // 
	dw 0x7 // 7.322913
	dw 0xf20 // 
	dw 0x8 // 8.059084
	dw 0xf4ef // 
	dw 0x8 // 8.956768
	dw 0x1378 // 
	dw 0xa // 10.076048
	dw 0x82d2 // 
	dw 0xb // 11.511022
	dw 0x6af8 // 
	dw 0xd // 13.417847
	dw 0x1375 // 
	dw 0x10 // 16.076008
	dw 0xa3e // 
	dw 0x14 // 20.040007
	dw 0x9689 // 
	dw 0x1a // 26.588022
	dw 0x7966 // 
	dw 0x27 // 39.474213
	dw 0x8dcb // 
	dw 0x4c // 76.553883
	dw 0xc3fe // 
	dw 0x4e7 // 1255.765592
	dw 0xd085 // 
	dw 0xffa8 // -87.185470
	dw 0xe03b // 
	dw 0xffd5 // -42.124097
	dw 0x3c12 // 
	dw 0xffe4 // -27.765354
	dw 0x4c33 // 
	dw 0xffeb // -20.702353
	dw 0x7ffc // 
	dw 0xffef // -16.500061
	dw 0x499b // 
	dw 0xfff2 // -13.712476
	dw 0x45bb // 
	dw 0xfff4 // -11.727618
	dw 0xc20c // 
	dw 0xfff5 // -10.242001
	dw 0xe979 // 
	dw 0xfff6 // -9.088002
	dw 0xd5a3 // 
	dw 0xfff7 // -8.165483
	dw 0x96cd // 
	dw 0xfff8 // -7.410939
	dw 0x37c5 // 
	dw 0xfff9 // -6.782146
	dw 0xc004 // 
	dw 0xfff9 // -6.249938
	dw 0x34dc // 
	dw 0xfffa // -5.793522
	dw 0x9a32 // 
	dw 0xfffa // -5.397672
	dw 0xf2f3 // 
	dw 0xfffa // -5.050984
	dw 0x4158 // 
	dw 0xfffb // -4.744749
	dw 0x871e // 
	dw 0xfffb // -4.472200
	dw 0xc5a2 // 
	dw 0xfffb // -4.227998
	dw 0xfdfc // 
	dw 0xfffb // -4.007877
	dw 0x310e // 
	dw 0xfffc // -3.808384
	dw 0x5f91 // 
	dw 0xfffc // -3.626699
	dw 0x8a1d // 
	dw 0xfffc // -3.460489
	dw 0xb133 // 
	dw 0xfffc // -3.307815
	dw 0xd53c // 
	dw 0xfffc // -3.167048
	dw 0xf694 // 
	dw 0xfffc // -3.036808
	dw 0x1586 // 
	dw 0xfffd // -2.915923
	dw 0x3255 // 
	dw 0xfffd // -2.803387
	dw 0x4d3a // 
	dw 0xfffd // -2.698333
	dw 0x6666 // 
	dw 0xfffd // -2.600011
	dw 0x7e03 // 
	dw 0xfffd // -2.507766
	dw 0x9438 // 
	dw 0xfffd // -2.421027
	dw 0xa924 // 
	dw 0xfffd // -2.339291
	dw 0xbce6 // 
	dw 0xfffd // -2.262115
	dw 0xcf97 // 
	dw 0xfffd // -2.189106
	dw 0xe14d // 
	dw 0xfffd // -2.119916
	dw 0xf21e // 
	dw 0xfffd // -2.054233
	dw 0x21b // 
	dw 0xfffe // -1.991778
	dw 0x1155 // 
	dw 0xfffe // -1.932303
	dw 0x1fda // 
	dw 0xfffe // -1.875581
	dw 0x2db8 // 
	dw 0xfffe // -1.821411
	dw 0x3afb // 
	dw 0xfffe // -1.769608
	dw 0x47ae // 
	dw 0xfffe // -1.720007
	dw 0x53da // 
	dw 0xfffe // -1.672455
	dw 0x5f89 // 
	dw 0xfffe // -1.626815
	dw 0x6ac3 // 
	dw 0xfffe // -1.582961
	dw 0x7590 // 
	dw 0xfffe // -1.540778
	dw 0x7ff6 // 
	dw 0xfffe // -1.500159
	dw 0x89fb // 
	dw 0xfffe // -1.461008
	dw 0x93a7 // 
	dw 0xfffe // -1.423236
	dw 0x9cfd // 
	dw 0xfffe // -1.386760
	dw 0xa604 // 
	dw 0xfffe // -1.351504
	dw 0xaebf // 
	dw 0xfffe // -1.317399
	dw 0xb733 // 
	dw 0xfffe // -1.284377
	dw 0xbf64 // 
	dw 0xfffe // -1.252380
	dw 0xc755 // 
	dw 0xfffe // -1.221352
	dw 0xcf0b // 
	dw 0xfffe // -1.191239
	dw 0xd688 // 
	dw 0xfffe // -1.161994
	dw 0xddce // 
	dw 0xfffe // -1.133570
	dw 0xe4e2 // 
	dw 0xfffe // -1.105927
	dw 0xebc5 // 
	dw 0xfffe // -1.079023
	dw 0xf27a // 
	dw 0xfffe // -1.052822
	dw 0xf904 // 
	dw 0xfffe // -1.027289
	dw 0xff63 // 
	dw 0xfffe // -1.002392
	dw 0x59b // 
	dw 0xffff // -0.978099
	dw 0xbae // 
	dw 0xffff // -0.954383
	dw 0x119c // 
	dw 0xffff // -0.931215
	dw 0x1768 // 
	dw 0xffff // -0.908571
	dw 0x1d13 // 
	dw 0xffff // -0.886425
	dw 0x229f // 
	dw 0xffff // -0.864757
	dw 0x280e // 
	dw 0xffff // -0.843543
	dw 0x2d5f // 
	dw 0xffff // -0.822763
	dw 0x3296 // 
	dw 0xffff // -0.802399
	dw 0x37b3 // 
	dw 0xffff // -0.782432
	dw 0x3cb6 // 
	dw 0xffff // -0.762844
	dw 0x41a2 // 
	dw 0xffff // -0.743620
	dw 0x4677 // 
	dw 0xffff // -0.724743
	dw 0x4b37 // 
	dw 0xffff // -0.706198
	dw 0x4fe1 // 
	dw 0xffff // -0.687973
	dw 0x5477 // 
	dw 0xffff // -0.670052
	dw 0x58fb // 
	dw 0xffff // -0.652424
	dw 0x5d6c // 
	dw 0xffff // -0.635075
	dw 0x61cb // 
	dw 0xffff // -0.617994
	dw 0x661a // 
	dw 0xffff // -0.601171
	dw 0x6a58 // 
	dw 0xffff // -0.584594
	dw 0x6e87 // 
	dw 0xffff // -0.568253
	dw 0x72a7 // 
	dw 0xffff // -0.552138
	dw 0x76b9 // 
	dw 0xffff // -0.536240
	dw 0x7abd // 
	dw 0xffff // -0.520550
	dw 0x7eb4 // 
	dw 0xffff // -0.505059
	dw 0x829f // 
	dw 0xffff // -0.489758
	dw 0x867e // 
	dw 0xffff // -0.474641
	dw 0x8a51 // 
	dw 0xffff // -0.459698
	dw 0x8e1a // 
	dw 0xffff // -0.444923
	dw 0x91d7 // 
	dw 0xffff // -0.430308
	dw 0x958b // 
	dw 0xffff // -0.415847
	dw 0x9935 // 
	dw 0xffff // -0.401533
	dw 0x9cd6 // 
	dw 0xffff // -0.387359
	dw 0xa06e // 
	dw 0xffff // -0.373319
	dw 0xa3fe // 
	dw 0xffff // -0.359407
	dw 0xa786 // 
	dw 0xffff // -0.345617
	dw 0xab06 // 
	dw 0xffff // -0.331943
	dw 0xae7f // 
	dw 0xffff // -0.318381
	dw 0xb1f1 // 
	dw 0xffff // -0.304924
	dw 0xb55c // 
	dw 0xffff // -0.291567
	dw 0xb8c1 // 
	dw 0xffff // -0.278305
	dw 0xbc20 // 
	dw 0xffff // -0.265134
	dw 0xbf7a // 
	dw 0xffff // -0.252048
	dw 0xc2ce // 
	dw 0xffff // -0.239043
	dw 0xc61d // 
	dw 0xffff // -0.226113
	dw 0xc968 // 
	dw 0xffff // -0.213256
	dw 0xccae // 
	dw 0xffff // -0.200465
	dw 0xcff0 // 
	dw 0xffff // -0.187737
	dw 0xd32f // 
	dw 0xffff // -0.175068
	dw 0xd66a // 
	dw 0xffff // -0.162453
	dw 0xd9a1 // 
	dw 0xffff // -0.149888
	dw 0xdcd5 // 
	dw 0xffff // -0.137369
	dw 0xe007 // 
	dw 0xffff // -0.124892
	dw 0xe336 // 
	dw 0xffff // -0.112454
	dw 0xe663 // 
	dw 0xffff // -0.100049
	dw 0xe98e // 
	dw 0xffff // -0.087676
	dw 0xecb7 // 
	dw 0xffff // -0.075328
	dw 0xefdf // 
	dw 0xffff // -0.063004
	dw 0xf305 // 
	dw 0xffff // -0.050699
	dw 0xf62b // 
	dw 0xffff // -0.038408
	dw 0xf950 // 
	dw 0xffff // -0.026130
	dw 0xfc74 // 
	dw 0xffff // -0.013859

	.global cot_table_16_16
cot_table_16_16:
	dw 0x0 // 
	dw 0x86a0 // 100000.000000
	dw 0x864a // 
	dw 0x51 // 81.524574
	dw 0xc193 // 
	dw 0x28 // 40.756154
	dw 0x29f9 // 
	dw 0x1b // 27.163954
	dw 0x5da6 // 
	dw 0x14 // 20.365809
	dw 0x4908 // 
	dw 0x10 // 16.285285
	dw 0x9046 // 
	dw 0xd // 13.563570
	dw 0x9e4a // 
	dw 0xb // 11.618318
	dw 0x288a // 
	dw 0xa // 10.158353
	dw 0x59c // 
	dw 0x9 // 9.021913
	dw 0x1ca8 // 
	dw 0x8 // 8.111940
	dw 0x5dde // 
	dw 0x7 // 7.366668
	dw 0xbeb3 // 
	dw 0x6 // 6.744922
	dw 0x37dc // 
	dw 0x6 // 6.218194
	dw 0xc421 // 
	dw 0x5 // 5.766123
	dw 0x5fb0 // 
	dw 0x5 // 5.373777
	dw 0x7ab // 
	dw 0x5 // 5.029956
	dw 0xb9e1 // 
	dw 0x4 // 4.726096
	dw 0x749e // 
	dw 0x4 // 4.455536
	dw 0x3688 // 
	dw 0x4 // 4.213017
	dw 0xfe8d // 
	dw 0x3 // 3.994332
	dw 0xcbcc // 
	dw 0x3 // 3.796076
	dw 0x9d8f // 
	dw 0x3 // 3.615461
	dw 0x733f // 
	dw 0x3 // 3.450185
	dw 0x4c5f // 
	dw 0x3 // 3.298331
	dw 0x2885 // 
	dw 0x3 // 3.158286
	dw 0x758 // 
	dw 0x3 // 3.028688
	dw 0xe88b // 
	dw 0x2 // 2.908374
	dw 0xcbdd // 
	dw 0x2 // 2.796348
	dw 0xb117 // 
	dw 0x2 // 2.691753
	dw 0x9806 // 
	dw 0x2 // 2.593844
	dw 0x8081 // 
	dw 0x2 // 2.501973
	dw 0x6a63 // 
	dw 0x2 // 2.415574
	dw 0x558b // 
	dw 0x2 // 2.334147
	dw 0x41db // 
	dw 0x2 // 2.257253
	dw 0x2f3c // 
	dw 0x2 // 2.184502
	dw 0x1d95 // 
	dw 0x2 // 2.115548
	dw 0xcd2 // 
	dw 0x2 // 2.050083
	dw 0xfce2 // 
	dw 0x1 // 1.987829
	dw 0xedb5 // 
	dw 0x1 // 1.928539
	dw 0xdf3b // 
	dw 0x1 // 1.871989
	dw 0xd167 // 
	dw 0x1 // 1.817978
	dw 0xc42e // 
	dw 0x1 // 1.766323
	dw 0xb784 // 
	dw 0x1 // 1.716859
	dw 0xab60 // 
	dw 0x1 // 1.669435
	dw 0x9fb9 // 
	dw 0x1 // 1.623915
	dw 0x9486 // 
	dw 0x1 // 1.580173
	dw 0x89c1 // 
	dw 0x1 // 1.538094
	dw 0x7f61 // 
	dw 0x1 // 1.497574
	dw 0x7561 // 
	dw 0x1 // 1.458515
	dw 0x6bbb // 
	dw 0x1 // 1.420830
	dw 0x626a // 
	dw 0x1 // 1.384435
	dw 0x5969 // 
	dw 0x1 // 1.349256
	dw 0x50b2 // 
	dw 0x1 // 1.315222
	dw 0x4843 // 
	dw 0x1 // 1.282270
	dw 0x4016 // 
	dw 0x1 // 1.250337
	dw 0x3829 // 
	dw 0x1 // 1.219370
	dw 0x3077 // 
	dw 0x1 // 1.189315
	dw 0x28fe // 
	dw 0x1 // 1.160124
	dw 0x21bb // 
	dw 0x1 // 1.131753
	dw 0x1aaa // 
	dw 0x1 // 1.104158
	dw 0x13ca // 
	dw 0x1 // 1.077301
	dw 0xd18 // 
	dw 0x1 // 1.051144
	dw 0x691 // 
	dw 0x1 // 1.025654
	dw 0x34 // 
	dw 0x1 // 1.000797
	dw 0xf9ff // 
	dw 0x0 // 0.976542
	dw 0xf3ef // 
	dw 0x0 // 0.952862
	dw 0xee03 // 
	dw 0x0 // 0.929729
	dw 0xe839 // 
	dw 0x0 // 0.907118
	dw 0xe290 // 
	dw 0x0 // 0.885004
	dw 0xdd06 // 
	dw 0x0 // 0.863366
	dw 0xd799 // 
	dw 0x0 // 0.842181
	dw 0xd249 // 
	dw 0x0 // 0.821429
	dw 0xcd14 // 
	dw 0x0 // 0.801091
	dw 0xc7f9 // 
	dw 0x0 // 0.781149
	dw 0xc2f7 // 
	dw 0x0 // 0.761585
	dw 0xbe0d // 
	dw 0x0 // 0.742384
	dw 0xb939 // 
	dw 0x0 // 0.723529
	dw 0xb47b // 
	dw 0x0 // 0.705006
	dw 0xafd2 // 
	dw 0x0 // 0.686800
	dw 0xab3d // 
	dw 0x0 // 0.668899
	dw 0xa6bb // 
	dw 0x0 // 0.651289
	dw 0xa24b // 
	dw 0x0 // 0.633958
	dw 0x9ded // 
	dw 0x0 // 0.616895
	dw 0x999f // 
	dw 0x0 // 0.600087
	dw 0x9562 // 
	dw 0x0 // 0.583526
	dw 0x9134 // 
	dw 0x0 // 0.567200
	dw 0x8d15 // 
	dw 0x0 // 0.551099
	dw 0x8904 // 
	dw 0x0 // 0.535215
	dw 0x8500 // 
	dw 0x0 // 0.519538
	dw 0x810a // 
	dw 0x0 // 0.504060
	dw 0x7d20 // 
	dw 0x0 // 0.488771
	dw 0x7942 // 
	dw 0x0 // 0.473665
	dw 0x7570 // 
	dw 0x0 // 0.458734
	dw 0x71a8 // 
	dw 0x0 // 0.443969
	dw 0x6deb // 
	dw 0x0 // 0.429365
	dw 0x6a38 // 
	dw 0x0 // 0.414913
	dw 0x668e // 
	dw 0x0 // 0.400608
	dw 0x62ee // 
	dw 0x0 // 0.386443
	dw 0x5f56 // 
	dw 0x0 // 0.372412
	dw 0x5bc7 // 
	dw 0x0 // 0.358508
	dw 0x5840 // 
	dw 0x0 // 0.344725
	dw 0x54c0 // 
	dw 0x0 // 0.331059
	dw 0x5148 // 
	dw 0x0 // 0.317504
	dw 0x4dd6 // 
	dw 0x0 // 0.304053
	dw 0x4a6c // 
	dw 0x0 // 0.290703
	dw 0x4707 // 
	dw 0x0 // 0.277447
	dw 0x43a8 // 
	dw 0x0 // 0.264282
	dw 0x404f // 
	dw 0x0 // 0.251201
	dw 0x3cfb // 
	dw 0x0 // 0.238201
	dw 0x39ac // 
	dw 0x0 // 0.225276
	dw 0x3661 // 
	dw 0x0 // 0.212423
	dw 0x331b // 
	dw 0x0 // 0.199637
	dw 0x2fda // 
	dw 0x0 // 0.186913
	dw 0x2c9b // 
	dw 0x0 // 0.174247
	dw 0x2961 // 
	dw 0x0 // 0.161635
	dw 0x262a // 
	dw 0x0 // 0.149074
	dw 0x22f5 // 
	dw 0x0 // 0.136558
	dw 0x1fc4 // 
	dw 0x0 // 0.124084
	dw 0x1c95 // 
	dw 0x0 // 0.111647
	dw 0x1968 // 
	dw 0x0 // 0.099245
	dw 0x163d // 
	dw 0x0 // 0.086873
	dw 0x1314 // 
	dw 0x0 // 0.074528
	dw 0xfed // 
	dw 0x0 // 0.062204
	dw 0xcc6 // 
	dw 0x0 // 0.049900
	dw 0x9a1 // 
	dw 0x0 // 0.037611
	dw 0x67c // 
	dw 0x0 // 0.025333
	dw 0x358 // 
	dw 0x0 // 0.013063
	dw 0x34 // 
	dw 0x0 // 0.000796
	dw 0xfd10 // 
	dw 0xffff // -0.011470
	dw 0xf9ec // 
	dw 0xffff // -0.023739
	dw 0xf6c8 // 
	dw 0xffff // -0.036016
	dw 0xf3a2 // 
	dw 0xffff // -0.048304
	dw 0xf07c // 
	dw 0xffff // -0.060606
	dw 0xed55 // 
	dw 0xffff // -0.072926
	dw 0xea2c // 
	dw 0xffff // -0.085269
	dw 0xe701 // 
	dw 0xffff // -0.097637
	dw 0xe3d5 // 
	dw 0xffff // -0.110035
	dw 0xe0a6 // 
	dw 0xffff // -0.122467
	dw 0xdd75 // 
	dw 0xffff // -0.134936
	dw 0xda41 // 
	dw 0xffff // -0.147446
	dw 0xd70a // 
	dw 0xffff // -0.160002
	dw 0xd3d0 // 
	dw 0xffff // -0.172607
	dw 0xd092 // 
	dw 0xffff // -0.185265
	dw 0xcd51 // 
	dw 0xffff // -0.197981
	dw 0xca0c // 
	dw 0xffff // -0.210759
	dw 0xc6c2 // 
	dw 0xffff // -0.223604
	dw 0xc374 // 
	dw 0xffff // -0.236519
	dw 0xc020 // 
	dw 0xffff // -0.249509
	dw 0xbcc8 // 
	dw 0xffff // -0.262579
	dw 0xb96a // 
	dw 0xffff // -0.275733
	dw 0xb606 // 
	dw 0xffff // -0.288976
	dw 0xb29c // 
	dw 0xffff // -0.302314
	dw 0xaf2b // 
	dw 0xffff // -0.315751
	dw 0xabb3 // 
	dw 0xffff // -0.329293
	dw 0xa835 // 
	dw 0xffff // -0.342945
	dw 0xa4af // 
	dw 0xffff // -0.356711
	dw 0xa120 // 
	dw 0xffff // -0.370599
	dw 0x9d8a // 
	dw 0xffff // -0.384614
	dw 0x99eb // 
	dw 0xffff // -0.398761
	dw 0x9642 // 
	dw 0xffff // -0.413048
	dw 0x9291 // 
	dw 0xffff // -0.427480
	dw 0x8ed5 // 
	dw 0xffff // -0.442064
	dw 0x8b0f // 
	dw 0xffff // -0.456807
	dw 0x873e // 
	dw 0xffff // -0.471717
	dw 0x8361 // 
	dw 0xffff // -0.486800
	dw 0x7f79 // 
	dw 0xffff // -0.502064
	dw 0x7b84 // 
	dw 0xffff // -0.517517
	dw 0x7782 // 
	dw 0xffff // -0.533168
	dw 0x7373 // 
	dw 0xffff // -0.549025
	dw 0x6f56 // 
	dw 0xffff // -0.565097
	dw 0x6b2a // 
	dw 0xffff // -0.581393
	dw 0x66ee // 
	dw 0xffff // -0.597923
	dw 0x62a3 // 
	dw 0xffff // -0.614698
	dw 0x5e47 // 
	dw 0xffff // -0.631727
	dw 0x59da // 
	dw 0xffff // -0.649023
	dw 0x555a // 
	dw 0xffff // -0.666596
	dw 0x50c7 // 
	dw 0xffff // -0.684459
	dw 0x4c21 // 
	dw 0xffff // -0.702624
	dw 0x4766 // 
	dw 0xffff // -0.721105
	dw 0x4295 // 
	dw 0xffff // -0.739916
	dw 0x3dad // 
	dw 0xffff // -0.759072
	dw 0x38ae // 
	dw 0xffff // -0.778587
	dw 0x3397 // 
	dw 0xffff // -0.798479
	dw 0x2e65 // 
	dw 0xffff // -0.818765
	dw 0x2919 // 
	dw 0xffff // -0.839462
	dw 0x23b0 // 
	dw 0xffff // -0.860590
	dw 0x1e2a // 
	dw 0xffff // -0.882168
	dw 0x1885 // 
	dw 0xffff // -0.904219
	dw 0x12c0 // 
	dw 0xffff // -0.926764
	dw 0xcd8 // 
	dw 0xffff // -0.949828
	dw 0x6cd // 
	dw 0xffff // -0.973436
	dw 0x9c // 
	dw 0xffff // -0.997614
	dw 0xfa45 // 
	dw 0xfffe // -1.022391
	dw 0xf3c4 // 
	dw 0xfffe // -1.047798
	dw 0xed17 // 
	dw 0xfffe // -1.073866
	dw 0xe63d // 
	dw 0xfffe // -1.100630
	dw 0xdf33 // 
	dw 0xfffe // -1.128126
	dw 0xd7f7 // 
	dw 0xfffe // -1.156395
	dw 0xd085 // 
	dw 0xfffe // -1.185477
	dw 0xc8da // 
	dw 0xfffe // -1.215417
	dw 0xc0f5 // 
	dw 0xfffe // -1.246263
	dw 0xb8d1 // 
	dw 0xfffe // -1.278067
	dw 0xb06a // 
	dw 0xfffe // -1.310884
	dw 0xa7bd // 
	dw 0xfffe // -1.344774
	dw 0x9ec5 // 
	dw 0xfffe // -1.379800
	dw 0x957f // 
	dw 0xfffe // -1.416033
	dw 0x8be4 // 
	dw 0xfffe // -1.453546
	dw 0x81f1 // 
	dw 0xfffe // -1.492421
	dw 0x779e // 
	dw 0xfffe // -1.532747
	dw 0x6ce6 // 
	dw 0xfffe // -1.574617
	dw 0x61c2 // 
	dw 0xfffe // -1.618137
	dw 0x562a // 
	dw 0xfffe // -1.663420
	dw 0x4a17 // 
	dw 0xfffe // -1.710589
	dw 0x3d7f // 
	dw 0xfffe // -1.759780
	dw 0x3059 // 
	dw 0xfffe // -1.811141
	dw 0x229a // 
	dw 0xfffe // -1.864836
	dw 0x1436 // 
	dw 0xfffe // -1.921046
	dw 0x521 // 
	dw 0xfffe // -1.979968
	dw 0xf54b // 
	dw 0xfffd // -2.041823
	dw 0xe4a5 // 
	dw 0xfffd // -2.106857
	dw 0xd31d // 
	dw 0xfffd // -2.175341
	dw 0xc09f // 
	dw 0xfffd // -2.247580
	dw 0xad14 // 
	dw 0xfffd // -2.323915
	dw 0x9864 // 
	dw 0xfffd // -2.404730
	dw 0x8271 // 
	dw 0xfffd // -2.490457
	dw 0x6b1d // 
	dw 0xfffd // -2.581587
	dw 0x5242 // 
	dw 0xfffd // -2.678677
	dw 0x37b7 // 
	dw 0xfffd // -2.782364
	dw 0x1b4c // 
	dw 0xfffd // -2.893379
	dw 0xfcc9 // 
	dw 0xfffc // -3.012564
	dw 0xdbee // 
	dw 0xfffc // -3.140895
	dw 0xb872 // 
	dw 0xfffc // -3.279511
	dw 0x91fc // 
	dw 0xfffc // -3.429746
	dw 0x6825 // 
	dw 0xfffc // -3.593178
	dw 0x3a73 // 
	dw 0xfffc // -3.771680
	dw 0x852 // 
	dw 0xfffc // -3.967500
	dw 0xd110 // 
	dw 0xfffb // -4.183355
	dw 0x93d3 // 
	dw 0xfffb // -4.422560
	dw 0x4f90 // 
	dw 0xfffb // -4.689208
	dw 0x2f8 // 
	dw 0xfffb // -4.988401
	dw 0xac64 // 
	dw 0xfffa // -5.326596
	dw 0x49b5 // 
	dw 0xfffa // -5.712074
	dw 0xd828 // 
	dw 0xfff9 // -6.155640
	dw 0x540e // 
	dw 0xfff9 // -6.671660
	dw 0xb868 // 
	dw 0xfff8 // -7.279666
	dw 0xfe3c // 
	dw 0xfff7 // -8.006902
	dw 0x1b82 // 
	dw 0xfff7 // -8.892546
	dw 0x144 // 
	dw 0xfff6 // -9.995053
	dw 0x9826 // 
	dw 0xfff4 // -11.405675
	dw 0xb98c // 
	dw 0xfff2 // -13.275205
	dw 0x20c3 // 
	dw 0xfff0 // -15.872022
	dw 0x468b // 
	dw 0xffec // -19.724440
	dw 0xf6cb // 
	dw 0xffe5 // -26.035972
	dw 0xbac6 // 
	dw 0xffd9 // -38.270410
	dw 0xd878 // 
	dw 0xffb7 // -72.154415

	.end
