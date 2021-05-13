#include "DoubleDouble.h"

std::vector<double> _two_sum_quick(double x, double y)
{
	double r = x + y;
	double e = y - (r - x);
	return { r, e };
}

std::vector<double> _two_sum(double x, double y)
{
	double r = x + y;
	double t = r - x;
	double e = (x - (r - t)) + (y - t);
	return { r, e };
}

std::vector<double> _two_difference(double x, double y)
{
	double r = x - y;
	double t = r - x;
	double e = (x - (r - t)) - (y + t);
	return { r, e };
}

std::vector<double> _two_product(double x, double y)
{
	double u = x * 134217729.0;
	double v = y * 134217729.0;
	double s = u - (u - x);
	double t = v - (v - y);
	double f = x - s;
	double g = y - t;
	double r = x * y;
	double e = ((s * t - r) + s * g + f * t) + f * g;
	return { r, e };
}

DoubleDouble::DoubleDouble(const double x, const double y) : x(x), y(y) {}

DoubleDouble DoubleDouble::operator+(const DoubleDouble& other)
{
	std::vector<double> tmp = _two_sum(x, other.x);
	tmp[1] += y + other.y;
	tmp = _two_sum_quick(tmp[0], tmp[1]);
	return DoubleDouble(tmp[0], tmp[1]);
}

DoubleDouble DoubleDouble::operator-(const DoubleDouble& other)
{
	std::vector<double> tmp = _two_difference(x, other.x);
	tmp[1] += y - other.y;
	tmp = _two_sum_quick(tmp[0], tmp[1]);
	return DoubleDouble(tmp[0], tmp[1]);
}

DoubleDouble DoubleDouble::operator*(const DoubleDouble& other)
{
	std::vector<double> tmp = _two_product(x, other.x);
	tmp[1] += x * other.y + y * other.x;
	tmp = _two_sum_quick(tmp[0], tmp[1]);
	return DoubleDouble(tmp[0], tmp[1]);
}

DoubleDouble DoubleDouble::operator/(const DoubleDouble& other)
{
	double r = x / other.x;
	std::vector<double> tmp = _two_product(r, other.x);
	double e = (x - tmp[0] - tmp[1] + y - r * other.y) / other.x;
	tmp = _two_sum_quick(r, e);
	return DoubleDouble(tmp[0], tmp[1]);
}

bool DoubleDouble::operator<(const DoubleDouble& other)
{
	return x < other.x || x == other.x && y < other.y;
}
