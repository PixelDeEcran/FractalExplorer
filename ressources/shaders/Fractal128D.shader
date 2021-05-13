#shader vertex
#version 330 core

layout(location = 0) in vec4 position;

void main()
{
	gl_Position = position;
};

#shader fragment
#version 330 core
#pragma optionNV(fastmath off)
#pragma optionNV(fastprecision off)
#extension GL_ARB_gpu_shader_fp64 : enable

layout(location = 0) out vec4 color;
layout(origin_upper_left, pixel_center_integer) in vec4 gl_FragCoord;

uniform int max_iterations;
uniform int fractal_id;
uniform int screenWidth;
uniform int screenHeight;
uniform float rotation;
uniform dvec2 radius;

uniform dvec2 x;
uniform dvec2 y;
uniform dvec2 zoom;

uniform vec3 colorA;
uniform vec3 colorB;
uniform vec3 colorC;
uniform vec3 colorD;

uniform dvec2 mandelbrot_z_r;
uniform dvec2 mandelbrot_z_i;

uniform dvec2 julia_c_r;
uniform dvec2 julia_c_i;

float PI = 3.141592653589793;

// START
// translated code from https://github.com/sukop/doubledouble

dvec2 _two_sum_quick(double x, double y)
{
	double r = x + y;
	double e = y - (r - x);
	return dvec2(r, e);
}

dvec2 _two_sum(double x, double y)
{
	double r = x + y;
	double t = r - x;
	double e = (x - (r - t)) + (y - t);
	return dvec2(r, e);
}

dvec2 _two_difference(double x, double y)
{
	double r = x - y;
	double t = r - x;
	double e = (x - (r - t)) - (y + t);
	return dvec2(r, e);
}

dvec2 _two_product(double x, double y)
{
	double u = x * 134217729.0;
	double v = y * 134217729.0;
	double s = u - (u - x);
	double t = v - (v - y);
	double f = x - s;
	double g = y - t;
	double r = x * y;
	double e = ((s * t - r) + s * g + f * t) + f * g;
	return dvec2(r, e);
}

dvec2 add(dvec2 a, dvec2 b)
{
	dvec2 tmp = _two_sum(a.x, b.x);
	tmp.y += a.y + b.y;
	return _two_sum_quick(tmp.x, tmp.y);
}

dvec2 sub(dvec2 a, dvec2 b)
{
	dvec2 tmp = _two_difference(a.x, b.x);
	tmp.y += a.y - b.y;
	return _two_sum_quick(tmp.x, tmp.y);
}

dvec2 mul(dvec2 a, dvec2 b)
{
	dvec2 tmp = _two_product(a.x, b.x);
	tmp.y += a.x * b.y + a.y * b.x; 
	return _two_sum_quick(tmp.x, tmp.y);
}

dvec2 div(dvec2 a, dvec2 b)
{
	double r = a.x / b.x;
	dvec2 tmp = _two_product(r, b.x);
	double e = (a.x - tmp.x - tmp.y + a.y - r * b.y) / b.x;
	return _two_sum_quick(r, e);
}

bool smallerThan(dvec2 a, dvec2 b)
{
	return a.x < b.x || a.x == b.x && a.y < b.y;
}

// END

vec3 palette(in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d)
{
	return a + b * cos(PI * 2 * (c * t + d));
}

double mandelbrot()
{
	dvec2 pointX = div(dvec2(gl_FragCoord.x - screenWidth / 2, 0.0), zoom);
	dvec2 pointY = div(dvec2(gl_FragCoord.y - screenHeight / 2, 0.0), zoom);

	dvec2 cosRotation = dvec2(double(cos(rotation)), 0.0);
	dvec2 sinRotation = dvec2(double(sin(rotation)), 0.0);

	dvec2 c_r = add(sub(mul(pointX, cosRotation), mul(pointY, sinRotation)), x);
	dvec2 c_i = add(add(mul(pointX, sinRotation), mul(pointY, cosRotation)), y);
	dvec2 z_r = mandelbrot_z_r;
	dvec2 z_i = mandelbrot_z_i;
	dvec2 two = dvec2(2.0, 0.0);
	int i = 0;

	do
	{
		dvec2 tmp = z_r;
		z_r = add(sub(mul(z_r, z_r), mul(z_i, z_i)), c_r);
		z_i = add(mul(mul(two, z_i), tmp), c_i);
		i = i + 1;
	} while (smallerThan(add(mul(z_r, z_r), mul(z_i, z_i)), radius) && i < max_iterations);

	if (i == max_iterations)
	{
		return i;
	}

	return i - log(log(float(add(mul(z_r, z_r), mul(z_i, z_i)).x)) / log(float(radius.x))) / log(2.0);
}

double julia()
{
	dvec2 pointX = div(dvec2(gl_FragCoord.x - screenWidth / 2, 0.0), zoom);
	dvec2 pointY = div(dvec2(gl_FragCoord.y - screenHeight / 2, 0.0), zoom);

	dvec2 cosRotation = dvec2(double(cos(rotation)), 0.0);
	dvec2 sinRotation = dvec2(double(sin(rotation)), 0.0);

	dvec2 c_r = julia_c_r;
	dvec2 c_i = julia_c_i;
	dvec2 z_r = add(sub(mul(pointX, cosRotation), mul(pointY, sinRotation)), x);
	dvec2 z_i = add(add(mul(pointX, sinRotation), mul(pointY, cosRotation)), y);
	dvec2 two = dvec2(2.0, 0.0);
	int i = 0;

	do
	{
		dvec2 tmp = z_r;
		z_r = add(sub(mul(z_r, z_r), mul(z_i, z_i)), c_r);
		z_i = add(mul(mul(two, z_i), tmp), c_i);
		i = i + 1;
	} while (smallerThan(add(mul(z_r, z_r), mul(z_i, z_i)), radius) && i < max_iterations);

	if (i == max_iterations)
	{
		return i;
	}

	return i - log(log(float(add(mul(z_r, z_r), mul(z_i, z_i)).x)) / log(float(radius.x))) / log(2.0);
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