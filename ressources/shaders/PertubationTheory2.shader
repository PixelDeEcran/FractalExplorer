#shader vertex
#version 330 core

layout(location = 0) in vec4 position;

void main()
{
	gl_Position = position;
};

#shader fragment
#version 330 core

layout(location = 0) out vec4 color;
layout(origin_upper_left, pixel_center_integer) in vec4 gl_FragCoord;

uniform int max_iterations;
uniform int fractal_id;
uniform float radius;

uniform float x;
uniform float y;
uniform float zoom;

uniform vec3 colorA;
uniform vec3 colorB;
uniform vec3 colorC;
uniform vec3 colorD;

vec3 palette(in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d)
{
	return a + b * cos(6.28318 * (c * t + d));
}

float mandelbrot()
{
	float c_r = x;
	float c_i = y;
	float dc_r = gl_FragCoord.x / zoom;
	float dc_i = gl_FragCoord.y / zoom;
	float z_r = 0;
	float z_i = 0;
	float dz_r = 0;
	float dz_i = 0;
	int i = 0;

	do
	{
		float tmpDz_r = dz_r;
		dz_r = 2 * dz_r * z_r - 2 * dz_i * z_i + z_r * z_r + dc_r;
		dz_i = 2 * tmpDz_r * z_i + 2 * dz_i * tmpDz_r + 2 * tmpDz_r * z_i + dc_i;

		float tmpZ_r = z_r;
		z_r = z_r * z_r - z_i * z_i + c_r + dc_r;
		z_i = 2 * z_i * tmpZ_r + c_i + dc_i;

		i = i + 1;
	} while (dz_r * dz_r + dz_i * dz_i < radius && i < max_iterations);

	return i - log(log(z_r * z_r + z_i * z_i) / log(radius)) / log(2.0f);
}

void main()
{
	float i = 0;
	if (fractal_id == 0)
	{
		i = mandelbrot();
	}
	else
	{
		color = vec4(0.0f, 1.0f, 1.0f, 1.0f);
	}

	if (i == max_iterations)
	{
		color = vec4(0.0f, 0.0f, 0.0f, 1.0f);
	}
	else
	{
		color = vec4(palette(i / float(max_iterations), colorA, colorB, colorC, colorD), 1.0f);
	}
};