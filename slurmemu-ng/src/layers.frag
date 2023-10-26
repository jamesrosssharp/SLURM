#version 330 core
out vec4 FragColor;
  
in vec3 ourColor;
in vec2 TexCoord;

uniform sampler2D BG0Texture;
uniform sampler2D BG1Texture;
uniform sampler2D SpritesTexture;
uniform sampler2D PaletteTexture;
//uniform sampler1D XPanTexture;
//uniform sampler1D AlphaOverrideTexture;
//uniform sampler2D CopperTexture; 

void main()
{
	vec2 t = TexCoord;
	t.x *= 0.5;
	
	t.y = 1.0 - t.y*0.5;
	float bg0 = texture(BG0Texture, t).r;
	float bg1 = texture(BG0Texture, t).r;
	float sp = texture(SpritesTexture, t).r;
	vec2  pal;


	pal.x = 0;

	if (bg0 != 0.0)
		pal.x = bg0;
	if (bg1 != 0.0)
		pal.x = bg1;
	if (sp != 0.0)
		pal.x = sp;

	pal.y = TexCoord.y;

	FragColor = texture(PaletteTexture, pal);

}
