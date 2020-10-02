import 'dart:ui';

import 'package:flutter/animation.dart';
import 'package:vector_math/vector_math_64.dart';

import 'model_project.dart';
import 'sampler_arc.dart';
import 'service_projectstorage.dart';
import 'utils.dart';

enum DrawFunction { AddPoint, InsertPoint, MovePoint }

class Controller {
  static const _tag = "Controller";

  DrawFunction _currentDrawFunction = DrawFunction.AddPoint;
  List<Offset> _controlPoints = List<Offset>();
  List<Offset> get getControlPoints => _controlPoints;
  double controlPointToucheRadius = 0.005;
  double controlPointDrawRadius = 8;
  double pathPointDrawRadius = 1;
  int steps = 100;
  double _scale = 1.0;
  bool _loop = true;

  CatmullRomSpline _path;
  CatmullRomSpline get getPath => _path;

  bool _isMoving = false;
  bool get getIsMoving => _isMoving;
  set setIsMoving(bool v) => _isMoving = v;

  int _currentPointIndex;
  int get getCurrentPointIndex => _currentPointIndex;
  set setCurrentPointIndex(int v) => _currentPointIndex = v;

  bool _isAnim = false;
  bool get getIsAnim => _isAnim;
  double _animTick;

  Matrix4 _transform = Matrix4.identity()..scale(1.0);
  Matrix4 get getTransform => _transform;

  // translate and scale from 0-1920 to 0-1
  /*Matrix4 _transformViewPort = Matrix4.identity()..scale(1.0);
  Matrix4 get getTransformViewPort => _transformViewPort;
  void setViewPortTransform(Size size) {
    double xScaleFactor = 1 / size.width;
    double yScaleFactor = 1 / size.height;
    _transformViewPort = Matrix4.identity()
      ..scale(xScaleFactor, yScaleFactor, 0);
  }*/

  /*Offset toViewport01(Offset widgetPoint) {
    // On viewportPoint, perform the inverse transformation of the scene to get
    // where the point would be in the scene before the transformation.
    final Matrix4 inverseMatrix = Matrix4.inverted(getTransformViewPort);
    final Vector3 untransformed = inverseMatrix.transform3(Vector3(
      widgetPoint.dx,
      widgetPoint.dy,
      0,
    ));
    return Offset(untransformed.x, untransformed.y);
  }*/

  /*void resize(Size size) {
    setViewPortTransform(size);
  }*/

  ArcSampler2 _arcSampler;
  ArcSampler2 get getArcSampler => _arcSampler;

  /*SimpleSampler2 _simpleSampler;
  SimpleSampler2 get getSimpleSampler => _simpleSampler;*/

  void setCurrentDrawFunction(DrawFunction df) {
    _currentDrawFunction = df;
  }

  DrawFunction get getCurrentDrawFunction => _currentDrawFunction;

  void zoomIn() {
    _transform.scale(2);
    _scale *= 2;
  }

  void zoomOut() {
    _transform.scale(0.5);
    _scale /= 2;
  }

  double get getScale => _scale;

  void toggleLoop() {
    _loop = !_loop;
    updatePath(true);
  }

  bool get getLoop => _loop;

  void toggleAnim() {
    _isAnim = !_isAnim;
    //updatePath();
  }

  void setAnimTick(double tick) => _animTick = tick;
  double get getAnimTick => _animTick;

  void updatePath(bool update) {
    print("updatePath");
    if (_controlPoints.length > 3) {
      List<Offset> newList = List.from(_controlPoints);
      if (_loop) newList.add(_controlPoints[0]);
      _path = CatmullRomSpline.precompute(
        newList,
        //endHandle: _controlPoints[0],
      );

      //_path.transformInternal(t)

      /*

      For arc reparameterization, you can make a it follow the distance with much more fidelity with another technique, but you're going to need the derivative of the curve (LibGDX has, for example).

vec2 point = catmullCurve.calculate(t);
vec2 derivative = catmullCurve.calculateDerivative(t);
and instead of increasing t by a fixed step, you increase it with the the inverse of the derivative times some speed factor:

//DON'T:
t += 0.1f;
//DO:
t += 0.1f / derivative.len();
You can see the wiki article I wrote for LibGDX on Splines, take a look at the last snippet, "Make the sprite traverse at constant speed".
*/

      //_arcSampler = ArcSampler(_path, 200);
      //_arcSampler.checkArcSampler();

      //_simpleSampler = SimpleSampler2(_path, 100);
      if (update) _arcSampler = ArcSampler2(_path.transform, 100);
    }
  }

  void add(Offset controlPoint) {
    print("add | controlPoint:$controlPoint");
    _controlPoints.add(controlPoint);
    print("add | # points: ${_controlPoints.length}");
    updatePath(true);
  }

  void remove(Offset controlPoint) {
    print("remove | controlPoint:$controlPoint");
    _controlPoints.removeWhere((element) => element == controlPoint);
    print("remove | # points: ${_controlPoints.length}");
    updatePath(true);
  }

  void updateIndex(int i, Offset offset) {
    print("updateIndex | i:$i offset:$offset");
    _controlPoints[i] = offset;
    updatePath(false);
  }

  int findSelectedPoint(Offset offset) { //, {double tolerance = 0.01}) {
    prnow(_tag, "findSelectedPoint | offset:$offset");
    for (int i = 0; i < _controlPoints.length; i++) {
      // points are in 0-1 interval
      Offset controlPoint = _controlPoints[i];
      //double tolerance = 1.0;
      if ((offset - controlPoint).distance <= controlPointToucheRadius) {
        // this point
        print("getPoint | offset:$offset i:$i controlPoint:$controlPoint");
        return i;
      }
    }
    return null;
  }

  void insert(Offset controlPoint) {
    print("insert | controlPoint:$controlPoint");
    double minDistance;
    int index = -1;
    for (int i = 0; i < _controlPoints.length - 1; i++) {
      double newd = _checkDistance(controlPoint, i);
      print("$newd $index");
      if (minDistance == null) {
        minDistance = newd;
        index = i;
      } else {
        if (newd < minDistance) {
          minDistance = newd;
          index = i;
        }
      }
    }
    // last check is between last point and first
    double newd = _checkDistance(controlPoint, _controlPoints.length - 1);
    if (newd < minDistance) {
      minDistance = newd;
      index = _controlPoints.length - 1;
      _controlPoints.add(controlPoint);
    } else {
      // insert after index
      if (index != -1) {
        _controlPoints.insert(index + 1, controlPoint);
      }
    }
    print("insert | # points: ${_controlPoints.length}");
    updatePath(true);
  }

  double _checkDistance(Offset controlPoint, int index) {
    int next = (index + 1) % _controlPoints.length;
    print("$index $next");
    Offset p1 = _controlPoints[index];
    Offset p2 = _controlPoints[next];
    double d1 = offDistance(controlPoint, p1);
    double d2 = offDistance(controlPoint, p2);
    double newd = d1 + d2;
    return newd;
  }

  void reset() {
    _controlPoints.clear();
    _scale = 1.0;
    _isMoving = false;
    _currentPointIndex = null;
    _arcSampler = null;
  }

  void printValues() {
    print("printValues | len:${getArcSampler.getNewSamples.length}");
    String s = "";
    //s += "List<Offset> controlPoints = [";
    s += " [";
    for (int i = 0; i < getArcSampler.getNewSamples.length; i++) {
      Offset o = getArcSampler.getNewSamples[i];
      s += "Offset(${o.dx},${o.dy}),";
    }
    s += "];";
    print(s);
  }

  void loadProject() async {
    print("loadProject");
    ProjectStorage ps = ProjectStorage();
    ModelProject mp = await ps.loadProject();
    setControlPoints(mp.getControlPoints);
  }

  void saveProject() async {
    print("saveProject");
    ModelProject mp = ModelProject(controlPoints: _controlPoints);
    ProjectStorage ps = ProjectStorage();
    await ps.saveProject(mp);
  }

  void setControlPoints(List<Offset> controlPoints) {
    _controlPoints = controlPoints;
    updatePath(true);
  }
}
