//import 'dart:html';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'model_project.dart';
import 'utils.dart';

//import 'dart:js' as js;
import 'dart:html' as html;

class ProjectStorage {
  static const _tag = "ProjectStorage";

  Future<String> get getLocalPath async {
    prnow(_tag, "getLocalPath");
    final directory = await getApplicationDocumentsDirectory();

    prnow(_tag, "directory: $directory");

    return directory.path;
  }

  Future<File> get getLocalFile async {
    prnow(_tag, "getLocalFile");
    final path = await getLocalPath;
    return File('$path/project.json');
  }
  

  Future<ModelProject> loadProject() async {
    prnow(_tag, "loadProject");
    try {
      if (kIsWeb){

      }
      else {

      }
      final file = await getLocalFile;

      // Read the file
      String contents = await file.readAsString();

      return ModelProject.fromJson(contents);
      //return jsonDecode(contents);
    } catch (e) {
      // If encountering an error, return 0
      return ModelProject(controlPoints: []);
    }
  }

  Future<void> saveProject(ModelProject project) async {
    prnow(_tag, "saveProject");

    if (kIsWeb) {
      prnow(_tag, "${project.toJson()}");
      final bytes = utf8.encode(jsonEncode(project));
      
      /*
      //final text = 'this is the text file';
      
      
      
      final script =
          html.document.createElement('script') as html.ScriptElement;
      script.src = "http://cdn.jsdelivr.net/g/filesaver.js";

      html.document.body.nodes.add(script);
      

// calls the "saveAs" method from the FileSaver.js libray
      js.context.callMethod("saveAs", [
        html.Blob([bytes]),
        "testText.json", //File Name (optional) defaults to "download"
        "application/json; charset=UTF-8" //File Type (optional)
      ]);

      // cleanup
      html.document.body.nodes.remove(script);
      */

  //File file = // generated somewhere
  //final rawData = file.readAsBytesSync();
  final content = base64Encode(bytes);
  final anchor = html.AnchorElement(
      href: "data:application/json; charset=UTF-8;base64,$content")
    ..setAttribute("download", "file.txt")
    ..click();

    } else {
      final file = await getLocalFile;
      file.writeAsString(jsonEncode(project.toJson()));
    }

    // Write the file
    //return file.writeAsString(jsonEncode(project));

    
  }
}
