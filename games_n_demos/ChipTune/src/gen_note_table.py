#!/usr/bin/python3

#
#	Generate the note table.
#	
#	Note table is split into 2 parts: hi and low 16-bit values of note_freq / c5_note_freq * 65536.  
#
#


notes = [
#C0	16.35 	2109.89
16,
# C#0/Db0  	17.32 	1991.47
17,
#D0	18.35 	1879.69
18,
#D#0/Eb0  	19.45 	1774.20
19,
#E0	20.60 	1674.62
20,
#F0	21.83 	1580.63
21,
# F#0/Gb0  	23.12 	1491.91
23,
#G0	24.50 	1408.18
24,
# G#0/Ab0  	25.96 	1329.14
25,
#A0	27.50 	1254.55
27,
# A#0/Bb0  	29.14 	1184.13
29,
#B0	30.87 	1117.67
30,
#C1	32.70 	1054.94
32,
# C#1/Db1  	34.65 	995.73
34,
#D1	36.71 	939.85
36,
# D#1/Eb1  	38.89 	887.10
38,
#E1	41.20 	837.31
41,
#F1	43.65 	790.31
43,
# F#1/Gb1  	46.25 	745.96
46,
#G1	49.00 	704.09
49,
# G#1/Ab1  	51.91 	664.57
51,
#A1	55.00 	627.27
55,
# A#1/Bb1  	58.27 	592.07
58,
#B1	61.74 	558.84
61,
#C2	65.41 	527.47
65,
# C#2/Db2  	69.30 	497.87
69,
#D2	73.42 	469.92
73,
# D#2/Eb2  	77.78 	443.55
77,
#E2	82.41 	418.65
82,
#F2	87.31 	395.16
87,
# F#2/Gb2  	92.50 	372.98
92,
#G2	98.00 	352.04
98,
# G#2/Ab2  	103.83 	332.29
103,
#A2	110.00 	313.64
110,
# A#2/Bb2  	116.54 	296.03
116,
#B2	123.47 	279.42
123,
#C3	130.81 	263.74
130,
# C#3/Db3  	138.59 	248.93
138,
#D3	146.83 	234.96
146,
# D#3/Eb3  	155.56 	221.77
155,
#E3	164.81 	209.33
164,
#F3	174.61 	197.58
174,
# F#3/Gb3  	185.00 	186.49
185,
#G3	196.00 	176.02
196,
# G#3/Ab3  	207.65 	166.14
207,
#A3	220.00 	156.82
220,
# A#3/Bb3  	233.08 	148.02
233,
#B3	246.94 	139.71
246,
#C4	261.63 	131.87
261,
# C#4/Db4  	277.18 	124.47
277,
#D4	293.66 	117.48
293,
# D#4/Eb4  	311.13 	110.89
311,
#E4	329.63 	104.66
329,
#F4	349.23 	98.79
349,
# F#4/Gb4  	369.99 	93.24
369,
#G4	392.00 	88.01
392,
# G#4/Ab4  	415.30 	83.07
415,
#A4	440.00 	78.41
440,
# A#4/Bb4  	466.16 	74.01
466,
#B4	493.88 	69.85
493,
#C5	523.25 	65.93
523,
# C#5/Db5  	554.37 	62.23
554,
#D5	587.33 	58.74
587,
# D#5/Eb5  	622.25 	55.44
622,
#E5	659.25 	52.33
659,
#F5	698.46 	49.39
698,
# F#5/Gb5  	739.99 	46.62
739,
#G5	783.99 	44.01
783,
# G#5/Ab5  	830.61 	41.54
830,
#A5	880.00 	39.20
880,
# A#5/Bb5  	932.33 	37.00
932,
#B5	987.77 	34.93
987,
#C6	1046.50 	32.97
1046,
# C#6/Db6  	1108.73 	31.12
1108,
#D6	1174.66 	29.37
1174,
# D#6/Eb6  	1244.51 	27.72
1244,
#E6	1318.51 	26.17
1318,
#F6	1396.91 	24.70
1396,
# F#6/Gb6  	1479.98 	23.31
1479,
#G6	1567.98 	22.00
1567,
# G#6/Ab6  	1661.22 	20.77
1661,
#A6	1760.00 	19.60
1760,
# A#6/Bb6  	1864.66 	18.50
1864,
#B6	1975.53 	17.46
1975,
#C7	2093.00 	16.48
2093,
# C#7/Db7  	2217.46 	15.56
2217,
#D7	2349.32 	14.69
2349,
# D#7/Eb7  	2489.02 	13.86
2489,
#E7	2637.02 	13.08
2637,
#F7	2793.83 	12.35
2793,
# F#7/Gb7  	2959.96 	11.66
2959,
#G7	3135.96 	11.00
3135,
# G#7/Ab7  	3322.44 	10.38
3322,
#A7	3520.00 	9.80
3520,
# A#7/Bb7  	3729.31 	9.25
3729,
#B7	3951.07 	8.73
3951,
#C8	4186.01 	8.24
4186,
# C#8/Db8  	4434.92 	7.78
4434,
#D8	4698.63 	7.34
4698,
# D#8/Eb8  	4978.03 	6.93
4978,
#E8	5274.04 	6.54
5274,
#F8	5587.65 	6.17
5587,
# F#8/Gb8  	5919.91 	5.83
5919,
#G8	6271.93 	5.50
6271,
# G#8/Ab8  	6644.88 	5.19
6644,
#A8	7040.00 	4.90
7040,
# A#8/Bb8  	7458.62 	4.63
7458,
#B8	7902.13 	4.37
7902
]


note_table_hi = []
note_table_lo = []

C5_FREQ = 523

for note in notes:

	note_mul = note * 65536 // C5_FREQ
	note_table_hi.append(note_mul >> 16)
	note_table_lo.append(note_mul & 0xffff)

print("short note_table_hi[] = {")

i = 0
for hi in note_table_hi:
	print("\t%d," % hi, end = '')
	i += 1
	if i == 12:
		i = 0
		print("")


print("}")

i = 0
print("short note_table_lo[] = {")

for lo in note_table_lo:
	print("\t%d," % lo, end = '')
	i += 1
	if i == 12:
		i = 0
		print("")


print("}")


