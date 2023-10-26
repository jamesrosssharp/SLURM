#version 330 core

in vec2 TexCoord;

layout(location = 0) out vec4 color;
 
uniform sampler2D mem_4bpp;
uniform sampler2D mem_8bpp;

uniform float tilemap_addr;
uniform float tileset_addr;
uniform float pal_hi;
uniform float tile_size;
uniform float tilemap_x;
uniform float tilemap_y;
uniform float enable;


void main()
{
	if (enable == 0.0)
	{
		color.r = 0;
	}
	else
	{

		float addrm = tilemap_addr*2 + (floor((TexCoord.y*525.0 + tilemap_y)/tile_size)*64.0);
		addrm += ((TexCoord.x*800.0 + tilemap_x)/tile_size);

		vec2 tm = vec2(fract(floor(addrm)/256.0), floor(addrm/256.0)/512.0);

		float tile = texture(mem_8bpp, tm).r * 255.0;	

		if (tile != 255.0)
		{

			vec2 tilec = vec2(fract(tile / tile_size) * tile_size * tile_size, floor(tile/tile_size) * tile_size); 

			float screen_X = TexCoord.x*800.0 + tilemap_x;
			float screen_Y = floor(TexCoord.y*525.0 + tilemap_y);

			float tile_X = fract(screen_X / tile_size) * tile_size;
			float tile_Y = fract(screen_Y / tile_size) * tile_size;

			float addr = tileset_addr + (floor(tile_Y + tilec.y)*256.0/4.0);
			addr += (tile_X + tilec.x)/4.0; 

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
				color.r = (val * 15.0 / 255.0) + pal_hi;
			else
				color.r = 0.0;
		}
		else
		{ 
			color.r = 0.0;
		}
	}
}
