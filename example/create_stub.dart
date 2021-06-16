import 'dart:io';
//import 'package:search_engine/search_engine.dart';

String buildStub(List<String> lines) {
  var rc = '';
  return rc;
}

void main(List<String> args) {
  if (args.isEmpty) {
    print('+++ missing argument');
  } else {
    final name = args[0];
    final file = File(name);
    if (!file.existsSync()) {
      print('+++ not a file: $name');
    } else {
      final lines = file.readAsLinesSync();
      print(buildStub(lines));
    }
  }
}
