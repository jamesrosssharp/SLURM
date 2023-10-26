#version 330 core

in vec2 TexCoord;

//layout(location = 0) out vec4 color;
out vec4 color; 

uniform sampler2D mem_4bpp;
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
*/

const float kSpriteDataChannelX 	= 0.0 / 8.0;
const float kSpriteDataChannelEn 	= 1.0 / 8.0;
const float kSpriteDataChannelPalHi 	= 2.0 / 8.0;
const float kSpriteDataChannelStride 	= 3.0 / 8.0;
const float kSpriteDataChannelY 	= 4.0 / 8.0;
const float kSpriteDataChannelW 	= 5.0 / 8.0;
const float kSpriteDataChannelEndY 	= 6.0 / 8.0;
const float kSpriteDataChannelAddress 	= 7.0 / 8.0;

void main()
{

	for (float spr = 0.0; spr < 1.0; spr += 1/255.0)
	{

		float x = texture(sp_dat, vec2(spr, kSpriteDataChannelX)).r;
		float y = texture(sp_dat, vec2(spr, kSpriteDataChannelY)).r;
		float w = texture(sp_dat, vec2(spr, kSpriteDataChannelW)).r;
		float y2 = texture(sp_dat, vec2(spr, kSpriteDataChannelEndY)).r;

		float screen_X = TexCoord.x * 800.0;
		float screen_Y = TexCoord.y * 525.0;

		if ((screen_X >= x) && (screen_X <= (x+w)) && (screen_Y >= y) && (screen_Y <= y2))
			color.r = 1.0 / 255.0;
		else
			color.r = 0.0;
	}

	//color.r = texture(sp_dat, TexCoord).r;
}
