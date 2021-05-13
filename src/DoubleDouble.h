#pragma once

#include <vector>

class DoubleDouble
{
	double x;
	double y;

public:
	DoubleDouble(double x = 0.0, double y = 0.0);

	DoubleDouble operator + (const DoubleDouble& other);
	DoubleDouble operator - (const DoubleDouble& other);
	DoubleDouble operator * (const DoubleDouble& other);
	DoubleDouble operator / (const DoubleDouble& other);
	bool operator < (const DoubleDouble& other);

	inline float to_float() const { return static_cast<float>(x); }
	inline double to_double() const { return x; }
	inline std::vector<double> to_double_double() const { return { x, y }; }
};
