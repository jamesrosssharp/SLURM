/*
 *
 *	Only include these tables in the music player.
 *
 *
 *
 */

const unsigned short slide_up_lo[256] = {
	0, 237, 474, 713, 953, 1193, 1435, 1677, 
	1920, 2164, 2409, 2654, 2901, 3149, 3397, 3646, 
	3896, 4148, 4400, 4653, 4906, 5161, 5417, 5673, 
	5931, 6189, 6449, 6709, 6971, 7233, 7496, 7760, 
	8025, 8291, 8558, 8826, 9095, 9365, 9636, 9908, 
	10181, 10455, 10729, 11005, 11282, 11560, 11839, 12119, 
	12399, 12681, 12964, 13248, 13533, 13819, 14106, 14394, 
	14683, 14973, 15264, 15557, 15850, 16144, 16440, 16736, 
	17034, 17332, 17632, 17933, 18235, 18538, 18842, 19147, 
	19453, 19761, 20069, 20379, 20689, 21001, 21314, 21628, 
	21944, 22260, 22577, 22896, 23216, 23537, 23859, 24182, 
	24507, 24833, 25159, 25487, 25817, 26147, 26479, 26811, 
	27145, 27481, 27817, 28155, 28493, 28834, 29175, 29517, 
	29861, 30206, 30552, 30900, 31249, 31599, 31950, 32303, 
	32657, 33012, 33368, 33726, 34085, 34445, 34807, 35170, 
	35534, 35899, 36266, 36634, 37004, 37375, 37747, 38121, 
	38495, 38872, 39249, 39628, 40009, 40390, 40773, 41158, 
	41544, 41931, 42320, 42710, 43101, 43494, 43889, 44284, 
	44681, 45080, 45480, 45882, 46285, 46689, 47095, 47502, 
	47911, 48321, 48733, 49146, 49561, 49978, 50395, 50815, 
	51235, 51658, 52082, 52507, 52934, 53362, 53792, 54224, 
	54657, 55092, 55528, 55966, 56405, 56846, 57289, 57733, 
	58179, 58626, 59075, 59526, 59978, 60432, 60888, 61345, 
	61804, 62265, 62727, 63191, 63656, 64124, 64593, 65063, 
	0, 474, 949, 1427, 1906, 2387, 2870, 3354, 
	3840, 4328, 4818, 5309, 5803, 6298, 6794, 7293, 
	7793, 8296, 8800, 9306, 9813, 10323, 10834, 11347, 
	11863, 12379, 12898, 13419, 13942, 14466, 14992, 15521, 
	16051, 16583, 17117, 17653, 18191, 18731, 19272, 19816, 
	20362, 20910, 21459, 22011, 22565, 23120, 23678, 24238, 
	24799, 25363, 25929, 26497, 27066, 27638, 28212, 28788, 
	29367, 29947, 30529, 31114, 31700, 32289, 32880, 33473, 
	};
const unsigned short slide_up_hi[256] = {
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 
	2, 2, 2, 2, 2, 2, 2, 2, 
	2, 2, 2, 2, 2, 2, 2, 2, 
	2, 2, 2, 2, 2, 2, 2, 2, 
	2, 2, 2, 2, 2, 2, 2, 2, 
	2, 2, 2, 2, 2, 2, 2, 2, 
	2, 2, 2, 2, 2, 2, 2, 2, 
	2, 2, 2, 2, 2, 2, 2, 2, 
	2, 2, 2, 2, 2, 2, 2, 2, 
	};
const unsigned short slide_down_lo[256] = {
	0, 65299, 65064, 64830, 64596, 64363, 64131, 63900, 
	63670, 63440, 63212, 62984, 62757, 62531, 62305, 62081, 
	61857, 61634, 61412, 61191, 60970, 60751, 60532, 60314, 
	60096, 59880, 59664, 59449, 59235, 59021, 58809, 58597, 
	58385, 58175, 57965, 57757, 57548, 57341, 57134, 56928, 
	56723, 56519, 56315, 56112, 55910, 55709, 55508, 55308, 
	55108, 54910, 54712, 54515, 54318, 54123, 53928, 53733, 
	53540, 53347, 53154, 52963, 52772, 52582, 52392, 52204, 
	52015, 51828, 51641, 51455, 51270, 51085, 50901, 50717, 
	50535, 50353, 50171, 49990, 49810, 49631, 49452, 49274, 
	49096, 48919, 48743, 48567, 48392, 48218, 48044, 47871, 
	47698, 47526, 47355, 47185, 47014, 46845, 46676, 46508, 
	46340, 46173, 46007, 45841, 45676, 45511, 45347, 45184, 
	45021, 44859, 44697, 44536, 44376, 44216, 44056, 43898, 
	43740, 43582, 43425, 43268, 43112, 42957, 42802, 42648, 
	42494, 42341, 42189, 42037, 41885, 41734, 41584, 41434, 
	41285, 41136, 40988, 40840, 40693, 40546, 40400, 40254, 
	40109, 39965, 39821, 39677, 39534, 39392, 39250, 39108, 
	38967, 38827, 38687, 38548, 38409, 38270, 38132, 37995, 
	37858, 37722, 37586, 37450, 37315, 37181, 37047, 36913, 
	36780, 36648, 36516, 36384, 36253, 36122, 35992, 35862, 
	35733, 35604, 35476, 35348, 35221, 35094, 34968, 34842, 
	34716, 34591, 34466, 34342, 34218, 34095, 33972, 33850, 
	33728, 33606, 33485, 33364, 33244, 33124, 33005, 32886, 
	32768, 32649, 32532, 32415, 32298, 32181, 32065, 31950, 
	31835, 31720, 31606, 31492, 31378, 31265, 31152, 31040, 
	30928, 30817, 30706, 30595, 30485, 30375, 30266, 30157, 
	30048, 29940, 29832, 29724, 29617, 29510, 29404, 29298, 
	29192, 29087, 28982, 28878, 28774, 28670, 28567, 28464, 
	28361, 28259, 28157, 28056, 27955, 27854, 27754, 27654, 
	27554, 27455, 27356, 27257, 27159, 27061, 26964, 26866, 
	26770, 26673, 26577, 26481, 26386, 26291, 26196, 26102, 
	};
const unsigned short slide_down_hi[256] = {
	1, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	};
