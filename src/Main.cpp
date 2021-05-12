#include <GL/glew.h>
#include <GLFW/glfw3.h>

#include <chrono>
#include <iomanip>

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
double radius = 8.0;
double x = -0.75;
double y = 0;
double zoom = 200;

float colorA[3] = { 0.5f, 0.5f, 0.5f };
float colorB[3] = { 0.5f, 0.5f, 0.5f };
float colorC[3] = { 1.0f, 1.0f, 1.0f };
float colorD[3] = { 0.0f, 0.1f, 0.2f };

float mandelbrot_z_r = 0.0;
float mandelbrot_z_i = 0.0;

float julia_c_r = 0.285;
float julia_c_i = 0.01;

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

		double amountX = ((mouseX - double(width) / 2) / zoom) * 0.1 * (signbit(yoffset) == 0 ? 1 : -1);
		double amountY = ((mouseY - double(height) / 2) / zoom) * 0.1 * (signbit(yoffset) == 0 ? 1 : -1);
		
		x += amountX * cos(rotation) - amountY * sin(rotation);
		y += amountX * sin(rotation) + amountY * cos(rotation);
		
		if (yoffset > 0)
		{
			zoom += zoom * 0.1 * abs(yoffset);
		}
		else
		{
			zoom -= zoom * 0.1 * abs(yoffset);
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
			Shader("ressources/shaders/Fractal64.shader")
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
					double amountX = (mouseX - prevMouseX) / zoom;
					double amountY = (mouseY - prevMouseY) / zoom;

					x -= amountX * cos(rotation) - amountY * sin(rotation);
					y -= amountX * sin(rotation) + amountY * cos(rotation);
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

			ImGui::ShowDemoWindow();

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
					ImGui::RadioButton("64-bit", &precisionId, 1);

					ImGui::Dummy(ImVec2(0.0f, 20.0f));

					ImGui::InputDouble("X", &x, 10 / zoom, 50 / zoom);
					ImGui::InputDouble("Y", &y, 10 / zoom, 50 / zoom);
					ImGui::InputDouble("Zoom", &zoom, zoom * 0.1, zoom * 0.25);
					ImGui::InputDouble("Radius", &radius, 0.1, 1.0);
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
						
						ImGui::SliderFloat("z_r", &mandelbrot_z_r, 0.0f, 1.0f, "%.3f");
						ImGui::SliderFloat("z_i", &mandelbrot_z_i, 0.0f, 1.0f, "%.3f");
						break;
					case 1:
						ImGui::Text("Julia Settings :");

						ImGui::SliderFloat("c_r", &julia_c_r, 0.0f, 1.0f, "%.3f");
						ImGui::SliderFloat("c_i", &julia_c_i, 0.0f, 1.0f, "%.3f");
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

			double renderX = x;
			double renderY = y;

			if (isMaxIterationsAuto)
			{
				maxIterations = log(zoom) * log10(zoom) * 0.75 + 50;
			}

			shader.SetUniform1i("max_iterations", maxIterations);
			shader.SetUniform1i("screenWidth", width);
			shader.SetUniform1i("screenHeight", height);
			shader.SetUniform1i("fractal_id", fractalId);
			shader.SetUniform1f("rotation", rotation);

			switch (precisionId)
				{
				case 0:
					shader.SetUniform1f("radius", static_cast<float>(radius));
					shader.SetUniform1f("x", static_cast<float>(renderX));
					shader.SetUniform1f("y", static_cast<float>(renderY));
					shader.SetUniform1f("zoom", static_cast<float>(zoom));

				
					shader.SetUniform1f("mandelbrot_z_r", mandelbrot_z_r);
					shader.SetUniform1f("mandelbrot_z_i", mandelbrot_z_i);
				
					shader.SetUniform1f("julia_c_r", julia_c_r);
					shader.SetUniform1f("julia_c_i", julia_c_i);
					break;
				case 1:
					shader.SetUniform1d("radius", radius);
					shader.SetUniform1d("x", renderX);
					shader.SetUniform1d("y", renderY);
					shader.SetUniform1d("zoom", zoom);


					shader.SetUniform1d("mandelbrot_z_r", mandelbrot_z_r);
					shader.SetUniform1d("mandelbrot_z_i", mandelbrot_z_i);

					shader.SetUniform1d("julia_c_r", julia_c_r);
					shader.SetUniform1d("julia_c_i", julia_c_i);
					break;
				case 2:
					float tmp[2];
				
					shader.SetUniform1f("radius", static_cast<float>(radius));

					tmp[0] = (float)renderX;
					tmp[1] = renderX - tmp[0];
					shader.SetUniform2f("x", tmp[0], tmp[1]);

					tmp[0] = (float)renderY;
					tmp[1] = renderY - tmp[0];
					shader.SetUniform2f("y", tmp[0], tmp[1]);

					tmp[0] = (float)zoom;
					tmp[1] = zoom - tmp[0];
					shader.SetUniform2f("zoom", tmp[0], tmp[1]);

					std::cout << "Zoom : " << tmp[0] << " ; " << tmp[1] << std::endl;
					break;
				}

			shader.SetUniform3f("colorA", colorA[0], colorA[1], colorA[2]);
			shader.SetUniform3f("colorB", colorB[0], colorB[1], colorB[2]);
			shader.SetUniform3f("colorC", colorC[0], colorC[1], colorC[2]);
			shader.SetUniform3f("colorD", colorD[0], colorD[1], colorD[2]);
			
			renderer.Draw(va, ib, shader);
			
			ImGui_ImplOpenGL3_RenderDrawData(ImGui::GetDrawData());

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
