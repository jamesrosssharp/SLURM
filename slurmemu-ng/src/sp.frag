#version 430 core

in vec2 TexCoord;

layout(location = 0) out vec4 color;
//out vec4 color; 

uniform sampler2D mem_4bpp;
uniform sampler2D mem_5bpp;
uniform sampler2D sp_dat;


/*
   	static constexpr int kSpriteDataChannelX        = 0;
        static constexpr int kSpriteDataChannelEn       = 1;
        static constexpr int kSpriteDataChannelPalHi    = 2;
        static constexpr int kSpriteDataChannelStride   = 3;
        static constexpr int kSpriteDataChannelY        = 4;
        static constexpr int kSpriteDataChannelW        = 5;
        static constexpr int kSpriteDataChannelEndY     = 6;
        static constexpr int kSpriteDataChannelAddress     = 7;
        static constexpr int kSpriteDataChannel5bpp       = 8;
*/

const float kSpriteDataChannelX 	= 0.5 / 9.0;
const float kSpriteDataChannelEn 	= 1.5 / 9.0;
const float kSpriteDataChannelPalHi 	= 2.5 / 9.0;
const float kSpriteDataChannelStride 	= 3.5 / 9.0;
const float kSpriteDataChannelY 	= 4.5 / 9.0;
const float kSpriteDataChannelW 	= 5.5 / 9.0;
const float kSpriteDataChannelEndY 	= 6.5 / 9.0;
const float kSpriteDataChannelAddress 	= 7.5 / 9.0;
const float kSpriteDataChannel5bpp 	= 8.5 / 9.0;

layout(binding=0) buffer SSBOBlock {
   int collide[256]; 
};

void main()
{
	color.r = 0.0;

	int prevSp = 15;

	for (float spr = 0.0; spr < 1.0; spr += 1/256.0)
	{

		float en = texture(sp_dat, vec2(kSpriteDataChannelEn, spr)).r;
		
		if (en == 1.0)
		{

			float x = texture(sp_dat, vec2(kSpriteDataChannelX, spr)).r;
			float y = texture(sp_dat, vec2(kSpriteDataChannelY, spr)).r;
			float w = texture(sp_dat, vec2(kSpriteDataChannelW, spr)).r;
			float y2 = texture(sp_dat, vec2(kSpriteDataChannelEndY, spr)).r;
			float pal_hi = texture(sp_dat, vec2(kSpriteDataChannelPalHi, spr)).r;
			float stride = texture(sp_dat, vec2(kSpriteDataChannelStride, spr)).r;
			float address = texture(sp_dat, vec2(kSpriteDataChannelAddress, spr)).r; 
			float fivebpp = texture(sp_dat, vec2(kSpriteDataChannel5bpp, spr)).r; 

			float screen_X = TexCoord.x * 800.0;
			float screen_Y = TexCoord.y * 525.0;

			if (fivebpp == 0.0)
			{
				if ((screen_X >= x) && (screen_X <= x + w + 1.0) && (screen_Y >= y) && (screen_Y <= y2))
				{
					float addr = address + (floor(screen_Y - y)*stride/4.0);
					addr += (screen_X - x)/4.0; 

					float frac = fract(addr) * 4.0;

					vec2 t = vec2(fract(floor(addr) / 256.0), floor(addr/256.0) / 256.0);
					
					float val = 0;
					if ((0 < frac) && (frac <= 1))
						val = texture(mem_4bpp, t).a;
					else if ((1 < frac) && (frac <= 2))
						val = texture(mem_4bpp, t).b;
					else if ((2 < frac) && (frac <= 3))
						val = texture(mem_4bpp, t).g;
					else if ((3 < frac) && (frac <= 4))
						val = texture(mem_4bpp, t).r;

					if (val != 0.0)
				        {
						color.r = (floor(val * 15.0) / 255.0) + (pal_hi / 16.0);
						if (prevSp != 15)
						{
							atomicOr(collide[int(spr * 256.0)], 1 << prevSp);
						}
						prevSp = int(spr*16.0);
					}	
				}
			}
			else
			{
				if ((screen_X >= x) && (screen_X <= x + (w*3.0/4.0) + 1.0) && (screen_Y >= y) && (screen_Y <= y2))
				{

					float addr = address + (floor(floor(screen_Y - y)*stride/4.0));
					addr += (screen_X - x)/3.0; 

					float frac = fract(addr) * 3.0;

					vec2 t = vec2(fract(floor(addr) / 256.0), floor(addr/256.0) / 256.0);
					
					float val = 0;
					if ((0 < frac) && (frac < 1))
						val = texture(mem_5bpp, t).r;
					else if ((1 <= frac) && (frac < 2))
						val = texture(mem_5bpp, t).g;
					else if ((2 <= frac) && (frac < 3))
						val = texture(mem_5bpp, t).b;

					if (val != 0.0)
					{
					
						color.r = (floor(val * 31.5) / 255.0) + (floor(pal_hi / 2.0) / 8.0);
						if (prevSp != 15)
						{
							atomicOr(collide[int(spr * 256.0)], 1 << prevSp);
						}
						prevSp = int(spr*16.0);
					}

				}
			}
		}
	}

}
