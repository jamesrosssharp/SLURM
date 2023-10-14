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

Renderer::Renderer()    :
    m_vertexData{-1, -1, 0, 0, 1,
                  1, -1, 0, 1, 1,
                  1,  1, 0, 1, 0,
                  -1, 1, 0, 0, 0},
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

}
        
Renderer::~Renderer()
{


}

void Renderer::renderScene(Slurm16SoC* soc, int w, int h)
{
    glViewport(0, 0, w, h);

    // Render copper

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
                 GL_RGBA, GL_UNSIGNED_BYTE, soc->getGfxCore()->getCopperBG());

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
    glBindTexture(GL_TEXTURE_2D, m_textures[kBG0Texture]);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST); 
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RED, 800, 525, 0,
                 GL_RED, GL_UNSIGNED_BYTE, soc->getGfxCore()->getBG0Texture());


    glUniform1i(glGetUniformLocation(m_layersShaderProgram, "BG0Texture"), 0);

    // Load palette texture

    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, m_textures[kPaletteTexture]);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST); 
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 256, 525, 0,
                 GL_BGRA, GL_UNSIGNED_SHORT_4_4_4_4_REV, soc->getGfxCore()->getPaletteTexture());

    glUniform1i(glGetUniformLocation(m_layersShaderProgram, "PaletteTexture"), 1);


    // Draw

    glBindVertexArray(m_vertexArrayID);
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);

    glDisable(GL_BLEND);

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


