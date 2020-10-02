import 'dart:html';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';

import 'controller.dart';
import 'model_project.dart';
import 'widget_mybutton.dart';
import 'widget_path_painter.dart';
import 'widget_rowcolumn.dart';

const int vbuild = 1;

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
        // This makes the visual density adapt to the platform that you run
        // the app on. For desktop platforms, the controls will be smaller and
        // closer together (more dense) than on mobile platforms.
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);
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
                          "Path creator v.$vbuild",
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
    final Matrix4 inverseMatrix = Matrix4.inverted(controller.getTransform);
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
    int i = controller.findSelectedPoint(scenePoint, tolerance: 10.0);
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


