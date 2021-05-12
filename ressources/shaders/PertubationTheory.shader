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

vec2 cmul(vec2 a, vec2 b) { return vec2(a.x * b.x - a.y * b.y, a.x * b.y + a.y * b.x); }

float mandelbrot()
{
	vec2 c = vec2(x, y);
	vec2 dc = vec2(gl_FragCoord.x / zoom, gl_FragCoord.y / zoom);
	vec2 z = vec2(0.0);
	vec2 dz = vec2(0.0);
	int i = 0;

	for (int i = 0; i < max_iterations; i++)
	{
		dz = cmul(2.0 * z + dz, dz) + dc;
		z = cmul(z, z) + c; 

		if (dot(z + dz, z + dz) > radius) {
			return i;
		}
	}

	return i;
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