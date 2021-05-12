#shader vertex
#version 330 core

layout(location = 0) in highp vec4 position;

void main()
{
	gl_Position = position;
};

#shader fragment
#version 330

layout(origin_upper_left, pixel_center_integer) in highp vec4 gl_FragCoord;

uniform int max_iterations;
uniform int fractal_id;
uniform highp float radius;

uniform highp vec2 x;
uniform highp vec2 y;
uniform highp vec2 zoom;

uniform highp vec3 colorA;
uniform highp vec3 colorB;
uniform highp vec3 colorC;
uniform highp vec3 colorD;

// inline double quick_two_sum(double a, double b, double &err)
highp vec2 quick_2sum(highp float a, highp float b)
{
	highp float s = a + b;                       // double s = a + b;
	return vec2(s, b - (s - a));       // err = b - (s - a);
}

/* Computes fl(a+b) and err(a+b).  */
// inline double two_sum(double a, double b, double &err)
highp vec2 two_sum(highp float a, highp float b)
{
	highp float v, s, e;

	s = a + b;                               // double s = a + b;
	v = s - a;                               // double bb = s - a;
	e = (a - (s - v)) + (b - v);   // err = (a - (s - bb)) + (b - bb);

	return vec2(s, e);
}

highp vec2 split(highp float a)
{
	highp float t, hi;
	t = 8193. * a;
	hi = t - (t - a);
	return vec2(hi, a - hi);
}

highp vec3 three_sum(highp float a, highp float b, highp float c)
{
	highp vec2 tmp;
	highp vec3 res;// = highp vec3(0.);
	highp float t1, t2, t3;
	tmp = two_sum(a, b); // t1 = qd::two_sum(a, b, t2);
	t1 = tmp.x;
	t2 = tmp.y;

	tmp = two_sum(c, t1); // a  = qd::two_sum(c, t1, t3);
	res.x = tmp.x;
	t3 = tmp.y;

	tmp = two_sum(t2, t3); // b  = qd::two_sum(t2, t3, c);
	res.y = tmp.x;
	res.z = tmp.y;

	return res;
}

//inline void three_sum2(double &a, double &b, double &c)
highp vec3 three_sum2(highp float a, highp float b, highp float c)
{
	highp vec2 tmp;
	highp vec3 res;// = highp vec3(0.);
	highp float t1, t2, t3;       // double t1, t2, t3;
	tmp = two_sum(a, b); // t1 = qd::two_sum(a, b, t2);
	t1 = tmp.x;
	t2 = tmp.y;

	tmp = two_sum(c, t1); // a  = qd::two_sum(c, t1, t3);
	res.x = tmp.x;
	t3 = tmp.y;

	res.y = t2 + t3;      // b = t2 + t3;
	return res;
}

highp vec2 two_prod(highp float a, highp float b)
{
	highp float p, e;
	highp vec2 va, vb;

	p = a * b;
	va = split(a);
	vb = split(b);

	e = ((va.x * vb.x - p) + va.x * vb.y + va.y * vb.x) + va.y * vb.y;
	return vec2(p, e);
}

highp vec4 renorm(highp float c0, highp float c1, highp float c2, highp float c3, highp float c4)
{
	highp float s0, s1, s2 = 0.0, s3 = 0.0;
	highp vec2 tmp;

	// if (QD_ISINF(c0)) return;

	tmp = quick_2sum(c3, c4); // s0 = qd::quick_two_sum(c3, c4, c4);
	s0 = tmp.x;
	c4 = tmp.y;

	tmp = quick_2sum(c2, s0); // s0 = qd::quick_two_sum(c2, s0, c3);
	s0 = tmp.x;
	c3 = tmp.y;

	tmp = quick_2sum(c1, s0); // s0 = qd::quick_two_sum(c1, s0, c2);
	s0 = tmp.x;
	c2 = tmp.y;

	tmp = quick_2sum(c0, s0); // c0 = qd::quick_two_sum(c0, s0, c1);
	c0 = tmp.x;
	c1 = tmp.y;

	s0 = c0;
	s1 = c1;

	tmp = quick_2sum(c0, c1); // s0 = qd::quick_two_sum(c0, c1, s1);
	s0 = tmp.x;
	s1 = tmp.y;

	if (s1 != 0.0) {
		tmp = quick_2sum(s1, c2); // s1 = qd::quick_two_sum(s1, c2, s2);
		s1 = tmp.x;
		s2 = tmp.y;

		if (s2 != 0.0) {
			tmp = quick_2sum(s2, c3); // s2 = qd::quick_two_sum(s2, c3, s3);
			s2 = tmp.x;
			s3 = tmp.y;
			if (s3 != 0.0)
				s3 += c4;
			else
				s2 += c4;
		}
		else {
			tmp = quick_2sum(s1, c3); // s1 = qd::quick_two_sum(s1, c3, s2);
			s1 = tmp.x;
			s2 = tmp.y;
			if (s2 != 0.0) {
				tmp = quick_2sum(s2, c4); // s2 = qd::quick_two_sum(s2, c4, s3);
				s2 = tmp.x;
				s3 = tmp.y;
			}
			else {
				tmp = quick_2sum(s1, c4); // s1 = qd::quick_two_sum(s1, c4, s2);
				s1 = tmp.x;
				s2 = tmp.y;
			}
		}
	}
	else {
		tmp = quick_2sum(s0, c2); // s0 = qd::quick_two_sum(s0, c2, s1);
		s0 = tmp.x;
		s1 = tmp.y;
		if (s1 != 0.0) {
			tmp = quick_2sum(s1, c3); // s1 = qd::quick_two_sum(s1, c3, s2);
			s1 = tmp.x;
			s2 = tmp.y;
			if (s2 != 0.0) {
				tmp = quick_2sum(s2, c4); // s2 = qd::quick_two_sum(s2, c4, s3);
				s2 = tmp.x;
				s3 = tmp.y;
			}
			else {
				tmp = quick_2sum(s1, c4); // s1 = qd::quick_two_sum(s1, c4, s2);
				s1 = tmp.x;
				s2 = tmp.y;
			}
		}
		else {
			tmp = quick_2sum(s0, c3); // s0 = qd::quick_two_sum(s0, c3, s1);
			s0 = tmp.x;
			s1 = tmp.y;
			if (s1 != 0.0) {
				tmp = quick_2sum(s1, c4); // s1 = qd::quick_two_sum(s1, c4, s2);
				s1 = tmp.x;
				s2 = tmp.y;
			}
			else {
				tmp = quick_2sum(s0, c4); // s0 = qd::quick_two_sum(s0, c4, s1);
				s0 = tmp.x;
				s1 = tmp.y;
			}
		}
	}

	return vec4(s0, s1, s2, s3);

}

highp vec4 renorm4(highp float c0, highp float c1, highp float c2, highp float c3)
{
	highp float s0, s1, s2 = 0.0, s3 = 0.0;
	highp vec2 tmp;
	// if (QD_ISINF(c0)) return;

	tmp = quick_2sum(c2, c3); // s0 = qd::quick_two_sum(c2, c3, c3);
	s0 = tmp.x;
	c3 = tmp.y;

	tmp = quick_2sum(c1, s0); // s0 = qd::quick_two_sum(c1, s0, c2);
	s0 = tmp.x;
	c2 = tmp.y;

	tmp = quick_2sum(c0, s0); // c0 = qd::quick_two_sum(c0, s0, c1);
	c0 = tmp.x;
	c1 = tmp.y;

	s0 = c0;
	s1 = c1;
	if (s1 != 0.0) {
		tmp = quick_2sum(s1, c2); // s1 = qd::quick_two_sum(s1, c2, s2);
		s1 = tmp.x;
		s2 = tmp.y;

		if (s2 != 0.0) {
			tmp = quick_2sum(s2, c3); // s2 = qd::quick_two_sum(s2, c3, s3);
			s2 = tmp.x;
			s3 = tmp.y;
		}
		else {
			tmp = quick_2sum(s1, c3); // s1 = qd::quick_two_sum(s1, c3, s2);
			s1 = tmp.x;
			s2 = tmp.y;
		}
	}
	else {
		tmp = quick_2sum(s0, c2); // s0 = qd::quick_two_sum(s0, c2, s1);
		s0 = tmp.x;
		s1 = tmp.y;
		if (s1 != 0.0) {
			tmp = quick_2sum(s1, c3); // s1 = qd::quick_two_sum(s1, c3, s2);
			s1 = tmp.x;
			s2 = tmp.y;
		}
		else {
			tmp = quick_2sum(s0, c3); // s0 = qd::quick_two_sum(s0, c3, s1);
			s0 = tmp.x;
			s1 = tmp.y;
		}
	}

	return vec4(s0, s1, s2, s3);
}

highp vec3 quick_three_accum(highp float a, highp float b, highp float c)
{
	highp vec2 tmp;
	highp float s;
	bool za, zb;

	tmp = two_sum(b, c); // s = qd::two_sum(b, c, b);
	s = tmp.x;
	b = tmp.y;

	tmp = two_sum(a, s); // s = qd::two_sum(a, s, a);
	s = tmp.x;
	a = tmp.y;

	za = (a != 0.0);
	zb = (b != 0.0);

	if (za && zb)
		return vec3(a, b, s);

	if (!zb) {
		b = a;
		a = s;
	}
	else {
		a = s;
	}

	return vec3(a, b, 0.);
}

// inline qd_real qd_real::ieee_add(const qd_real &a, const qd_real &b)
highp vec4 qs_ieee_add(highp vec4 _a, highp vec4 _b)
{
	highp vec2 tmp = vec2(0.);
	highp vec3 tmp3 = vec3(0.);
	int i, j, k;
	highp float s, t;
	highp float u, v;   // double-length accumulator
	highp float x[4] = float[4](0.0, 0.0, 0.0, 0.0);
	highp float a[4], b[4];

	a[0] = _a.x;
	a[1] = _a.y;
	a[2] = _a.z;
	a[3] = _a.w;

	b[0] = _b.x;
	b[1] = _b.y;
	b[2] = _b.z;
	b[3] = _b.w;

	i = j = k = 0;
	if (abs(a[i]) > abs(b[j]))
		u = a[i++];
	else
		u = b[j++];
	if (abs(a[i]) > abs(b[j]))
		v = a[i++];
	else
		v = b[j++];

	tmp = quick_2sum(u, v); // u = qd::quick_two_sum(u, v, v);
	u = tmp.x;
	v = tmp.y;

	while (k < 4) {
		if (i >= 4 && j >= 4) {
			x[k] = u;
			if (k < 3)
				x[++k] = v;
			break;
		}

		if (i >= 4)
			t = b[j++];
		else if (j >= 4)
			t = a[i++];
		else if (abs(a[i]) > abs(b[j])) {
			t = a[i++];
		}
		else
			t = b[j++];

		tmp3 = quick_three_accum(u, v, t); // s = qd::quick_three_accum(u, v, t);
		u = tmp3.x;
		v = tmp3.y;
		s = tmp3.z;

		if (s != 0.0) {
			x[k++] = s;
		}
	}

	// add the rest.
	for (k = i; k < 4; k++)
		x[3] += a[k];
	for (k = j; k < 4; k++)
		x[3] += b[k];

	// qd::renorm(x[0], x[1], x[2], x[3]);
	// return qd_real(x[0], x[1], x[2], x[3]);
	return renorm4(x[0], x[1], x[2], x[3]);
}

// inline qd_real qd_real::sloppy_add(const qd_real &a, const qd_real &b)
highp vec4 qs_sloppy_add(highp vec4 a, highp vec4 b)
{
	highp float s0, s1, s2, s3;
	highp float t0, t1, t2, t3;

	highp float v0, v1, v2, v3;
	highp float u0, u1, u2, u3;
	highp float w0, w1, w2, w3;

	highp vec2 tmp;
	highp vec3 tmp3;

	s0 = a.x + b.x;       // s0 = a[0] + b[0];
	s1 = a.y + b.y;       // s1 = a[1] + b[1];
	s2 = a.z + b.z;       // s2 = a[2] + b[2];
	s3 = a.w + b.w;       // s3 = a[3] + b[3];  

	v0 = s0 - a.x;        // v0 = s0 - a[0];
	v1 = s1 - a.y;        // v1 = s1 - a[1];
	v2 = s2 - a.z;        // v2 = s2 - a[2];
	v3 = s3 - a.w;        // v3 = s3 - a[3];

	u0 = s0 - v0;
	u1 = s1 - v1;
	u2 = s2 - v2;
	u3 = s3 - v3;

	w0 = a.x - u0;        // w0 = a[0] - u0;
	w1 = a.y - u1;        // w1 = a[1] - u1;
	w2 = a.z - u2;        // w2 = a[2] - u2;
	w3 = a.w - u3;        // w3 = a[3] - u3; 

	u0 = b.x - v0;        // u0 = b[0] - v0;
	u1 = b.y - v1;        // u1 = b[1] - v1;
	u2 = b.z - v2;        // u2 = b[2] - v2;
	u3 = b.w - v3;        // u3 = b[3] - v3;

	t0 = w0 + u0;
	t1 = w1 + u1;
	t2 = w2 + u2;
	t3 = w3 + u3;

	tmp = two_sum(s1, t0); // s1 = qd::two_sum(s1, t0, t0);
	s1 = tmp.x;
	t0 = tmp.y;

	tmp3 = three_sum(s2, t0, t1); // qd::three_sum(s2, t0, t1);
	s2 = tmp3.x;
	t0 = tmp3.y;
	t1 = tmp3.z;

	tmp3 = three_sum2(s3, t0, t2); // qd::three_sum2(s3, t0, t2);
	s3 = tmp3.x;
	t0 = tmp3.y;
	t2 = tmp3.z;

	t0 = t0 + t1 + t3;

	// qd::renorm(s0, s1, s2, s3, t0);
	return renorm(s0, s1, s2, s3, t0); // return qd_real(s0, s1, s2, s3);
}

highp vec4 qs_add(highp vec4 _a, highp vec4 _b)
{
	return qs_sloppy_add(_a, _b);
	//  return qs_ieee_add(_a, _b);
}

highp vec4 qs_mul(highp vec4 a, highp vec4 b)
{
	highp float p0, p1, p2, p3, p4, p5;
	highp float q0, q1, q2, q3, q4, q5;
	highp float t0, t1;
	highp float s0, s1, s2;
	highp vec2 tmp;
	highp vec3 tmp3;

	tmp = two_prod(a.x, b.x); // p0 = qd::two_prod(a[0], b[0], q0);
	p0 = tmp.x;
	q0 = tmp.y;

	tmp = two_prod(a.x, b.y); // p1 = qd::two_prod(a[0], b[1], q1);
	p1 = tmp.x;
	q1 = tmp.y;

	tmp = two_prod(a.y, b.x); // p2 = qd::two_prod(a[1], b[0], q2);
	p2 = tmp.x;
	q2 = tmp.y;

	tmp = two_prod(a.x, b.z); // p3 = qd::two_prod(a[0], b[2], q3);
	p3 = tmp.x;
	q3 = tmp.y;

	tmp = two_prod(a.y, b.y); // p4 = qd::two_prod(a[1], b[1], q4);
	p4 = tmp.x;
	q4 = tmp.y;

	tmp = two_prod(a.z, b.x); // p5 = qd::two_prod(a[2], b[0], q5);
	p5 = tmp.x;
	q5 = tmp.y;

	/* Start Accumulation */
	tmp3 = three_sum(p1, p2, q0); // qd::three_sum(p1, p2, q0);
	p1 = tmp3.x;
	p2 = tmp3.y;
	q0 = tmp3.z;

	/* Six-Three Sum  of p2, q1, q2, p3, p4, p5. */
	tmp3 = three_sum(p2, q1, q2); // qd::three_sum(p2, q1, q2);
	p2 = tmp3.x;
	q1 = tmp3.y;
	q2 = tmp3.z;

	tmp3 = three_sum(p3, p4, p5); // qd::three_sum(p3, p4, p5);
	p3 = tmp3.x;
	p4 = tmp3.y;
	p5 = tmp3.z;

	/* compute (s0, s1, s2) = (p2, q1, q2) + (p3, p4, p5). */
	tmp = two_sum(p2, p3); // s0 = qd::two_sum(p2, p3, t0);
	s0 = tmp.x;
	t0 = tmp.y;

	tmp = two_sum(q1, p4); // s1 = qd::two_sum(q1, p4, t1);
	s1 = tmp.x;
	t1 = tmp.y;

	s2 = q2 + p5;
	tmp = two_sum(s1, t0); // s1 = qd::two_sum(s1, t0, t0);
	s1 = tmp.x;
	t0 = tmp.y;
	s2 += (t0 + t1);

	/* O(eps^3) order terms */
	s1 += a.x * b.w + a.y * b.z + a.z * b.y + a.w * b.x + q0 + q3 + q4 + q5;

	return renorm(p0, p1, s0, s1, s2); // qd::renorm(p0, p1, s0, s1, s2);
}

highp vec4 qs_div(highp vec4 a, highp vec4 b)
{
	highp float q0, q1, q2, q3;

	highp vec4 r = vec4(0.0);

	q0 = a.x / b.x;
	r = a - (b * q0);

	q1 = r.x / b.x;
	r -= (b * q1);

	q2 = r.x / b.x;
	r -= (b * q2);

	q3 = r.x / b.x;

	return renorm4(q0, q1, q2, q3);
}

highp float ds_compare(highp vec2 dsa, highp vec2 dsb)
{
	if (dsa.x < dsb.x) return -1.;
	else if (dsa.x == dsb.x)
	{
		if (dsa.y < dsb.y) return -1.;
		else if (dsa.y == dsb.y) return 0.;
		else return 1.;
	}
	else return 1.;
}

highp float qs_compare(highp vec4 qsa, highp vec4 qsb)
{
	if (ds_compare(qsa.xy, qsb.xy) < 0.) return -1.; // if (dsa.x < dsb.x) return -1.;
	else if (ds_compare(qsa.xy, qsb.xy) == 0.) // else if (dsa.x == dsb.x)
	{
		if (ds_compare(qsa.zw, qsb.zw) < 0.) return -1.; // if (dsa.y < dsb.y) return -1.;
		else if (ds_compare(qsa.zw, qsb.zw) == 0.) return 0.;// else if (dsa.y == dsb.y) return 0.;
		else return 1.;
	}
	else return 1.;
}

highp vec3 palette(in highp float t, in highp vec3 a, in highp vec3 b, in highp vec3 c, in highp vec3 d)
{
	return a + b * cos(6.28318 * (c * t + d));
}

highp float mandelbrot()
{
	highp vec4 fragCoordX = vec4(gl_FragCoord.x, vec3(0.0));
	highp vec4 fragCoordY = vec4(gl_FragCoord.y, vec3(0.0));
	highp vec4 zoomRender = vec4(zoom, 0.0, 0.0);

	highp vec4 c_r = qs_add(qs_div(fragCoordX, zoomRender), vec4(x, 0.0, 0.0));
	highp vec4 c_i = qs_add(qs_div(fragCoordY, zoomRender), vec4(y, 0.0, 0.0));
	highp vec4 z_r = vec4(0.0);
	highp vec4 z_i = vec4(0.0);
	highp vec4 two = vec4(2.0, vec3(0.0));
	highp vec4 renderRadius = vec4(radius, vec3(0.0));
	int i = 0;

	do
	{
		highp vec4 tmp = z_r;
		z_r = qs_add(qs_add(qs_mul(z_r, z_r), qs_mul(z_i, z_i) * -1), c_r);
		z_i = qs_add(qs_mul(qs_mul(z_i, tmp), two), c_i);
		i = i + 1;
	} while (qs_compare(qs_add(qs_mul(z_r, z_r), qs_mul(z_i, z_i)), renderRadius) <= 0.0 && i < max_iterations);

	return i;
}

void main()
{
	highp float i = 0;
	if (fractal_id == 0)
	{
		i = mandelbrot();
	}
	else
	{
		highp vec4 fragCoordX = vec4(gl_FragCoord.x, vec3(0.0));
		highp vec4 fragCoordY = vec4(gl_FragCoord.y, vec3(0.0));
		highp vec4 zoomRender = vec4(zoom, 0.0, 0.0);

		highp vec4 ok = qs_mul(qs_div(fragCoordX, zoomRender), qs_div(fragCoordY, zoomRender));
		gl_FragColor = vec4(ok.x, ok.x, ok.x, 1.0f);
		return;
	}

	if (i == max_iterations)
	{
		gl_FragColor = vec4(0.0f, 0.0f, 0.0f, 1.0f);
	}
	else
	{
		gl_FragColor = vec4(palette(i / float(max_iterations), colorA, colorB, colorC, colorD), 1.0f);
	}
};