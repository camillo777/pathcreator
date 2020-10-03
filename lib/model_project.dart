import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'utils.dart';

extension Json on Offset {
  static const String _tag = "Offset";

  Map toJson() {
    prnow(_tag, "toJson");
    return {
      'dx': double.parse("${this.dx.toStringAsFixed(3)}"),
      'dy': double.parse("${this.dy.toStringAsFixed(3)}"),
    };
  }
}

class ModelProject {
  static const _tag = "ModelProject";

  List<Offset> _controlPoints = List<Offset>();
  List<Offset> get getControlPoints => _controlPoints;

  ModelProject({@required List<Offset> controlPoints}) {
    _controlPoints = controlPoints;
  }

  Map<String, dynamic> toJson() {
    prnow(_tag, "toJson");
    List<Map> jsonControlPoints = this._controlPoints != null
        ? _controlPoints.map((i) => i.toJson()).toList()
        : null;

    return {
      'ver': "1",
      'controlPoints': jsonControlPoints,
    };
  }

  factory ModelProject.fromJson(String json) {
    prnow(_tag, "fromJson");
    prnow(_tag, "$json");
    Map map = jsonDecode(json);
    List list = map["controlPoints"];
    List<Offset> offsets = list.map((e) => Offset(e["dx"], e["dy"])).toList();
    return ModelProject(controlPoints: offsets);
  }
}
