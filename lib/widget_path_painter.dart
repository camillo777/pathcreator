import 'package:flutter/rendering.dart';

import 'controller.dart';

class PathPainter extends CustomPainter {
  final Paint paintFirstPoint = Paint()..color = Color(0xffff0000);
  final Paint paintPoint = Paint()
    ..color = Color(0xffff0000)
    ..style = PaintingStyle.stroke;
  final Paint paintSelected = Paint()..color = Color(0xffff00ff);
  final Paint paintGreen = Paint()
    ..color = Color(0xff00ff00)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  final Paint paintBlue = Paint()
    ..color = Color(0xff0000ff)
    ..style = PaintingStyle.stroke;
  final Paint paintDebug = Paint()
    ..color = Color(0xff888888)
    ..style = PaintingStyle.stroke;
  final Paint paintArcSampler = Paint()
    ..color = Color(0xffffff00)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;

  final Controller controller;

  PathPainter(this.controller);

  @override
  void paint(Canvas canvas, Size size) {
    _paintCanvas(canvas, size);

    // paint spline in N steps
    if (controller.getControlPoints.length > 3) {
      if (controller.getPath != null) {
        Path path = Path();
        for (int i = 0; i < controller.steps; i++) {
          final double t = i / controller.steps.toDouble();
          Offset offset = controller.getPath.transform(t);
          if (i == 0)
            path.moveTo(offset.dx, offset.dy);
          else
            path.lineTo(offset.dx, offset.dy);
          canvas.drawCircle(offset, controller.pathPointRadius, paintBlue);
        }
        canvas.drawPath(path, paintGreen);
      }
    }

    // paint control points
    for (int i = 0; i < controller.getControlPoints.length; i++) {
      Offset cp = controller.getControlPoints[i];
      canvas.drawCircle(cp, controller.controlPointRadius,
          i == 0 ? paintFirstPoint : paintPoint);

      if (controller.getCurrentPointIndex == i)
        canvas.drawCircle(cp, controller.controlPointRadius*2, paintSelected);
    }

    // paint arc sampled constant speed parametrization
    if (controller.getArcSampler != null) {
      controller.getArcSampler.drawSamples(canvas, paintDebug);
      controller.getArcSampler.drawNewSamples(canvas, paintArcSampler);
    }


    /*if ((controller.getIsAnim) && (controller.getArcSampler != null)) {
      print("${controller.getAnimTick}");
      //Offset pos = controller?._arcSampler?.curve(controller.getAnimTick);
      int i = (controller.getAnimTick * controller.getArcSampler.steps).floor();
      Offset pos = Offset.lerp(
        controller.getArcSampler.getNewSamples[i],
        controller.getArcSampler.getNewSamples[i + 1],
        t,
      );
      //Offset pos = controller.getArcSampler.curve(controller.getAnimTick);
      canvas.drawRect(
          Rect.fromCenter(center: pos, width: 15, height: 15), paintDebug);
    }
    */
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }

  void _paintCanvas(Canvas canvas, Size size) {
    canvas.drawLine(Offset.zero, Offset(size.width, size.height), paintDebug);
    canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), paintDebug);
  }

  /*void _paintArcSampler(Canvas canvas, Size size) {
    if (controller.getArcSampler != null) {
      /*
      double step = 0.01;
      for (double t = 0; t < 1 - step; t += step) {
        double t1 = t;
        double t2 = t + step;
        Offset o1 = controller.getArcSampler.curve(t1);
        Offset o2 = controller.getArcSampler.curve(t2);
        canvas.drawLine(o1, o2, paintArcSampler);
      }*/

      double step = 0.01;
      for (double s = 0; s < 1; s += step) {
        /*double t1 = t;
        double t2 = t + step;*/
        Offset o1 = controller.getArcSampler.curve(s);
        //Offset o2 = controller.getArcSampler.curve(t2);
        canvas.drawCircle(o1, 3, paintArcSampler);
      }
    }
  }*/
}