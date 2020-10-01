import 'dart:html';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pathcreator/service_projectstorage.dart';
import 'package:vector_math/vector_math_64.dart';

import 'model_project.dart';
import 'sampler_arc.dart';
import 'sampler_simple.dart';
import 'widget_mybutton.dart';
import 'widget_rowcolumn.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        //primarySwatch: Colors.blue,
        // This makes the visual density adapt to the platform that you run
        // the app on. For desktop platforms, the controls will be smaller and
        // closer together (more dense) than on mobile platforms.
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  final GlobalKey _targetKey = GlobalKey();
  Controller controller;

  AnimationController animationController;

  @override
  void initState() {
    controller = Controller();

    animationController = AnimationController(
      lowerBound: 0,
      upperBound: 1,
      vsync: this,
      duration: Duration(seconds: 10),
    );
    animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) animationController.reset();
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    //if (controller.getAnim) controller.animTick = animationController.value;

    return Scaffold(
      backgroundColor: Color(0xff000000),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return RowColumn(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              children: <Widget>[
                Container(
                  alignment: Alignment.topCenter,
                  color: Color(0xff00ff00),
                  width: constraints.maxWidth * 0.1,
                  child: RowColumn(
                      width: constraints.maxHeight,
                      height: constraints.maxWidth,
                      children: <Widget>[
                        Text("Left"),
                        MyButton(
                          onPressed: () {
                            setState(() => controller
                                .setCurrentDrawFunction(DrawFunction.Add));
                          },
                          text: "ADD",
                          selected: controller.getCurrentDrawFunction ==
                              DrawFunction.Add,
                        ),
                        MyButton(
                          onPressed: () {
                            setState(() => controller
                                .setCurrentDrawFunction(DrawFunction.Insert));
                          },
                          text: "INSERT",
                          selected: controller.getCurrentDrawFunction ==
                              DrawFunction.Insert,
                        ),
                        MyButton(
                          onPressed: () {
                            setState(() => controller.zoomIn());
                          },
                          text: "ZOOM ${controller.getScale}",
                        ),
                        MyButton(
                          onPressed: () {
                            setState(() => controller.reset());
                          },
                          text: "RESET",
                        ),
                        MyButton(
                          onPressed: () {
                            setState(() => controller.toggleLoop());
                          },
                          text: "LOOP ${controller.getLoop}",
                          selected: controller.getLoop ? true : false,
                        ),
                        MyButton(
                          onPressed: () {
                            setState(() {
                              if (controller.getIsAnim == true)
                                animationController.stop();
                              else
                                animationController.forward();
                              controller.toggleAnim();
                            });
                          },
                          text: "ANIM ${controller.getIsAnim}",
                          selected: controller.getIsAnim ? true : false,
                        ),
                      ]),
                ),
                Expanded(
                  child: Container(
                    child: Stack(children: <Widget>[
                      Container(
                        alignment: Alignment.topCenter,
                        //decoration: BoxDecoration(color: Color(0x88aa0000)),
                        constraints: BoxConstraints.expand(),
                        child: Text(
                          "Path creator",
                          style:
                              TextStyle(fontSize: 50, color: Color(0xffffffff)),
                        ),
                      ),
                      Positioned.fill(
                        child: GestureDetector(
                          child: Transform(
                              origin: Offset.zero,
                              alignment: Alignment.topLeft,
                              transform: controller.getTransform,
                              child: AnimatedBuilder(
                                  animation: animationController,
                                  builder: (_, child) {
                                    controller
                                        .setAnimTick(animationController.value);
                                    return CustomPaint(
                                      key: _targetKey,
                                      painter: PathPainter(controller),
                                    );
                                  })),
                          onTapUp: (details) {
                            print(
                                "onTapUp | local:${details.localPosition} global:${details.globalPosition}");
                            _onTapUp(details);
                          },
                          onPanStart: (details) {
                            print(
                                "onPanStart | local:${details.localPosition} global:${details.globalPosition}");
                            _onPanStart(details);
                          },
                          onPanUpdate: (details) {
                            print(
                                "onPanUpdate | local:${details.localPosition} global:${details.globalPosition}");
                            _onPanUpdate(details);
                          },
                          onPanEnd: (details) {
                            print("onPanEnd");
                            _onPanEnd(details);
                          },
                        ),
                      ),
                    ]),
                  ),
                ),
                Container(
                  alignment: Alignment.topCenter,
                  color: Color(0xff00ff00),
                  width: constraints.maxWidth * 0.1,
                  child: RowColumn(
                      width: constraints.maxHeight,
                      height: constraints.maxWidth,
                      children: <Widget>[
                        Text("Right"),
                        MyButton(
                          onPressed: () => controller.printValues(),
                          text: "PRINT VALUES",
                        ),
                        MyButton(
                          onPressed: () {
                            if (kIsWeb) {
                              _startFilePicker();
                            } else {
                              controller.loadProject();
                            }
                          },
                          text: "Load project...",
                        ),
                        MyButton(
                          onPressed: () => controller.saveProject(),
                          text: "Save project...",
                        ),
                      ]),
                ),
              ]);
        },
      ),
    );
  }

  Offset toScene(Offset viewportPoint) {
    // On viewportPoint, perform the inverse transformation of the scene to get
    // where the point would be in the scene before the transformation.
    final Matrix4 inverseMatrix = Matrix4.inverted(controller._transform);
    final Vector3 untransformed = inverseMatrix.transform3(Vector3(
      viewportPoint.dx,
      viewportPoint.dy,
      0,
    ));
    return Offset(untransformed.x, untransformed.y);
  }

  Offset getTransformedPoint(Offset globalPosition) {
    print("getTransformedPoint glob:$globalPosition");
    final RenderBox renderBox =
        _targetKey.currentContext.findRenderObject() as RenderBox;
    final Offset zeroOffset = renderBox.localToGlobal(Offset.zero);
    final Offset offset = globalPosition - zeroOffset;
    final Offset scenePoint = /*_transformationController.*/ toScene(offset);
    print(
        "glob:$globalPosition zeroOff:$zeroOffset scenePoint:$scenePoint size:${renderBox.size}");

    return clampOffset(scenePoint, renderBox.size);
  }

  Offset clampOffset(Offset offset, Size size) {
    return Offset(
      offset.dx < 0
          ? 0
          : offset.dx > size.width
              ? size.width
              : offset.dx,
      offset.dy < 0
          ? 0
          : offset.dy > size.height
              ? size.height
              : offset.dy,
    );
  }

  void _onTapUp(TapUpDetails details) {
    print(
        "onTapUp | local:${details.localPosition} global:${details.globalPosition}");

    final Offset scenePoint = getTransformedPoint(details.globalPosition);
    /*
    final RenderBox renderBox =
        _targetKey.currentContext.findRenderObject() as RenderBox;
    final Offset offset =
        details.globalPosition - renderBox.localToGlobal(Offset.zero);
    final Offset scenePoint = /*_transformationController.*/ toScene(offset);
    //final boardPoint = _board.pointToBoardPoint(scenePoint);
    */
    setState(() {
      //_board = _board.copyWithSelected(boardPoint);

      controller.setIsMoving = false;
      controller.setCurrentPointIndex = null;
      if (controller.getCurrentDrawFunction == DrawFunction.Add)
        controller.add(scenePoint /*details.localPosition*/);
      if (controller.getCurrentDrawFunction == DrawFunction.Insert)
        controller.insert(scenePoint /*details.localPosition*/);
    });
  }

  void _onPanStart(DragStartDetails details) {
    print(
        "onPanStart | local:${details.localPosition} global:${details.globalPosition}");
    final Offset scenePoint = getTransformedPoint(details.globalPosition);

    //int i = controller.getPoint(details.localPosition);
    int i = controller.findSelectedPoint(scenePoint);
    if (i != null) {
      // found point
      controller.setIsMoving = true;
      controller.setCurrentPointIndex = i;
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    print(
        "onPanUpdate | local:${details.localPosition} global:${details.globalPosition}");
    final Offset scenePoint = getTransformedPoint(details.globalPosition);

    if (controller.getIsMoving) {
      setState(() {
        controller.updateIndex(controller.getCurrentPointIndex, scenePoint);
      });
    }
  }

  void _onPanEnd(DragEndDetails details) {
    print("onPanEnd");
    setState(() {
      controller.setIsMoving = false;
      controller.setCurrentPointIndex = null;
      controller.updatePath(true);
    });
  }

  _startFilePicker() async {
    InputElement uploadInput = FileUploadInputElement();
    uploadInput.click();

    uploadInput.onChange.listen((e) {
      // read file content as dataURL
      final FileList files = uploadInput.files;
      if (files.length == 1) {
        final File file = files[0];
        FileReader reader = FileReader();

        reader.onLoadEnd.listen((e) {
          setState(() {
            //uploadedImage = reader.result;
            String s = String.fromCharCodes(reader.result);
            ModelProject mp = ModelProject.fromJson(s);
            controller.setControlPoints(mp.getControlPoints);
          });
        });

        reader.onError.listen((fileEvent) {
          setState(() {
            //option1Text = "Some Error occured while reading the file";
          });
        });

        reader.readAsArrayBuffer(file);
      }
    });
  }
}

enum DrawFunction { Add, Insert }

class Controller {
  DrawFunction _currentDrawFunction = DrawFunction.Add;
  List<Offset> _controlPoints = List<Offset>();
  List<Offset> get getControlPoints => _controlPoints;
  double controlPointRadius = 8;
  double pathPointRadius = 1;
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

  int findSelectedPoint(Offset offset) {
    for (int i = 0; i < _controlPoints.length; i++) {
      Offset controlPoint = _controlPoints[i];
      double tolerance = 1.0;
      if ((offset - controlPoint).distance <= controlPointRadius + tolerance) {
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

double offDistance(Offset o1, Offset o2) {
  return (o2 - o1).distance;
}

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

    if (controller._controlPoints.length > 3) {
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

    for (int i = 0; i < controller.getControlPoints.length; i++) {
      Offset cp = controller.getControlPoints[i];
      canvas.drawCircle(cp, controller.controlPointRadius,
          i == 0 ? paintFirstPoint : paintPoint);

      if (controller._currentPointIndex == i)
        canvas.drawCircle(cp, controller.controlPointRadius, paintSelected);
    }

    //_paintArcSampler(canvas, size);

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
