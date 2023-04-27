#include "app.h"
#include <fstream>
#include <sstream>
#include "Shader.h"

App::App(GLchar * vertexStr, GLchar * fragmentStr)
{
    this->m_vertexStr = vertexStr;
    this->m_fragmentStr = fragmentStr;
}

void App::framebuffer_size_callback(GLFWwindow* window, int width, int height)
{
    glViewport(0, 0, width, height);
}

void App::processInput(GLFWwindow *window)
{
    if (glfwGetKey(window, GLFW_KEY_ESCAPE) == GLFW_PRESS)
        glfwSetWindowShouldClose(window, true);
    if (glfwGetKey(window, GLFW_KEY_SPACE) == GLFW_PRESS)
    {
        Shader shader(this->m_vertexStr, this->m_fragmentStr);
        shader.use();
    }
}


