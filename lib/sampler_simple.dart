import 'package:flutter/widgets.dart';

class SimpleSampler {
  List<Offset> samples = List<Offset>();
  List<int> indices = List<int>();

  SimpleSampler(Curve2D f, int steps) {
    for (int i = 0; i < steps; i++) {
      double t = i / steps;
      samples.add(f.transform(t));
      indices.add(i);
    }
    samples.add(f.transform(1));
    indices.add(steps);
  }

  // Returns the point at length s% of the total length of the curve
  // using the reverse arc-length parameterization
  Offset curve(double s) {
    if (s < 0 || s > 1) throw "Invalid s parameter : must be in [0, 1]";
    if (s == 1) return samples[samples.length - 1];
    int i = (s * indices.length).floor();
    var t = indices[i];
    return Offset.lerp(samples[t], samples[t + 1], s * indices.length - i);
  }

  void draw(Canvas canvas, Size size, Paint paint) {
    double step = 0.01;
    for (double s = 0; s < 1; s += step) {
      /*double t1 = t;
        double t2 = t + step;*/
      Offset o1 = this.curve(s);
      //Offset o2 = controller.getArcSampler.curve(t2);
      canvas.drawCircle(o1, 3, paint);
    }
  }
}

class SimpleSampler2 {
  List<Offset> samples; //= List<Offset>();
  List<int> indices; //= List<int>();

  SimpleSampler2(Curve2D f, int steps) {
    /*for (int i = 0; i < steps; i++) {
      double t = i / steps;
      samples.add(f.transform(t));
      indices.add(i);
    }
    samples.add(f.transform(1));
    indices.add(steps);*/

    samples = List<Offset>.filled(steps + 1, Offset.zero);
    indices = List<int>.filled(steps + 1, 0);

    List<double> lengths = List<double>.filled(steps + 1, 0);
    lengths[0] = 0;
    samples[0] = f.transform(0);
    for (int i = 1; i <= steps; i++) {
      samples[i] = f.transform(i / steps);
      // approximate curve length at every sample point
      // lengths[i] = distance(samples[i], samples[i-1]) + lengths[i-1]
      lengths[i] = (samples[i] - samples[i - 1]).distance + lengths[i - 1];
      print("i:$i samples[i]:${samples[i]} lengths[i]:${lengths[i]}");
    }
// normalize lengths to be between 0 and 1
//lengths = lengths / lengths[k]
    for (int i = 0; i < lengths.length; i++) {
      lengths[i] = lengths[i] / lengths[steps];
    }

    lengths.forEach((len) {
      assert(len >= 0 && len <= 1);
    });

    indices[0] = 0;
    for (int i = 1; i <= steps; i++) {
      double s = i / steps;

      // find j = so that lengths[j] <= s < lengths[j+1]
      int j = -1;
      for (int l = 0; l < lengths.length - 1; l++) {
        if (s == 1.0) {
          j = lengths.length - 2;
          break;
        }
        if ((s >= lengths[l]) && (s < lengths[l + 1])) {
          //print("$l $s");
          print("indices i:$i => j:$l lengths.length:${lengths.length} ${lengths[l]}<=$s<${lengths[l+1]}");
          j = l;
          break;
        }
      }

      if (j == -1) {
        throw Exception("$s");
      }
      
      indices[i] = j;
    }

    //_checkArcSampler();
  }

  // Returns the point at length s% of the total length of the curve
  // using the reverse arc-length parameterization
  /*
  function curve(s):
  i = floor(s * indices.length)
  t = indices[i]
  point = lerp(samples[t], samples[t+1], s * indices.length - i)
  return point
  */
  Offset curve(double s) {
    if (s < 0 || s > 1) throw "Invalid s parameter : must be in [0, 1]";
    if (s == 1) return samples[samples.length - 1];
    int i = (s * indices.length).floor();
    assert(i < indices.length);
    int t = indices[i];
    if (t >= samples.length - 1)
      print("s:$s i:$i t:$t t+1:${t + 1} ${samples.length}");
    assert(t < samples.length - 1);
    return Offset.lerp(samples[t], samples[t + 1], s * indices.length - i);
  }

  void draw(Canvas canvas, Size size, Paint paint) {
    double steps = 10;
    double step = 1 / steps;
    for (double s = 0; s <= 1; s += step) {
      /*double t1 = t;
        double t2 = t + step;*/
      Offset o1 = this.curve(s);
      //Offset o2 = controller.getArcSampler.curve(t2);
      canvas.drawCircle(o1, 3, paint);
      drawText(canvas, o1, "${s.toStringAsFixed(2)}");
    }
  }

  void drawText(Canvas canvas, Offset position, String text) {
    final TextPainter textPainter = TextPainter(
        text: TextSpan(
            text: text,
            style: TextStyle(color: Color(0xffff0000), fontSize: 12)),
        textAlign: TextAlign.justify,
        textDirection: TextDirection.ltr)
      ..layout(); //maxWidth: size.width - 12.0 - 12.0);

    textPainter.paint(canvas, position);
  }

  void _checkArcSampler() {
    double steps = 1000;
    double step = 1 / steps;
    double distance;
    for (double t = 0; t < 1 - step; t += step) {
      double t1 = t;
      double t2 = t + step;
      Offset o1 = curve(t1);
      Offset o2 = curve(t2);
      double newDistance = (o2 - o1).distance;
      print("$t distance: $distance newDistance: $newDistance o1:$o1 o2:$o2");
      //if (t != 0) assert(distance == newDistance);
      distance = newDistance;
    }
  }
}
