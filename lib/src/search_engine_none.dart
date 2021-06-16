import 'package:dart_bones/dart_bones.dart';
import 'search_engine.dart';

/// Extension of SearchEngine with functionality depending on dart:io.
class SearchEngineIo extends SearchEngine {
  /// This constructor defines the text by a file content.
  SearchEngineIo.fromFile(String filename, BaseLogger logger)
      : super([], logger) {
    throw UnsupportedError('SearchEngineIo.fromFile()');
  }
}
