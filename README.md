A text engine for inserting/deleting 
and a search engine for searching and replacing in a text
given by a file, or a list of lines.

## Glossary:

* A **position** is a well known location in the text, given by a line index (0..N-1) and a column index (0..M-1)
* A **region** is a part of the text given by a start / end position. The end position of the region is outside the region (exclusive).
* A **block** is a lot of consecutive lines that can described by three regular expressions:
  * an optional pattern of the start line
  * an optional pattern of the end line
  * a pattern describing the rest lines or a pattern describing lines not part of the block

Created from templates made available by Stagehand under a BSD-style
[license](https://github.com/dart-lang/stagehand/blob/master/LICENSE).

## Usage

A simple usage example:

```dart
import 'package:dart_bones/dart_bones.dart';
import 'package:search_engine/search_engine.dart';

/// Prints some statistics about all classes from a file given from program arguments.
void main(List<String> args) {
  final logger = MemoryLogger(LEVEL_FINE);
  final engine = SearchEngine.fromFile(args[0], logger);
  final regExpEmpty = RegExp(r'^\s*$');
  final regExpComment = RegExp(r'^\s*//');
  final regExpDocumentationComment = RegExp(r'^\s*///');
  // over all classes:
  while (engine.searchByRegExp(pattern: r'^class\s*(\w+)')) {
    // sets the start of the region:
    engine.currentRegion.start.clone(engine.currentPosition);
    final name = engine.lastMatch!.group(1);
    // Search backward to the start of the documenting comments (///...)
    engine.currentPosition.previousLine();
    if (!engine.skipBackwardBlockByRegExp(regExprBody: regExpDocumentationComment)){
      /// No comments found: than we must undo *.previousLine():
      engine.currentPosition.nextLine();
    }
    final start = engine.currentPosition.line;
    if (!engine.searchByRegExp(regExp: RegExp(r'^\}'), skipLastMatch: true)) {
      logger.log('syntax error: missing "}"');
      break;
    } else {
      // sets the end of the region:
      engine.currentRegion.end.clone(engine.currentPosition);
      final count = engine.currentPosition.line - start + 1;
      // set the current position to the region start
      engine.goto(engine.currentRegion.start);
      // count inside the region only:
      final comments = engine.countByRegExp(regExp: regExpComment, onePerLine: true);
      final empty = engine.countByRegExp(regExp: regExpEmpty, onePerLine: true);
      final code = count - comments - empty;
      print(
          'class $name: $count line(s), $comments comment(s), $code line(s) of code');
      // sets the current position at the end:
      engine.goto(engine.currentRegion.start);
      // expand the region to the text end
      // otherwise the search of the next class will fail
      engine.currentRegion.end.setEndOfText();
    }
  }
}
```

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: http://example.com/issues/replaceme
