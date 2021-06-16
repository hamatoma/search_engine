import 'package:dart_bones/dart_bones.dart';
import 'package:search_engine/search_engine.dart';

/// Prints some statistics about all classes from a file given from program arguments.
void main(List<String> args) {
  final logger = MemoryLogger(LEVEL_FINE);
  final engine = SearchEngineIo.fromFile(args[0], logger);
  final blockComment = Block([
    BlockEntry(
        BlockEntryType.sequence, RegExpSearcher(engine, pattern: r'^\s*///'))
  ]);
  final searcherEmpty = RegExpSearcher(engine, pattern: r'^\s*$');
  final searcherComment = RegExpSearcher(engine, pattern: r'^\s*//');
  final searcherClass =
      RegExpSearcher(engine, pattern: r'^(?:abstract )?class\s*(\w+)');
  final searcherApiComments = RegExpSearcher(engine, pattern: r'^\s*///');
  // over all classes:
  while (engine.search(searcherClass)) {
    final name = engine.lastMatch.group(1);
    // Search backward to the start of the documenting comments ("///...")
    if (!engine.findBlockStart(blockComment,
        offsetBackward: 1, startOfBlock: engine.currentRegion.start)) {
      /// No comments found: than the "class ..." line is the region start:
      engine.currentRegion.start.clone(engine.currentPosition);
    }
    final startClass = engine.currentPosition.line;
    if (!engine.search(RegExpSearcher(engine, regExp: RegExp(r'^\}')),
        skipLastMatch: true)) {
      logger.log('syntax error: missing "}"');
      break;
    } else {
      // Sets the end of the region:
      engine.currentRegion.end.clone(engine.currentPosition);
      final count = engine.currentPosition.line - startClass + 1;
      // Sets the current position to the region start:
      engine.goto(engine.currentRegion.start);
      // count() works inside the region only:
      final comments = engine.count(searcherComment);
      final apiComments = engine.count(searcherApiComments);
      final empty = engine.count(searcherEmpty);
      final code = count - comments - empty;
      print(
          'class $name: $count line(s), $comments comment(s), $apiComments API comments, $code line(s) of code');
      // Sets the current position at the end of the already handled class:
      engine.currentPosition.clone(engine.currentRegion.end);
      engine.currentRegion.start.clone(engine.currentPosition);
      // Expand the region to the text end.
      // Otherwise the search of the next class will fail
      engine.currentRegion.end.setEndOfText();
    }
  }
}
