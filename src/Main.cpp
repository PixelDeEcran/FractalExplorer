#include <GL/glew.h>
#include <GLFW/glfw3.h>

#include <chrono>
#include <iomanip>

#include "DoubleDouble.h"
#include "opengl_utils/Renderer.h"
#include "opengl_utils/VertexBufferLayout.h"

#include "vendor/imgui/imgui.h"
#include "vendor/imgui/imgui_impl_glfw.h"
#include "vendor/imgui/imgui_impl_opengl3.h"
#include "vendor/imgui/imgui_internal.h"

const double PI = std::atan(1) * 4;

bool showConfigWindow = true;
bool isConfigWindowHovered = false;
bool isMaxIterationsAuto = true;

int fractalId = 0;
int precisionId = 0;

int maxIterations = 50;
float rotation = 0.0;
DoubleDouble radius = 8.0;
DoubleDouble x = -0.75;
DoubleDouble y = 0;
DoubleDouble zoom = 200;

float colorA[3] = { 0.5f, 0.5f, 0.5f };
float colorB[3] = { 0.5f, 0.5f, 0.5f };
float colorC[3] = { 1.0f, 1.0f, 1.0f };
float colorD[3] = { 0.0f, 0.1f, 0.2f };

DoubleDouble mandelbrot_z_r = 0.0;
DoubleDouble mandelbrot_z_i = 0.0;

DoubleDouble julia_c_r = 0.285;
DoubleDouble julia_c_i = 0.01;

void key_callback(GLFWwindow* window, int key, int scancode, int action, int mods)
{
	if (key == GLFW_KEY_SPACE && action == GLFW_PRESS)
	{
		showConfigWindow = !showConfigWindow;
	}
}

void scroll_callback(GLFWwindow* window, double xoffset, double yoffset)
{
	if (!isConfigWindowHovered)
	{
		double mouseX, mouseY;
		glfwGetCursorPos(window, &mouseX, &mouseY);
		int width, height;
		glfwGetWindowSize(window, &width, &height);

		DoubleDouble amountX = (DoubleDouble(mouseX - double(width) / 2) / zoom) * 0.1 * (signbit(yoffset) == 0 ? 1 : -1);
		DoubleDouble amountY = (DoubleDouble(mouseY - double(height) / 2) / zoom) * 0.1 * (signbit(yoffset) == 0 ? 1 : -1);
		
		x = x + (amountX * cos(rotation) - amountY * sin(rotation));
		y = y + (amountX * sin(rotation) + amountY * cos(rotation));
		
		if (yoffset > 0)
		{
			zoom = zoom + (zoom * 0.1 * abs(yoffset));
		}
		else
		{
			zoom = zoom - (zoom * 0.1 * abs(yoffset));
		}
	}
}


int main()
{	
	glewExperimental = true;
	if (!glfwInit())
	{
		fprintf(stderr, "Failed to initialize GLFW\n");
		return -1;
	}

	glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
	glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
	glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);

	GLFWwindow* window = glfwCreateWindow(1280, 720, "Fractals", nullptr, nullptr);
	if (window == nullptr)
	{
		fprintf(stderr, "Failed to open GLFW window.\n");
		glfwTerminate();
		return -1;
	}
	glfwSetScrollCallback(window, scroll_callback);
	glfwSetKeyCallback(window, key_callback);

	glfwMakeContextCurrent(window);
	glfwSwapInterval(1);

	if (glewInit() != GLEW_OK)
	{
		fprintf(stderr, "Failed to initialize GLEW\n");
		return -1;
	}
	{
		Renderer renderer;
		
		float positions[] = {
			-1.0f, -1.0f,
			 1.0f, -1.0f,
			 1.0f,  1.0f,
			-1.0f,  1.0f,
		};

		unsigned int indices[] = {
			0, 1, 2,
			2, 3, 0
		};
		
		VertexArray va;
		VertexBuffer vb(positions, sizeof(float) * 4 * 2);

		VertexBufferLayout layout;
		layout.Push<float>(2);
		va.AddBuffer(vb, layout);

		IndexBuffer ib(indices, 6);

		Shader shaders[] = {
			Shader("ressources/shaders/Fractal32.shader"),
			Shader("ressources/shaders/Fractal64.shader"),
			Shader("ressources/shaders/Fractal128D.shader")
		};

		va.Unbind();
		vb.Unbind();
		ib.Unbind();
		
		ImGui::CreateContext();
		ImGui::StyleColorsDark();
		ImGui_ImplGlfw_InitForOpenGL(window, true);
		ImGui_ImplOpenGL3_Init("#version 150");

		double prevMouseX, prevMouseY;
		glfwGetCursorPos(window, &prevMouseX, &prevMouseY);

		while (!glfwWindowShouldClose(window))
		{
			/*
			 * PRE-RENDER
			 */

			double mouseX, mouseY;
			glfwGetCursorPos(window, &mouseX, &mouseY);

			int width, height;
			glfwGetWindowSize(window, &width, &height);

			if (!isConfigWindowHovered)
			{
				if (glfwGetMouseButton(window, GLFW_MOUSE_BUTTON_LEFT) == GLFW_PRESS)
				{
					DoubleDouble amountX = DoubleDouble(mouseX - prevMouseX) / zoom;
					DoubleDouble amountY = DoubleDouble(mouseY - prevMouseY) / zoom;

					x = x - (amountX * cos(rotation) - amountY * sin(rotation));
					y = y - (amountX * sin(rotation) + amountY * cos(rotation));
				}
				else if (glfwGetMouseButton(window, GLFW_MOUSE_BUTTON_RIGHT) == GLFW_PRESS)
				{
					rotation -= (mouseX - prevMouseX) * PI / 720;
				}
			}

			prevMouseX = mouseX;
			prevMouseY = mouseY;

			auto currentTime = std::chrono::duration_cast<std::chrono::milliseconds>(
				std::chrono::system_clock::now().time_since_epoch()).count();


			/*
			 * RENDER
			 */

			renderer.Clear();

			ImGui_ImplOpenGL3_NewFrame();
			ImGui_ImplGlfw_NewFrame();
			ImGui::NewFrame();

			if (showConfigWindow)
			{
				ImGui::Begin("Configuration (Press Space to Hide/Show)");
				
				if (ImGui::CollapsingHeader("General"))
				{
					ImGui::Dummy(ImVec2(0.0f, 20.0f));
					
					ImGui::Text("Fractal :"); ImGui::SameLine();
					ImGui::RadioButton("Mandelbrot", &fractalId, 0); ImGui::SameLine();
					ImGui::RadioButton("Julia", &fractalId, 1);

					ImGui::Dummy(ImVec2(0.0f, 4.0f));

					ImGui::Text("Precision :"); ImGui::SameLine();
					ImGui::RadioButton("32-bit", &precisionId, 0); ImGui::SameLine();
					ImGui::RadioButton("64-bit", &precisionId, 1); ImGui::SameLine();
					ImGui::RadioButton("128-bit", &precisionId, 2);

					ImGui::Dummy(ImVec2(0.0f, 20.0f));

					//ImGui::InputDouble("X", &x, 10 / zoom, 50 / zoom);
					//ImGui::InputDouble("Y", &y, 10 / zoom, 50 / zoom);
					//ImGui::InputDouble("Zoom", &zoom, zoom * 0.1, zoom * 0.25);
					//ImGui::InputDouble("Radius", &radius, 0.1, 1.0);
					ImGui::SliderAngle("Rotation", &rotation, 0, 360);

					if (isMaxIterationsAuto)
					{
						ImGui::PushItemFlag(ImGuiItemFlags_Disabled, true);
						ImGui::PushStyleVar(ImGuiStyleVar_Alpha, ImGui::GetStyle().Alpha * 0.5f);
					}
					ImGui::DragInt("Max iterations", &maxIterations); ImGui::SameLine();
					if (isMaxIterationsAuto)
					{
						ImGui::PopItemFlag();
						ImGui::PopStyleVar();
					}
					ImGui::Checkbox("Auto", &isMaxIterationsAuto);
					
					ImGui::Dummy(ImVec2(0.0f, 20.0f));

					switch (fractalId)
					{
					case 0:
						ImGui::Text("Mandelbrot Settings :");
						
						//ImGui::SliderFloat("z_r", &mandelbrot_z_r, 0.0f, 1.0f, "%.3f");
						//ImGui::SliderFloat("z_i", &mandelbrot_z_i, 0.0f, 1.0f, "%.3f");
						break;
					case 1:
						ImGui::Text("Julia Settings :");

						//ImGui::SliderFloat("c_r", &julia_c_r, 0.0f, 1.0f, "%.3f");
						//ImGui::SliderFloat("c_i", &julia_c_i, 0.0f, 1.0f, "%.3f");
						break;
					}
					
					ImGui::Dummy(ImVec2(0.0f, 20.0f));
				}

				if (ImGui::CollapsingHeader("Palette"))
				{
					ImGui::Dummy(ImVec2(0.0f, 20.0f));
					
					ImGui::ColorEdit3("Color A", colorA);
					ImGui::ColorEdit3("Color B", colorB);
					ImGui::ColorEdit3("Color C", colorC);
					ImGui::ColorEdit3("Color D", colorD);
					
					ImGui::Dummy(ImVec2(0.0f, 20.0f));
				}

				ImGui::Dummy(ImVec2(0.0f, 20.0f));

				ImGui::Text("%.1f FPS (%.3f ms)", ImGui::GetIO().Framerate, 1000.0f / ImGui::GetIO().Framerate);
				ImGui::Text("by PixelDeEcran");

				isConfigWindowHovered = ImGui::IsWindowHovered() || ImGui::IsAnyItemHovered() || ImGui::IsAnyItemFocused();
				ImGui::End();
			}

			ImGui::Render();

			Shader shader = shaders[precisionId];
			
			shader.Bind();

			if (isMaxIterationsAuto)
			{
				maxIterations = log(zoom.to_double()) * log10(zoom.to_double()) * 0.75 + 50;
			}

			shader.SetUniform1i("max_iterations", maxIterations);
			shader.SetUniform1i("screenWidth", width);
			shader.SetUniform1i("screenHeight", height);
			shader.SetUniform1i("fractal_id", fractalId);
			shader.SetUniform1f("rotation", rotation);

			switch (precisionId)
			{
			case 0:
				shader.SetUniform1f("radius", radius.to_float());
				shader.SetUniform1f("x", x.to_float());
				shader.SetUniform1f("y", y.to_float());
				shader.SetUniform1f("zoom", zoom.to_float());


				shader.SetUniform1f("mandelbrot_z_r", mandelbrot_z_r.to_float());
				shader.SetUniform1f("mandelbrot_z_i", mandelbrot_z_i.to_float());

				shader.SetUniform1f("julia_c_r", julia_c_r.to_float());
				shader.SetUniform1f("julia_c_i", julia_c_i.to_float());
				break;
			case 1:
				shader.SetUniform1d("radius", radius.to_double());
				shader.SetUniform1d("x", x.to_double());
				shader.SetUniform1d("y", y.to_double());
				shader.SetUniform1d("zoom", zoom.to_double());


				shader.SetUniform1d("mandelbrot_z_r", mandelbrot_z_r.to_double());
				shader.SetUniform1d("mandelbrot_z_i", mandelbrot_z_i.to_double());

				shader.SetUniform1d("julia_c_r", julia_c_r.to_double());
				shader.SetUniform1d("julia_c_i", julia_c_i.to_double());
				break;
			case 2:
				shader.SetUniform2d("radius", radius);
				shader.SetUniform2d("x", x);
				shader.SetUniform2d("y", y);
				shader.SetUniform2d("zoom", zoom);

				shader.SetUniform2d("mandelbrot_z_r", mandelbrot_z_r);
				shader.SetUniform2d("mandelbrot_z_i", mandelbrot_z_i);

				shader.SetUniform2d("julia_c_r", julia_c_r);
				shader.SetUniform2d("julia_c_i", julia_c_i);
				break;
			}

			shader.SetUniform3f("colorA", colorA[0], colorA[1], colorA[2]);
			shader.SetUniform3f("colorB", colorB[0], colorB[1], colorB[2]);
			shader.SetUniform3f("colorC", colorC[0], colorC[1], colorC[2]);
			shader.SetUniform3f("colorD", colorD[0], colorD[1], colorD[2]);
			
			renderer.Draw(va, ib, shader);
			
			ImGui_ImplOpenGL3_RenderDrawData(ImGui::GetDrawData());

			std::cout << "X : " << x.to_double_double()[0] << " ; " << x.to_double_double()[1] << std::endl;
			std::cout << "Y : " << y.to_double_double()[0] << " ; " << y.to_double_double()[1] << std::endl;

			glViewport(0, 0, width, height);
			GLCall(glfwSwapBuffers(window));
			GLCall(glfwPollEvents());
		}
	}

	ImGui_ImplOpenGL3_Shutdown();
	ImGui_ImplGlfw_Shutdown();
	ImGui::DestroyContext();

	glfwTerminate();
	return 0;
}
