/* vim: set et ts=4 sw=4: */

/*
	slurmemu-ng : Next-Generation SlURM16 Emulator

Renderer.cpp: OpenGL renderer

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

#include "Renderer.h"
#include <stdexcept>
#include <fstream>
#include <sstream>

#include <cassert>
#include <chrono>

#include "GFXConst.h"
#include <string.h>

static const char* vertex_shader =
"#version 330 core                                                     \n"
"                                                                      \n"
"// Input vertex data, different for all executions of this shader.    \n"
"layout(location = 0) in vec3 vertexPosition_modelspace;               \n"
"layout (location = 1) in vec2 aTexCoord;                              \n"
"                                                                      \n"
"out vec2 TexCoord;                                                    \n"
"                                                                      \n"
"void main(){                                                          \n"
"                                                                      \n"
"    gl_Position.xyz = vertexPosition_modelspace;                      \n"
"    gl_Position.w = 1.0;                                              \n"
"    TexCoord = aTexCoord;                                             \n"
"                                                                      \n"
"}                                                                     \n";

static const char* vanilla_fragment_shader  =
"#version 330 core                                                     \n"
"out vec4 FragColor;                                                   \n"
"                                                                      \n"
"in vec3 ourColor;                                                     \n"
"in vec2 TexCoord;                                                     \n"
"                                                                      \n"
"uniform sampler2D texture1;                                           \n"
"                                                                      \n"
"void main()                                                           \n"
"{                                                                     \n"
"    FragColor = texture(texture1, TexCoord);                          \n"
"}                                                                     \n";

static constexpr float minTX = (float)H_BACK_PORCH / (float)TOTAL_X;
static constexpr float minTY = (float)V_BACK_PORCH / (float)TOTAL_Y;
static constexpr float maxTX = 1.0 - ((float)H_FRONT_PORCH + (float)H_SYNC_PULSE) / (float)TOTAL_X;
static constexpr float maxTY = 1.0 - ((float)V_FRONT_PORCH + (float)V_SYNC_PULSE) / (float)TOTAL_Y;

static constexpr float minTX2 = 0.0;
static constexpr float minTY2 = 0.0;
static constexpr float maxTX2 = 1.0;
static constexpr float maxTY2 = 1.0;

Renderer::Renderer()    :
    m_vertexData{-1, -1, 0, minTX2, minTY2,
                  1, -1, 0, maxTX2, minTY2,
                  1,  1, 0, maxTX2, maxTY2,
                  -1, 1, 0, minTX2, maxTY2},
    
   m_vertexData2{-1, -1, 0, minTX, maxTY,
                  1, -1, 0, maxTX, maxTY,
                  1,  1, 0, maxTX, minTY,
                  -1, 1, 0, minTX, minTY},
   
    m_indexData{0, 1, 2, 0, 2, 3}
{

    // Compile shaders

    m_copperShaderProgram = loadShaders(vertex_shader, vanilla_fragment_shader);

    std::string fragmentShaderCode;
    std::ifstream fragmentShaderStream("src/layers.frag", std::ios::in);
    if(fragmentShaderStream.is_open()) {
		std::stringstream sstr;
		sstr << fragmentShaderStream.rdbuf();
		fragmentShaderCode = sstr.str();
		fragmentShaderStream.close();
    }
    else
    {
        throw std::runtime_error("Could not load fragment shader");
    }    

    m_layersShaderProgram = loadShaders(vertex_shader, fragmentShaderCode.c_str());

    std::string bgFragmentShaderCode;
    std::ifstream bgFragmentShaderStream("src/bg.frag", std::ios::in);
    if(bgFragmentShaderStream.is_open()) {
		std::stringstream sstr;
		sstr << bgFragmentShaderStream.rdbuf();
		bgFragmentShaderCode = sstr.str();
		bgFragmentShaderStream.close();
    }
    else
    {
        throw std::runtime_error("Could not load fragment shader");
    }    

    m_backgroundShaderProgram = loadShaders(vertex_shader, bgFragmentShaderCode.c_str());

    std::string spFragmentShaderCode;
    std::ifstream spFragmentShaderStream("src/sp.frag", std::ios::in);
    if(spFragmentShaderStream.is_open()) {
		std::stringstream sstr;
		sstr << spFragmentShaderStream.rdbuf();
		spFragmentShaderCode = sstr.str();
		spFragmentShaderStream.close();
    }
    else
    {
        throw std::runtime_error("Could not load fragment shader");
    }    

    m_spriteShaderProgram = loadShaders(vertex_shader, spFragmentShaderCode.c_str());

    // Create vertex array

    glGenVertexArrays(1, &m_vertexArrayID);
	glBindVertexArray(m_vertexArrayID);
 
    glGenBuffers(1, &m_vertexBufferID);
	glBindBuffer(GL_ARRAY_BUFFER, m_vertexBufferID);
	glBufferData(GL_ARRAY_BUFFER, m_vertexData.size() * sizeof(GLfloat), m_vertexData.data(), GL_STATIC_DRAW);

    glGenBuffers(1, &m_indexBufferID);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, m_indexBufferID);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, m_indexData.size() * sizeof(GLuint), m_indexData.data(), GL_STATIC_DRAW);

    glVertexAttribPointer(
        0,                  // attribute 0. No particular reason for 0, but must match the layout in the shader.
        3,                  // size
        GL_FLOAT,           // type
        GL_FALSE,           // normalized?
        5*sizeof(GLfloat),                  // stride
        (void*)0            // array buffer offset
    );
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(
        1,                  // 
        2,                  // size
        GL_FLOAT,           // type
        GL_FALSE,           // normalized?
        5*sizeof(GLfloat),                  // stride
        (void*)(sizeof(GLfloat)*3)            // array buffer offset
    );
    glEnableVertexAttribArray(1);

    // Generate textures

    glGenTextures(kNumTextures, m_textures);

    // Create framebuffer

    glGenFramebuffers(1, &m_framebuffer);

    // Set up render to framebuffer for BG0

    glBindTexture(GL_TEXTURE_2D, m_textures[kBG0TextureOut]);

    glTexImage2D(GL_TEXTURE_2D, 0, GL_RED, TOTAL_X, TOTAL_Y, 0, GL_RED, GL_UNSIGNED_BYTE, 0);

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);

    glBindTexture(GL_TEXTURE_2D, m_textures[kBG1TextureOut]);

    glTexImage2D(GL_TEXTURE_2D, 0, GL_RED, TOTAL_X, TOTAL_Y, 0, GL_RED, GL_UNSIGNED_BYTE, 0);

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);

    glBindTexture(GL_TEXTURE_2D, m_textures[kSpriteTextureOut]);

    glTexImage2D(GL_TEXTURE_2D, 0, GL_RED, TOTAL_X, TOTAL_Y, 0, GL_RED, GL_UNSIGNED_BYTE, 0);

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);

    glGenBuffers(2, m_ssbo);
    m_fence[0] = m_fence[1] = 0;
    m_frame = 0;

}
        
Renderer::~Renderer()
{


}

float Renderer::renderScene(const FrameSnapshot& s, int w, int h,
                            std::uint32_t* collisions, bool& gotCollisions)
{
    
    std::chrono::time_point<std::chrono::high_resolution_clock> oldTime = std::chrono::high_resolution_clock::now();

    // Read last frame's sprite collisions, if the GPU has finished with
    // them: never wait for it

    int cur = m_frame & 1, prev = cur ^ 1;

    m_frame++;
    gotCollisions = false;

    if (m_fence[prev])
    {
        GLenum r = glClientWaitSync(m_fence[prev], 0, 0);

        if (r == GL_ALREADY_SIGNALED || r == GL_CONDITION_SATISFIED)
        {
            void* p = glMapNamedBufferRange(m_ssbo[prev], 0, sizeof(m_collisionSSBO), GL_MAP_READ_BIT);

            if (p)
            {
                memcpy(collisions, p, sizeof(m_collisionSSBO));
                gotCollisions = true;
            }
            glUnmapNamedBuffer(m_ssbo[prev]);
        }

        glDeleteSync(m_fence[prev]);
        m_fence[prev] = 0;
    }


    // Render BG0
  
    glBindFramebuffer(GL_FRAMEBUFFER, m_framebuffer);
    glViewport(0, 0, TOTAL_X, TOTAL_Y); 
   
    glBindBuffer(GL_ARRAY_BUFFER, m_vertexBufferID);
	glBufferData(GL_ARRAY_BUFFER, m_vertexData.size() * sizeof(GLfloat), m_vertexData.data(), GL_STATIC_DRAW);

    glFramebufferTexture(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, m_textures[kBG0TextureOut], 0);

    // Set the list of draw buffers.
    GLenum DrawBuffers[1] = {GL_COLOR_ATTACHMENT0};
    glDrawBuffers(1, DrawBuffers);

    assert(glCheckFramebufferStatus(GL_FRAMEBUFFER) == GL_FRAMEBUFFER_COMPLETE);
    
    glUseProgram(m_backgroundShaderProgram);

    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, m_textures[kMem4bppTexture]);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST); 
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 256, 256, 0,
                 GL_RGBA, GL_UNSIGNED_SHORT_4_4_4_4, s.mem);
    
    int err = glGetError();
    if (err)
        printf("Error: %x\n", err);
    assert(err == GL_NO_ERROR);
    
    glUniform1i(glGetUniformLocation(m_backgroundShaderProgram, "mem_4bpp"), 1);
    assert(glGetError() == GL_NO_ERROR);

    glActiveTexture(GL_TEXTURE2);
    glBindTexture(GL_TEXTURE_2D, m_textures[kMem8bppTexture]);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST); 
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RED, 256, 512, 0,
                 GL_RED, GL_UNSIGNED_BYTE, s.mem);

    glUniform1i(glGetUniformLocation(m_backgroundShaderProgram, "mem_8bpp"), 2);

    
    // Render background layers 0 and 1 (each into its own texture)
    for (int layer = 0; layer < 2; layer++)
    {
        const BGLayerSnapshot& bg = s.bg[layer];

        glFramebufferTexture(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, m_textures[layer == 0 ? kBG0TextureOut : kBG1TextureOut], 0);

        glUniform1f(glGetUniformLocation(m_backgroundShaderProgram, "tilemap_addr"), bg.tilemap_addr);
        glUniform1f(glGetUniformLocation(m_backgroundShaderProgram, "tileset_addr"), bg.tileset_addr);
        glUniform1f(glGetUniformLocation(m_backgroundShaderProgram, "pal_hi"), bg.pal_hi);
        glUniform1f(glGetUniformLocation(m_backgroundShaderProgram, "tile_size"), bg.tile_size);
        glUniform1f(glGetUniformLocation(m_backgroundShaderProgram, "tilemap_x"), bg.tilemap_x);
        glUniform1f(glGetUniformLocation(m_backgroundShaderProgram, "tilemap_y"), bg.tilemap_y);
        glUniform1f(glGetUniformLocation(m_backgroundShaderProgram, "row_tiles"), bg.row_tiles);
        glUniform1f(glGetUniformLocation(m_backgroundShaderProgram, "enable"), bg.enable);

        glBindVertexArray(m_vertexArrayID);
        glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);
    }


    // Render sprites

    glFramebufferTexture(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, m_textures[kSpriteTextureOut], 0);

    glUseProgram(m_spriteShaderProgram);
    
    glActiveTexture(GL_TEXTURE3);
    glBindTexture(GL_TEXTURE_2D, m_textures[kSpriteDataTexture]);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST); 
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_R32F, 9, 256, 0,
                 GL_RED, GL_FLOAT, s.sprites);
   
    glActiveTexture(GL_TEXTURE4);
    glBindTexture(GL_TEXTURE_2D, m_textures[kMem5bppTexture]);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST); 
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST);
     glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 256, 256, 0,
                 GL_RGBA, GL_UNSIGNED_SHORT_1_5_5_5_REV, s.mem);
    
    glUniform1i(glGetUniformLocation(m_spriteShaderProgram, "mem_4bpp"), 1);
    glUniform1i(glGetUniformLocation(m_spriteShaderProgram, "mem_5bpp"), 4);
    glUniform1i(glGetUniformLocation(m_spriteShaderProgram, "sp_dat"), 3);

    memset(m_collisionSSBO, 0, sizeof(m_collisionSSBO));
    glBindBuffer(GL_SHADER_STORAGE_BUFFER, m_ssbo[cur]);
    glBufferData(GL_SHADER_STORAGE_BUFFER, sizeof(m_collisionSSBO), &m_collisionSSBO, GL_DYNAMIC_READ);
    glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 0, m_ssbo[cur]);

    glBindVertexArray(m_vertexArrayID);
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);

    // The shader's writes to the collision buffer must be visible to the map
    // next frame; the fence says when they are done
    glMemoryBarrier(GL_BUFFER_UPDATE_BARRIER_BIT | GL_CLIENT_MAPPED_BUFFER_BARRIER_BIT);
    m_fence[cur] = glFenceSync(GL_SYNC_GPU_COMMANDS_COMPLETE, 0);

    // Render copper
    glViewport(0, 0, w, h);

	glBindBuffer(GL_ARRAY_BUFFER, m_vertexBufferID);
	glBufferData(GL_ARRAY_BUFFER, m_vertexData2.size() * sizeof(GLfloat), m_vertexData2.data(), GL_STATIC_DRAW);

    glBindFramebuffer(GL_FRAMEBUFFER, 0);

        // bind shader
    glUseProgram(m_copperShaderProgram);

        // load vertex array
    glBindBuffer(GL_ARRAY_BUFFER, m_vertexBufferID);
    
    glUniform1i(glGetUniformLocation(m_copperShaderProgram, "texture1"), 0);

        // Load the Copper texture
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, m_textures[kCopperTexture]); 

    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST); 
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST);

    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 800, 525, 0,
                 GL_RGBA, GL_UNSIGNED_BYTE, s.copperBG);

    glBindVertexArray(m_vertexArrayID);
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);

    glEnable(GL_BLEND); //Enable blending.
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA); //Set blending function.

    // Render layers

    glUseProgram(m_layersShaderProgram);

    // load vertex array
    glBindBuffer(GL_ARRAY_BUFFER, m_vertexBufferID);
    
    // Load BG0 texture
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, m_textures[kBG0TextureOut]);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST); 
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST);

    glUniform1i(glGetUniformLocation(m_layersShaderProgram, "BG0Texture"), 0);
    
    // Load BG1 texture
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, m_textures[kBG1TextureOut]);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST); 
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST);


    glUniform1i(glGetUniformLocation(m_layersShaderProgram, "BG1Texture"), 1);

    // Load Sprites texture
    glActiveTexture(GL_TEXTURE3);
    glBindTexture(GL_TEXTURE_2D, m_textures[kSpriteTextureOut]);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST); 
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST);

    glUniform1i(glGetUniformLocation(m_layersShaderProgram, "SpritesTexture"), 3);
 
    // Load palette texture

    glActiveTexture(GL_TEXTURE2);
    glBindTexture(GL_TEXTURE_2D, m_textures[kPaletteTexture]);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST); 
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 256, 525, 0,
                 GL_BGRA, GL_UNSIGNED_SHORT_4_4_4_4_REV, s.palette);

    glUniform1i(glGetUniformLocation(m_layersShaderProgram, "PaletteTexture"), 2);

    // Load alpha override texture

    glActiveTexture(GL_TEXTURE4);
    glBindTexture(GL_TEXTURE_2D, m_textures[kAlphaOverrideTexture]);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST); 
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RED, 2, 525, 0,
                 GL_RED, GL_FLOAT, s.alphaOverride);

    // Load x pan texture
    glActiveTexture(GL_TEXTURE5);
    glBindTexture(GL_TEXTURE_1D, m_textures[kXPanTexture]);
    glTexParameteri(GL_TEXTURE_1D,GL_TEXTURE_MAG_FILTER,GL_NEAREST); 
    glTexParameteri(GL_TEXTURE_1D,GL_TEXTURE_MIN_FILTER,GL_NEAREST);
    glTexImage1D(GL_TEXTURE_1D, 0, GL_R32F, 525, 0,
                 GL_RED, GL_FLOAT, s.xpan);



    glUniform1f(glGetUniformLocation(m_layersShaderProgram, "yFlip"), s.yFlip);
    glUniform1f(glGetUniformLocation(m_layersShaderProgram, "videoMode"), s.videoMode);
    glUniform1i(glGetUniformLocation(m_layersShaderProgram, "alphaOverride"), 4);
    glUniform1i(glGetUniformLocation(m_layersShaderProgram, "xpan"), 5);

    // Draw

    glBindVertexArray(m_vertexArrayID);
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);

    glDisable(GL_BLEND);

       
    auto msecs = std::chrono::duration_cast<std::chrono::milliseconds>(std::chrono::high_resolution_clock::now() - oldTime);
    return msecs.count();
}

GLuint Renderer::loadShaders(const char* vertex_shader, const char* fragment_shader)
{
    // Create the shaders
	GLuint VertexShaderID = glCreateShader(GL_VERTEX_SHADER);
	GLuint FragmentShaderID = glCreateShader(GL_FRAGMENT_SHADER);

	GLint Result = GL_FALSE;
	int InfoLogLength;

	// Compile Vertex Shader
	char const * VertexSourcePointer = vertex_shader;
	glShaderSource(VertexShaderID, 1, &VertexSourcePointer , NULL);
	glCompileShader(VertexShaderID);

	// Check Vertex Shader
	glGetShaderiv(VertexShaderID, GL_COMPILE_STATUS, &Result);
	glGetShaderiv(VertexShaderID, GL_INFO_LOG_LENGTH, &InfoLogLength);
	if ( InfoLogLength > 0 ){
		std::vector<char> VertexShaderErrorMessage(InfoLogLength+1);
		glGetShaderInfoLog(VertexShaderID, InfoLogLength, NULL, &VertexShaderErrorMessage[0]);
		printf("%s\n", &VertexShaderErrorMessage[0]);
	    throw std::runtime_error("Error compiling vertex shader");
    }

	// Compile Fragment Shader
	char const * FragmentSourcePointer = fragment_shader;
	glShaderSource(FragmentShaderID, 1, &FragmentSourcePointer , NULL);
	glCompileShader(FragmentShaderID);

	// Check Fragment Shader
	glGetShaderiv(FragmentShaderID, GL_COMPILE_STATUS, &Result);
	glGetShaderiv(FragmentShaderID, GL_INFO_LOG_LENGTH, &InfoLogLength);
	if ( InfoLogLength > 0 ){
		std::vector<char> FragmentShaderErrorMessage(InfoLogLength+1);
		glGetShaderInfoLog(FragmentShaderID, InfoLogLength, NULL, &FragmentShaderErrorMessage[0]);
		printf("%s\n", &FragmentShaderErrorMessage[0]);
	    throw std::runtime_error("Error compiling fragment shader");
	}

	// Link the program
	printf("Linking program\n");
	GLuint ProgramID = glCreateProgram();
	glAttachShader(ProgramID, VertexShaderID);
	glAttachShader(ProgramID, FragmentShaderID);
	glLinkProgram(ProgramID);

	// Check the program
	glGetProgramiv(ProgramID, GL_LINK_STATUS, &Result);
	glGetProgramiv(ProgramID, GL_INFO_LOG_LENGTH, &InfoLogLength);
	if ( InfoLogLength > 0 ){
		std::vector<char> ProgramErrorMessage(InfoLogLength+1);
		glGetProgramInfoLog(ProgramID, InfoLogLength, NULL, &ProgramErrorMessage[0]);
		printf("%s\n", &ProgramErrorMessage[0]);
	    throw std::runtime_error("Error linking shader");
	}

	glDetachShader(ProgramID, VertexShaderID);
	glDetachShader(ProgramID, FragmentShaderID);
	
	glDeleteShader(VertexShaderID);
	glDeleteShader(FragmentShaderID);

	return ProgramID;
}


