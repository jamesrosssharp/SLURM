

struct slurmsng_header {
	char magic[8];
	unsigned char playlist_size;
	unsigned char num_samples;
	unsigned char num_patterns;
	unsigned char __pad;

	unsigned char initial_speed;
	unsigned char initial_tempo;
	unsigned short __pad2;

	unsigned short pl_offset_lo;
	unsigned short pl_offset_hi;

	unsigned short sample_offset_lo;
	unsigned short sample_offset_hi;

	unsigned short pattern_offset_lo;
	unsigned short pattern_offset_hi;
};

struct slurmsng_playlist {
	char magic[2];
	short chunklen;
};

struct slurmsng_sample {
	char magic[2];
	char bit_depth;
	char loop;
	unsigned short speed;
	unsigned short loop_start;
	unsigned short loop_end;
	unsigned short sample_len;
};

