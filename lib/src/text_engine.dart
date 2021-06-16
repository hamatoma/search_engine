/// ## Glossary:
///
/// * A **position** is a well known location in the text,
///   given by a line index (0..L-1) and a column index (0..C-1)
///
/// * A **region** is a part of the text given by a start / end position.
///   The end position of the region is outside the region (exclusive).
///
import 'package:dart_bones/dart_bones.dart';

/// We want to use null safety: So we define a TextEngine for class variable
/// initializing, that will be replaced in the constructor.
final dummyTextEngine = TextEngine([], globalLogger);

/// We want to use null safety: So we define a Region for class variable
/// initializing, that will be replaced in the constructor.
final dummyRegion = Region(start: Position(0, 0), end: Position(0, 0));

/// Stores a position in a text represented by a line index and a column index.
class Position {
  int line;
  int column;
  final TextEngine? searchEngine;

  Position(this.line, this.column, [this.searchEngine]);

  /// Adds an [offset] to the column.
  /// If the new column is behind the line end the first position in the
  /// next line is set.
  /// [offset] may be negative.
  /// Returns true, if next line is set.
  bool addColumn(int offset) {
    column += offset;
    if (column < 0) {
      column = 0;
    }
    final rc = normalize();
    return rc;
  }

  /// Moves the position [offset] characters backwards (across lines).
  /// Returns false: [offset] was too large, begin of text is reached.
  bool backward(int offset) {
    var rc = false;
    if (searchEngine != null) {
      rc = true;
      while (offset > 0) {
        if (column == 0) {
          if (--line < 0) {
            line = 0;
            rc = false;
            break;
          } else {
            column = searchEngine!.lines[line].length;
          }
        }
        if (column > 0) {
          if (offset <= column) {
            column -= offset;
            offset = 0;
          } else {
            offset -= column;
            column = 0;
          }
        }
      }
    }
    return rc;
  }

  /// Takes the data from another Position instance.
  void clone(Position source) {
    line = source.line;
    column = source.column;
  }

  /// Positions to the end of [lines].
  void endOfText() {
    if (searchEngine != null) {
      line = searchEngine!.lines.length;
      column = 0;
    }
  }

  /// Moves the position [offset] characters forward (across lines).
  /// Returns false: [offset] was too large, end of text is reached
  bool forward(int offset) {
    var rc = false;
    if (searchEngine != null) {
      final countLines = searchEngine!.lines.length;
      rc = true;
      int eol;
      while (offset > 0) {
        final lastColumn = column;
        column += offset;
        if (column < (eol = searchEngine!.lines[line].length)) {
          offset = 0;
        } else {
          offset -= eol - lastColumn;
          column = 0;
          if (++line >= countLines) {
            rc = offset == 0;
            line = searchEngine!.lines.length;
            break;
          }
        }
      }
    }
    return rc;
  }

  /// Returns whether the instance is above ("lower than") the [reference].
  /// If [orEquals] is true and the positions are equal true will be returned.
  bool isAbove(Position reference, {bool orEqual = false}) {
    var rc = orEqual && reference.line == line && reference.column == column;
    if (!rc) {
      rc = line < reference.line ||
          reference.line == line && column < reference.column;
    }
    return rc;
  }

  /// Returns whether the instance is below ("greater than") the [reference].
  /// If [orEquals] is true and the positions are equal true will be returned.
  bool isBelow(Position reference, {bool orEqual = false}) {
    var rc = orEqual && reference.line == line && reference.column == column;
    if (!rc) {
      rc = line > reference.line ||
          reference.line == line && column > reference.column;
    }
    return rc;
  }

  /// Tests whether a given [position] points to the end of text.
  /// Return true: [position] is end of text.
  bool isEndOfText() {
    final rc =
        searchEngine == null ? false : line >= searchEngine!.lines.length;
    return rc;
  }

  /// Moves the position to the start of the next line, [count] times.
  /// If starting from the end of text position remains.
  /// Returns true if position is not as required (end of text reached).
  bool nextLine([int count = 1]) {
    var rc = false;
    if (searchEngine == null) {
      line += count;
      column = 0;
    } else {
      column = 0;
      if ((line += count) >= searchEngine!.lines.length) {
        rc = line > searchEngine!.lines.length;
        if (rc) {
          line = searchEngine!.lines.length;
        }
      }
    }
    return rc;
  }

  /// Normalizes "end of line":
  ///
  /// If the column >= line length, the first position in the next line is set.
  /// If line > lines.length than line = lines.length and column = 0.
  /// Returns true if position is corrected.
  bool normalize() {
    var rc = false;
    if (searchEngine != null) {
      if (line >= searchEngine!.lines.length) {
        line = searchEngine!.lines.length;
        rc = true;
        column = 0;
      } else if (column > 0 && column >= searchEngine!.lines[line].length) {
        line++;
        column = 0;
        rc = true;
      }
    }
    return rc;
  }

  /// Moves the position to the begin of the previous line [count] times.
  /// Returns true if position is not as required (begin of text reached).
  bool previousLine([int count = 1]) {
    var rc = false;
    if ((line -= count) < 0) {
      line = 0;
      rc = true;
    }
    column = 0;
    return rc;
  }

  /// Sets the [line] and the [column].
  /// [lines]: if not null the line length is the limit.
  void set(int line, int column) {
    this.line = line;
    this.column = column;
    normalize();
  }

  /// Sets the instance at the first position behind the text given as line list.
  void setEndOfText() {
    if (searchEngine != null) {
      line = searchEngine!.lines.length;
      column = 0;
    }
  }

  @override
  String toString() {
    final rc = 'line $line column $column';
    return rc;
  }
}

/// Manages a part of the text defined by a start and end position.
class Region {
  final Position start;
  final Position end;
  TextEngine? searchEngine;
  Region({required this.start, required this.end}) {
    searchEngine = start.searchEngine;
  }

  /// Set the data from the [source].
  void clone(Region source) {
    start.clone(source.start);
    end.clone(source.end);
  }

  /// Returns true if [position] is inside the region described by the instance.
  bool contains(Position position) {
    final rc = position.isBelow(start, orEqual: true) && position.isAbove(end);
    return rc;
  }

  /// Sets the region to the full text.
  void setAll() {
    start.set(0, 0);
    end.setEndOfText();
  }

  @override
  String toString() {
    final rc = 'start: $start end: $end';
    return rc;
  }
}

enum RelativePosition { aboveFirst, onFirst, onLast, belowLast }

/// Offers services in a text represented as list of lines like insert/delete
/// text or text lines.
class TextEngine {
  List<String> lines = [];
  Position currentPosition = Position(0, 0);
  Region currentRegion = dummyRegion;
  Position tempPosition = Position(0, 0);

  BaseLogger logger = globalLogger;

  /// The basic constructor defined by a text given as [lines].
  TextEngine(this.lines, this.logger) {
    currentPosition = Position(0, 0, this);
    tempPosition = Position(0, 0, this);
    currentRegion = Region(
        start: Position(0, 0, this), end: Position(lines.length, 0, this));
  }

  /// This constructor defines the text given as single string.
  TextEngine.fromString(String text, BaseLogger logger)
      : this(text.split('\n'), logger);

  /// Returns the text between two positions as a string list.
  /// [start] ist the position to start.
  /// [end] is the the end of the wanted text.
  /// if [isInclusive] is true [end] is part of the returned text.
  List<String> asList(
      {required Position start,
      required Position end,
      bool isInclusive = false,
      List<String>? list}) {
    list ??= [];
    list.clear();
    if (start.isAbove(end, orEqual: isInclusive)) {
      if (start.line == end.line) {
        list.add(lines[start.line]
            .substring(start.column, end.column + (isInclusive ? 1 : 0)));
      } else {
        // first line may be a part:
        list.add(start.column == 0
            ? lines[start.line]
            : lines[start.line].substring(start.column));
        for (var ix = start.line + 1; ix < end.line; ix++) {
          list.add(lines[ix]);
        }
        // last line may be a part:
        if (end.column == 0) {
          if (isInclusive) {
            list.add('');
          }
        } else {
          list.add(
              lines[end.line].substring(0, end.column + (isInclusive ? 1 : 0)));
        }
      }
    }
    return list;
  }

  /// Returns the text between two positions as a string.
  /// [start] ist the position to start.
  /// [end] is the the end of the wanted text.
  /// if [isInclusive] is true [end] is part of the returned text.
  String asString(
      {required Position start,
      required Position end,
      bool isInclusive = false}) {
    final list = asList(start: start, end: end, isInclusive: isInclusive);
    return list.join('\n');
  }

  /// Deletes the text between the positions [start] and [end].
  /// If [start] is null the current position is taken.
  void deleteFromTo({Position? start, required Position end}) {
    start ??= currentPosition;
    if (start.isBelow(end)) {
      Position temp;
      temp = start;
      start = end;
      end = temp;
    }
    if (start.line == end.line) {
      lines[start.line] = lines[start.line].substring(0, start.column) +
          lines[start.line].substring(end.column);
    } else {
      var ixStart = start.line;
      var ixEnd = end.line + 1;
      if (start.column > 0) {
        lines[start.line] = lines[start.line].substring(0, start.column);
        ixStart++;
      }
      if (end.column > 0) {
        lines[end.line] = lines[end.line].substring(end.column);
        ixEnd--;
      }
      if (ixStart < ixEnd) {
        lines.removeRange(ixStart, ixEnd);
      }
    }
    if (currentRegion.end.line > lines.length) {
      currentRegion.end.set(lines.length, 0);
    }
  }

  void deleteLines({Position? start, int? countLines}) {}

  /// Sets the current position to [position].
  void goto(Position position) {
    currentPosition.clone(position);
  }

  /// Inserts a string at a given [position].
  /// If [position] is null the [currentPosition] is taken.
  void insert(String text, {Position? position}) {
    if (text.contains('\n')) {
      insertLines(text.split('\n'), position: position);
    } else {
      position ??= currentPosition;
      if (position.line >= lines.length) {
        lines.add(text);
      } else {
        if (position.column == 0) {
          lines[position.line] = text + lines[position.line];
        } else {
          final head = lines[position.line].substring(0, position.column);
          final tail = lines[position.line].substring(position.column);
          lines[position.line] = head + text + tail;
        }
      }
    }
  }

  /// Inserts a string list at a given [position].
  /// If [position] is null the [currentPosition] is taken.
  void insertLines(List<String> textLines, {Position? position}) {
    position ??= currentPosition;
    if (position.line >= textLines.length) {
      lines += textLines;
    } else if (position.column == 0) {
      lines.insertAll(position.line, textLines);
    } else {
      final restLine = lines[position.line].substring(position.column);
      lines[position.line] =
          lines[position.line].substring(0, position.column) + textLines[0];
      lines.insert(position.line + 1, restLine);
      lines.insertAll(position.line + 1, textLines.sublist(1));
    }
  }

  /// Returns a line given by its index. May be a part of the stored line
  /// if the [currentRegion] requires that.
  String lineByIndex(int ix) {
    var line = lines[ix];
    if (ix == currentRegion.start.line) {
      if (ix == currentRegion.end.line && currentRegion.end.column != 0) {
        line = line.substring(0, currentRegion.end.column);
      }
    } else if (ix == currentRegion.end.line && currentRegion.end.column != 0) {
      line = line.substring(0, currentRegion.end.column);
    }
    return line;
  }

  /// Returns the start column of a line given by its index depending on the
  /// [currentRegion].
  int startColumnByIndex(int ix) {
    final rc = ix == currentRegion.start.line ? currentRegion.start.column : 0;
    return rc;
  }
}
