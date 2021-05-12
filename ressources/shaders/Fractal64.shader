#shader vertex
#version 330 core

layout(location = 0) in vec4 position;

void main()
{
	gl_Position = position;
};

#shader fragment
#version 330 core
#extension GL_ARB_gpu_shader_fp64 : enable

layout(location = 0) out vec4 color;
layout(origin_upper_left, pixel_center_integer) in vec4 gl_FragCoord;

uniform int max_iterations;
uniform int fractal_id;
uniform int screenWidth;
uniform int screenHeight;
uniform float rotation;
uniform double radius;

uniform double x;
uniform double y;
uniform double zoom;

uniform vec3 colorA;
uniform vec3 colorB;
uniform vec3 colorC;
uniform vec3 colorD;

uniform double mandelbrot_z_r;
uniform double mandelbrot_z_i;

uniform double julia_c_r;
uniform double julia_c_i;

float PI = 3.141592653589793;

vec3 palette(in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d)
{
	return a + b * cos(PI * 2 * (c * t + d));
}

double mandelbrot()
{
	double pointX = (gl_FragCoord.x - screenWidth / 2) / zoom;
	double pointY = (gl_FragCoord.y - screenHeight / 2) / zoom;

	double c_r = (pointX * cos(rotation) - pointY * sin(rotation)) + x;
	double c_i = (pointX * sin(rotation) + pointY * cos(rotation)) + y;
	double z_r = mandelbrot_z_r;
	double z_i = mandelbrot_z_i;
	int i = 0;

	do
	{
		double tmp = z_r;
		z_r = z_r * z_r - z_i * z_i + c_r;
		z_i = 2 * z_i * tmp + c_i;
		i = i + 1;
	} while (z_r * z_r + z_i * z_i < radius && i < max_iterations);

	if (i == max_iterations)
	{
		return i;
	}
	return i - log(log(float(z_r * z_r + z_i * z_i)) / log(float(radius))) / log(2.0);
}

double julia()
{
	double pointX = (gl_FragCoord.x - screenWidth / 2) / zoom;
	double pointY = (gl_FragCoord.y - screenHeight / 2) / zoom;

	double c_r = julia_c_r;
	double c_i = julia_c_i;
	double z_r = (pointX * cos(rotation) - pointY * sin(rotation)) + x;
	double z_i = (pointX * sin(rotation) + pointY * cos(rotation)) + y;
	int i = 0;

	do
	{
		double tmp = z_r;
		z_r = z_r * z_r - z_i * z_i + c_r;
		z_i = 2 * z_i * tmp + c_i;
		i = i + 1;
	} while (z_r * z_r + z_i * z_i < radius && i < max_iterations);

	if (i == max_iterations)
	{
		return i;
	}
	return i - log(log(float(z_r * z_r + z_i * z_i)) / log(float(radius))) / log(2.0);
}

void main()
{
	double i = 0;
	if (fractal_id == 0)
	{
		i = mandelbrot();
	}
	else if (fractal_id == 1)
	{
		i = julia();
	}

	if (i == max_iterations)
	{
		color = vec4(0.0f, 0.0f, 0.0f, 1.0f);
	}
	else
	{
		color = vec4(palette(fract(float(i / double(max_iterations)) + 0.5), colorA, colorB, colorC, colorD), 1.0f);
	}
};