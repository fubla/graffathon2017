#pragma once
#include <glad\glad.h>
#include <GLFW\glfw3.h>
#include <string>

class App {

public:
    App(GLchar * vertexStr, GLchar * fragmentStr);
    static void framebuffer_size_callback(GLFWwindow* window, int width, int height);
    void processInput(GLFWwindow *window);
    GLchar * m_vertexStr; 
    GLchar * m_fragmentStr;
};
