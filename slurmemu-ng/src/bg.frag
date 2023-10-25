#version 330 core
//out vec4 FragColor;

in vec2 TexCoord;

layout(location = 0) out vec4 color;
 
uniform sampler2D mem_4bpp;
uniform sampler1D mem_8bpp;

uniform float tilemap_addr;
uniform float tileset_addr;
uniform float pal_hi;

void main()
{
	float addr = tileset_addr + (floor(TexCoord.y*480.0)*256.0/4.0);
	addr += ((TexCoord.x*640.0)/4.0); 

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

	//FragColor = texture(palette, vec2((val * 15.0 / 255.0 ) + pal_hi, TexCoord.y));
}
