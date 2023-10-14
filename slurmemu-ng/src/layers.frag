#version 330 core
out vec4 FragColor;
  
in vec3 ourColor;
in vec2 TexCoord;

uniform sampler2D BG0Texture;
//uniform sampler2D BG1Texture;
// uniform sampler2D SpriteTexture;
uniform sampler2D PaletteTexture;
//uniform sampler1D XPanTexture;
//uniform sampler1D AlphaOverrideTexture;
//uniform sampler2D CopperTexture; 

void main()
{
    vec2 t = TexCoord;
    t.x *= 0.5;
    float bg0 = texture(BG0Texture, t).r;
    vec2  pal; 
    pal.x = bg0;
    pal.y = TexCoord.y;

    FragColor = texture(PaletteTexture, pal);

    //FragColor = texture(PaletteTexture, TexCoord);
}
