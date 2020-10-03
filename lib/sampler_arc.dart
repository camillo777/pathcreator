// http://www.planetclegg.com/projects/WarpingTextToSplines.html

import 'dart:ui';

import 'utils.dart';

typedef Offset ParametricCurve2D(double t);

class ArcSampler2 {
  static const String _tag = "ArcSampler2";
  static const bool _debug = false;

  final int steps; // 100
  List<Offset> _samples; // 0 to 100 = lenght:101
  List<double> _arcLengths; // 0 to 100 = lenght:101
  List<Offset> _newSamples; // 0 to 100 = lenght:101
  List<Offset> get getNewSamples => _newSamples;

  ArcSampler2(ParametricCurve2D transform, this.steps) {
    int maxPoint = steps + 1;

    _samples = List<Offset>.filled(maxPoint, null);
    _arcLengths = List<double>.filled(maxPoint, null);
    _newSamples = List<Offset>.filled(maxPoint, null);

    // calculate samples
    _samples[0] = transform(0);
    _arcLengths[0] = 0;
    double totalLenght = 0;
    for (int i = 1; i <= steps; i++) {
      double t = i / steps;
      _samples[i] = transform(t);

      double segmentLen = (_samples[i] - _samples[i - 1]).distance;
      totalLenght += segmentLen;

      _arcLengths[i] = totalLenght;
    }

    // debug print samples
    if (_debug) {
      for (int i = 0; i <= steps; i++) {
        print("i:$i sample:${_samples[i]} ${_arcLengths[i]}");
      }
      print("totalLenght: $totalLenght");
    }

    // arc-length parameterization
    _newSamples = List<Offset>();
    int alpSteps = 100;
    double alpStep = 1 / alpSteps;
    double u = 0;
    for (int i = 0; i <= alpSteps; i++) {
      double t = _arcLengthParameterization(u);
      assert(t >= 0);
      assert(t <= 1);
      //_newSamples[i] = transform(t);
      _newSamples.add(transform(t));
      u += alpStep;
      if (u > 1) u = 1;
    }
  }

  // returns t from u
  double _arcLengthParameterization(double u) {
    if (_debug) prnow(_tag, "_arcLengthParameterization | u:$u");
    assert(u >= 0);
    assert(u <= 1);

    // get the target arcLength for curve for parameter u
    double targetArcLength = u * _arcLengths[_arcLengths.length - 1];
    //prnow(_tag, "targetArcLength: $targetArcLength");

    // the next function would be a binary search, for efficiency
    int index = _indexOfLargestValueSmallerThan(targetArcLength);
    assert(index < _arcLengths.length);

    double t;

    // if exact match, return t based on exact index
    if (_arcLengths[index] == targetArcLength) {
      if (_debug) print("exact match: $targetArcLength");
      t = index / (_arcLengths.length - 1);
    } else // need to interpolate between two points
    {
      double lengthBefore = _arcLengths[index];

      assert(index + 1 < _arcLengths.length);
      double lengthAfter = _arcLengths[index + 1];
      double segmentLength = lengthAfter - lengthBefore;

      // determine where we are between the 'before' and 'after' points.
      double segmentFraction = (targetArcLength - lengthBefore) / segmentLength;

      // add that fractional amount to t
      t = (index + segmentFraction) / (_arcLengths.length - 1);
    }

    assert(t >= 0);
    assert(t <= 1);
    assert(t != null);
    return t;
  }

  // find the index of the largest entry in the table that is smaller than or equal to
  // the desired arcLength
  int _indexOfLargestValueSmallerThan(targetArcLength) {
    if (_debug)
      print("_indexOfLargestValueSmallerThan | targetArcLength:$targetArcLength ${_arcLengths.length}");

    for (int i = 1; i < steps; i++) {
      double lower = _arcLengths[i - 1];
      double upper = _arcLengths[i];
      if (targetArcLength >= lower && targetArcLength < upper) {
        return i;
      }
    }
    if (_debug) print("END ${_arcLengths.length - 1}");
    return _arcLengths.length - 2;

    //throw Exception("Not found for $targetArcLength");
  }

  void drawSamples(Canvas canvas, Paint paint, Size size) {
    print("drawSamples");
    Offset previous = toScr(_samples[0], size);
    for (int i = 1; i < _samples.length; i++) {
      Offset current = toScr(_samples[i], size);
      canvas.drawCircle(current, 2, paint);
      canvas.drawLine(previous, current, paint);
      previous = current;
    }
  }

  void drawNewSamples(Canvas canvas, Paint paint, Size size) {
    print("drawNewSamples");
    Offset previous = toScr(_newSamples[0], size);
    for (int i = 1; i < _newSamples.length; i++) {
      Offset current = toScr(_newSamples[i], size);
      canvas.drawCircle(current, 2, paint);
      canvas.drawLine(previous, current, paint);
      previous = current;
    }
  }

  Offset toScr(Offset normalized, Size size) {
    return Offset(normalized.dx * size.width, normalized.dy * size.height);
  }
}

/*
// https://gamedevnotesblog.wordpress.com/2017/09/20/reverse-arc-length-parameterization-example-package/

// This could have as many coordinates as you want, but make sure
// to change the distance function accordingly
typedef Position = { x:Float, y:Float };

typedef Parametric = Float -> Position;

// Computes a reverse arc-length parameterization to solve the
// travel speed problem and give samples with O(1) complexity.
// For the sake of simplicity, the code is somewhat unoptimized.
// The initialization stage is O(n^2) but could be brought to
// O(n log(n)).
class ArcSampler
{
	private var samples:Array<Position> = new Array<Position>();
	private var indices:Array<Int> = new Array<Int>();
	
	// Distance between two 2D points
	static private function distance(a:Position, b:Position) : Float
	{
		var x = a.x - b.x, y = a.y - b.y;
		return Math.sqrt(x * x + y * y);
	}
	
	// f is the parametrisation of the curve, ie a function of time
	// steps is the amount of steps, ie the number of samples - 1
	// t will be in the closed interval [lowt, hight]
	public function new(f:Parametric, steps:Int, ?lowt = 0., ?hight = 1.)
	{
		var lengths = new Array<Float>();
		// Convenience function to map [0, 1] to [lowt, hight] linearly
		var range = function (t:Float) return lowt + t * (hight - lowt);

		// Direct application of the reverse arc-length parameterization algorithm
		lengths.push(0);
		samples.push(f(range(0)));
		if(steps < 1)
			throw "ArcSampler : must use at least one step";
		for(i in 1 ... steps + 1)
		{
			samples.push(f(range(i / steps)));
			lengths.push(distance(samples[i], samples[i-1]) + lengths[i-1]);
		}
		for(i in 1 ... steps + 1)
			lengths[i] /= lengths[steps];

		indices[0] = 0;
		for(i in 1 ... steps + 1)
		{
			var s = i / steps;
			// Index of the highest length that is less or equal to s
			// Can be optimized with a binary search instead
			var j = lengths.filter(function(l) return l <= s).length - 1;
			indices.push(j);
		}
	}

	// Linear interpolation with factor t between a and b
	static private function lerp(a:Position, b:Position, t:Float) : Position
	{
		return { x:(1 - t) * a.x + t * b.x, y:(1 - t) * a.y + t * b.y};
	}

	// Returns the point at length s% of the total length of the curve
	// using the reverse arc-length parameterization
	public function curve(s:Float) : Position
	{
		if(s < 0 || s > 1)
			throw "Invalid s parameter : must be in [0, 1]";
		if(s == 1)
			return samples[samples.length - 1];
		var i = Std.int(s * indices.length);
		var t = indices[i];
		return lerp(samples[t], samples[t+1], s * indices.length - i);
	}
}

// This could have as many coordinates as you want, but make sure
// to change the distance function accordingly
//typedef Position = { x:Float, y:Float };

//typedef Parametric = Float -> Position;
//typedef Offset Parametric(double);

// Computes a reverse arc-length parameterization to solve the
// travel speed problem and give samples with O(1) complexity.
// For the sake of simplicity, the code is somewhat unoptimized.
// The initialization stage is O(n^2) but could be brought to
// O(n log(n)).
class ArcSampler {
  List<Offset> samples = List<Offset>();
  List<int> indices = List<int>();

  // Distance between two 2D points
  static double distance(Offset a, Offset b) {
    double x = a.dx - b.dx;
    double y = a.dy - b.dy;
    return sqrt(x * x + y * y);
  }

  // f is the parametrisation of the curve, ie a function of time
  // steps is the amount of steps, ie the number of samples - 1
  // t will be in the closed interval [lowt, hight]
  ArcSampler(Curve2D f, int steps) {
    List<double> lengths = List<double>();
    // Convenience function to map [0, 1] to [lowt, hight] linearly
    //var range = function (t:Float) return lowt + t * (hight - lowt);

    // Direct application of the reverse arc-length parameterization algorithm
    lengths.add(0);
    samples.add(f.transform(0));
    if (steps < 1) throw "ArcSampler : must use at least one step";

    print("add steps");
    //for (int i = 1; i <= steps + 1; i++) {
    for (int i = 1; i <= steps; i++) {
      samples.add(f.transform(i / steps));
      lengths.add(distance(samples[i], samples[i - 1]) + lengths[i - 1]);
    }

    print("calculate samples:${samples.length} lengths:${lengths.length}");
    for (int i = 1; i <= steps; i++) lengths[i] /= lengths[steps];

    print("calculate indices");
    //indices[0] = 0;
    indices.add(0);
    for (int i = 1; i <= steps; i++) {
      double s = i / steps;
      // Index of the highest length that is less or equal to s
      // Can be optimized with a binary search instead
      int j = lengths.where((l) => l <= s).length - 1;
      indices.add(j);
    }
    print("calculated indices:${indices.length}");
  }

  // Linear interpolation with factor t between a and b
  /*static Offset lerp(Offset a, Offset b, t:Float) : Position
    {
        return { x:(1 - t) * a.x + t * b.x, y:(1 - t) * a.y + t * b.y};
    }*/

  // Returns the point at length s% of the total length of the curve
  // using the reverse arc-length parameterization
  Offset curve(double s) {
    if (s < 0 || s > 1) throw "Invalid s parameter : must be in [0, 1]";
    if (s == 1) return samples[samples.length - 1];
    int i = (s * indices.length).floor();
    var t = indices[i];
    return Offset.lerp(samples[t], samples[t + 1], s * indices.length - i);
  }

  /*void checkArcSampler() {
    double step = 0.01;
    double distance;
    for (double t = 0; t < 1 - step; t += step) {
      double t1 = t;
      double t2 = t + step;
      Offset o1 = curve(t1);
      Offset o2 = curve(t2);
      double newDistance = offDistance(o1, o2);
      print("distance: $distance newDistance: $newDistance");
      //if (t != 0) assert(distance == newDistance);
      distance = newDistance;
    }
  }*/
}
*/
