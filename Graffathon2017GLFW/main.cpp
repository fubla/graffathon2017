#include <glad\glad.h>
#include <GLFW\glfw3.h>
#include <iostream>

#include "Shader.h"
#include "app.h"
#include "sync\sync.h"

#include <Mmsystem.h>
#include <mciapi.h>
//these two headers are already included in the <Windows.h> header
#pragma comment(lib, "Winmm.lib")

#define WINDOW_WIDTH 820
#define WINDOW_HEIGHT 640
#define PI  3.141592653589793238L

const float bpm = 150.0f; /* beats per minute */
const int rpb = 8; /* rows per beat */
const double row_rate = (double(bpm) / 60) * rpb;



int main()
{
    /*struct sync_device *rocket;
    rocket = sync_create_device("sync");
    if (sync_connect(rocket, "localhost",
                     SYNC_DEFAULT_PORT))
    {
        std::cout << "Failed to connect to rocket" << std::endl;
        return -1;
    }
*/

    mciSendString("open \"audio.mp3\" type mpegvideo alias mp3", NULL, 0, NULL);


    GLchar * vertexStr = "vertex.glsl";
    GLchar * fragmentStr = "fragment.glsl";

    App app(vertexStr, fragmentStr);

    glfwInit();
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);

    GLFWwindow* window = glfwCreateWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Graffathon2017Demo", NULL/*glfwGetPrimaryMonitor()*/, NULL);
    if (window == NULL)
    {
        std::cout << "Failed to create GLFW window" << std::endl;
        glfwTerminate();
        return -1;
    }
    glfwMakeContextCurrent(window);

    if (!gladLoadGLLoader((GLADloadproc)glfwGetProcAddress))
    {
        std::cout << "Failed to initialize GLAD" << std::endl;
        return -1;
    }

    glfwSwapInterval(1);

    Shader shader(vertexStr, fragmentStr);
    shader.use();

    glViewport(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT);

    glfwSetFramebufferSizeCallback(window, App::framebuffer_size_callback);

    float quad[] = {
        -1.0f, -1.0f, 0.0f,
        1.0f, -1.0f, 0.0f,
        1.0f,  1.0f, 0.0f,
        -1.0f, 1.0f, 0.0f
    };

    unsigned int indices[] = {
        0, 1, 2,
        2, 0, 3
    };

    // create vertex array object
    unsigned int VAO;
    glGenVertexArrays(1, &VAO);

    // bind vertex array object
    glBindVertexArray(VAO);

    // create vertex buffer and bind it
    unsigned int VBO;
    glGenBuffers(1, &VBO);
    glBindBuffer(GL_ARRAY_BUFFER, VBO);
    glBufferData(GL_ARRAY_BUFFER, sizeof(quad), quad, GL_STATIC_DRAW);

    // create element buffer object 
    unsigned int EBO;
    glGenBuffers(1, &EBO);

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);

    //// create vertex shader
    //unsigned int vertexShader;
    //vertexShader = glCreateShader(GL_VERTEX_SHADER);

    //// compile vertex shader
    //glShaderSource(vertexShader, 1, &vertexShaderSource, NULL);
    //glCompileShader(vertexShader);

    //// check if succesful
    //int  success;
    //char infoLog[512];
    //glGetShaderiv(vertexShader, GL_COMPILE_STATUS, &success);

    //// check for errors
    //if (!success)
    //{
    //    glGetShaderInfoLog(vertexShader, 512, NULL, infoLog);
    //    std::cout << "ERROR::SHADER::VERTEX::COMPILATION_FAILED\n" << infoLog << std::endl;
    //}
    //unsigned int fragmentShader;
    //fragmentShader = glCreateShader(GL_FRAGMENT_SHADER);
    //glShaderSource(fragmentShader, 1, &fragmentShaderSource, NULL);
    //glCompileShader(fragmentShader);

    //// check if succesful
    //glGetShaderiv(fragmentShader, GL_COMPILE_STATUS, &success);

    //// check for errors
    //if (!success)
    //{
    //    glGetShaderInfoLog(fragmentShader, 512, NULL, infoLog);
    //    std::cout << "ERROR::SHADER::FRAGMENT::COMPILATION_FAILED\n" << infoLog << std::endl;
    //}

    //// create shader program
    //unsigned int shaderProgram;
    //shaderProgram = glCreateProgram();

    //// attach shaders to shader program and link
    //glAttachShader(shaderProgram, vertexShader);
    //glAttachShader(shaderProgram, fragmentShader);
    //glLinkProgram(shaderProgram);

    //// test for linkin errors
    //glGetProgramiv(shaderProgram, GL_LINK_STATUS, &success);
    //if (!success)
    //{
    //    glGetProgramInfoLog(shaderProgram, 512, NULL, infoLog);
    //    std::cout << "ERROR::SHADER::PROGRAM::COMPILATION_FAILED\n" << infoLog << std::endl;
    //}


    //// delete shaders as they are no longer needed
    //glDeleteShader(vertexShader);
    //glDeleteShader(fragmentShader);

    // tell OpenGL how to interpret data in vertex buffer object and enable attributes
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(float), (void*)0);
    glEnableVertexAttribArray(0);

    // set clear color
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);


    //glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);

    //mciSendString("play mp3 repeat", NULL, 0, NULL);

    // render loop
    while (!glfwWindowShouldClose(window))
    {
        app.processInput(window);

        // clear screen
        glClear(GL_COLOR_BUFFER_BIT);


        float timeValue = glfwGetTime();
        int uniform_timeValue = glGetUniformLocation(shader.program, "timeValue");
        glUniform1f(uniform_timeValue, timeValue);
        int uniform_windowSize = glGetUniformLocation(shader.program, "windowSize");
        glUniform2f(uniform_windowSize, WINDOW_WIDTH, WINDOW_HEIGHT);
        int uniform_ambient = glGetUniformLocation(shader.program, "material.ambient");
        glUniform3f(uniform_ambient, 1.0f, 0.5f, 0.31f);
        int uniform_diffuse = glGetUniformLocation(shader.program, "material.diffuse");
        glUniform3f(uniform_diffuse, 1.0f, 0.5f, 0.31f);
        int uniform_specular = glGetUniformLocation(shader.program, "material.specular");
        glUniform3f(uniform_specular, 0.5f, 0.5f, 0.5f);
        int uniform_shininess = glGetUniformLocation(shader.program, "material.shininess");
        glUniform1f(uniform_shininess, 32.0f);

        // draw
        glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);

        glfwSwapBuffers(window);
        glfwPollEvents();

        /*if (timeValue >= 30)
            break;*/
    }

    glfwTerminate();
    return 0;
}