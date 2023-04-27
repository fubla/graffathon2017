/* Credits for this file go to Xywzel */

#ifndef SHADER_H
#define SHADER_H

#include <glad\glad.h>

#include <string>
#include <fstream>
#include <sstream>
#include <iostream>

class Shader {
	public:
		GLuint program;
		Shader(const GLchar* vertexPath, const GLchar* fragmentPath);
		void use();

	private:
		std::string fileToString(const GLchar* path);
		void checkErrors(GLuint shader, std::string type);

};

#endif
