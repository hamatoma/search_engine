/// Defines functions that parse dart source files for special purposes.
import 'search_engine.dart';
import 'text_engine.dart';

/// Stores a dart class.
class Class extends ParserItem {
  Class(String name, [List<String>? lines])
      : super(name, ParserItemType.aClass, lines);
}

class DartParser {
  static const prefixString = '_MulSStrInG';
  static const prefixComment = '_MulCCoMeNt';
  Searcher noMetaChar = dummySearcher;
  Searcher backslash = dummySearcher;
  final multiStrings = <String, String>{};
  final multiComments = <String, String>{};
  final SearchEngine engine;
  DartParser(this.engine) {
    noMetaChar = RegExpSearcher(engine, pattern: r'''[^\\"']+''');
    backslash = StringSearcher(engine, r'\');
  }

  /// Searches the end of a multi line comment or string.
  /// [endSearcher] defines the pattern of the searched item.
  /// [end]: OUT stores the end of the item.
  /// Returns null on success or the error message.
  String? findEndOfMultilineItem(Searcher endSearcher, Position end) {
    String? rc;
    if (!engine.search(endSearcher,
        relativePosition: RelativePosition.belowLast)) {
      final marker = (endSearcher as StringSearcher).toSearch;
      rc = 'syntax error: missing end marker $marker for item starting in $end';
    } else {
      end.clone(engine.currentPosition);
    }
    return rc;
  }

  /// Finds the end of a single line string constant.
  /// [end] specifies the string end (" or ').
  /// If [hasPrefixR] the string constant is a "raw string" that means meta chars
  /// take not place there.
  /// [endPosition]: OUT the position behind the end delimiter.
  /// Returns null on success, otherwise the error message.
  String? findEndOfString(
      StringSearcher end, bool hasPrefixR, Position endPosition) {
    int? ix;
    String? rc;
    final line = engine.lineByIndex(engine.currentPosition.line);
    var col = engine.startColumnByIndex(engine.currentPosition.line);
    col = engine.currentPosition.column > col
        ? engine.currentPosition.column
        : col;
    endPosition.clone(engine.currentPosition);
    if (hasPrefixR) {
      ix = end.next(line, col);
      if (ix == null) {
        rc = 'missing end of string (${end.toSearch}) in line: $line';
      } else {
        endPosition.column = ix + 1;
        endPosition.normalize();
      }
    } else {
      int? ix;
      while (true) {
        var found = false;
        if ((ix = noMetaChar.next(line, col)) != null && ix == col) {
          col = endPosition.column = ix! + engine.lastMatch.length();
          found = true;
        }
        if (engine.containsAt(endPosition, backslash)) {
          col = endPosition.column += 2;
          found = true;
        }
        if (engine.containsAt(endPosition, end)) {
          endPosition.column += end.toSearch.length;
          endPosition.normalize();
          break;
        }
        if (!found) {
          rc = 'missing end of string (${end.toSearch}) in line: $line';
          break;
        }
      }
    }
    return rc;
  }

  /// Replaces strings and comments by identifiers.
  /// The content of the strings and comments will be stored in two maps, so
  /// that can be restored.
  void replaceStringsAndComments() {
    engine.currentRegion.setAll();
    multiComments.clear();
    multiStrings.clear();
    final start = Position(0, 0, engine);
    final startPrefix = Position(0, 0, engine);
    final end = Position(0, 0, engine);
    final multiString1 = StringSearcher(engine, "'''");
    final multiString2 = StringSearcher(engine, '"""');
    final string1 = StringSearcher(engine, '"');
    final string2 = StringSearcher(engine, "'");
    final multiComment = StringSearcher(engine, '/*');
    final comment = StringSearcher(engine, '//');
    final commentOnly = RegExpSearcher(engine, pattern: r'^\s*//');
    final startSearcher = RegExpSearcher(engine, pattern: r'''/[*/]|["']''');
    final prefixR = StringSearcher(engine, 'r');
    while (engine.search(startSearcher,
        hitPosition: start, relativePosition: RelativePosition.belowLast)) {
      startPrefix.set(start.line, start.column == 0 ? 0 : start.column - 1);
      var isString = true;
      String? error;
      start.column--;
      final hasPrefixR = start.column >= 0 && engine.containsAt(start, prefixR);
      start.column++;
      if (engine.containsAt(start, multiString1)) {
        error = findEndOfMultilineItem(multiString1, end);
      } else if (engine.containsAt(start, multiString2)) {
        error = findEndOfMultilineItem(multiString2, end);
      } else if (engine.containsAt(start, multiComment)) {
        error = findEndOfMultilineItem(StringSearcher(engine, '*/'), end);
        isString = false;
      } else if (engine.containsAt(start, string1)) {
        error = findEndOfString(string1, hasPrefixR, end);
      } else if (engine.containsAt(start, string2)) {
        error = findEndOfString(string2, hasPrefixR, end);
      } else if (engine.containsAt(start, comment)) {
        isString = false;
        end.set(start.line + 1, 0);
        // Test whether the comment is not preceded by statement:
        if (commentOnly.next(engine.lines[start.line]) == 0) {
          // Combine all "comment only" lines:
          while (end.line < engine.lines.length &&
              commentOnly.next(engine.lines[end.line]) == 0) {
            end.line++;
          }
        }
      } else {
        error = 'unknown meta character';
        end.clone(engine.currentPosition);
        end.forward(1);
      }
      engine.currentPosition.clone(end);
      if (error != null) {
        engine.logger.error(error);
        continue;
      }
      if (hasPrefixR) {
        start.column--;
      }
      final content = engine.asString(start: start, end: end);
      final map = isString ? multiStrings : multiComments;
      final name = (isString ? prefixString : prefixComment) +
          map.length.toString() +
          '_';
      map[name] = content;
      engine.deleteFromTo(start: start, end: end);
      engine.insert(name, position: start);
      engine.currentPosition.set(0, 0);
    }
  }
}

/// Stores one import line.
class Import extends ParserItem {
  Import([List<String>? lines]) : super('', ParserItemType.anImport, lines);
}

/// Base class of the items found by the parser.
class ParserItem {
  static int lastId = 1;
  final String name;
  int id = 0;
  final ParserItemType type;
  List<String> lines = [];
  ParserItem(this.name, this.type, [List<String>? lines]) {
    id = ++lastId;
    if (lines != null) {
      this.lines = lines;
    }
  }
}

enum ParserItemType { undef, aFunction, aClass, aMethod, aVariable, anImport }

/// Some parts of the dart file can be unknown.
/// They will be stored here.
class Unknown extends ParserItem {
  Unknown([List<String>? lines]) : super('', ParserItemType.undef, lines);
}

/// Stores a class variable or a module variable.
class Variable extends ParserItem {
  Variable(String name, [List<String>? lines])
      : super(name, ParserItemType.aVariable, lines);
}
