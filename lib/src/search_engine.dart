/// ## Glossary:
///
/// * A **block** is a lot of consecutive lines described by some "block entries".
///   * a block entry type: line, sequence, notSequence or startEndSequence
///     * line is a single line
///     * sequence is a sequence of lines matching one rule
///     * notSequence is a sequence of lines not matching one rule
///     * startEndSequence is a sequence matching a start line rule, any lines
///       between and ending with a line matching a end line rule. Both rules
///       may describe the same (single) line.
///   * a pattern of the entry described by a searcher
///   * each entry can be specified as optional
/// Example: Describes a block containing a class including the optional
/// preceding comment:
/// final blockClass = Block([
///   BlockEntry(BlockEntryType.sequence, RegExpSearcher(engine, r'^///', optional: true)),
///   BlockEntry(BlockEntryType.startEndSequence, RegExpSearcher(engine, r'^class'),
///     endSearcher: RegExpSearcher(engine, r'^\}')),
///   ]);
import 'package:dart_bones/dart_bones.dart';

import 'text_engine.dart';

const int int52MaxValue = 4503599627370496; // 2**52 (JavaScript "max-integer")
final dummyBlock = Block([]);
final dummySearchEngine = SearchEngine([], globalLogger);
final dummySearcher = StringSearcher(dummySearchEngine, '?');

class Block {
  static int _lastId = 0;

  /// if true at least one line of body is needed.
  List<BlockEntry> entries = [];
  List<BlockEntry> reverseEntries = [];
  String? name;
  int id = 0;
  Block(List<BlockEntry> entries, {this.name}) {
    id = _lastId++;
    this.entries = entries;
    reverseEntries = entries.reversed.toList(growable: false);
  }
}

class BlockEntry {
  final BlockEntryType entryType;
  final Searcher searcher;

  /// Only needed for a "start stop sequence":
  final Searcher? searcherEnd;
  final bool optional;
  BlockEntry(this.entryType, this.searcher,
      {this.searcherEnd, this.optional = false}) {
    assert(entryType != BlockEntryType.startEndSequence || searcherEnd != null);
  }

  /// Count the matching lines of the instance.
  /// [ixLine] is the index of the first line to inspect.
  /// [step]: +1 or -1: signals forward or backward searching.
  /// [ixStop] is the the first "forbidden" index: reaching this index the
  /// search stops.
  /// Returns the number of lines belonging to the sequence.
  int countMatchingLines(int ixLine, int step, int ixStop) {
    var rc = 0;
    switch (entryType) {
      case BlockEntryType.line:
        rc = 1;
        break;
      case BlockEntryType.sequence:
      case BlockEntryType.notSequence:
        rc = 1;
        while ((ixLine += step) != ixStop) {
          if (!match(searcher.searchEngine.lineByIndex(ixLine),
              searcher.searchEngine.startColumnByIndex(ixLine))) {
            break;
          }
          rc++;
        }
        break;
      case BlockEntryType.startEndSequence:
        if (step > 0) {
          rc = handleStartEndSequenceForward(ixLine, ixStop);
        } else {
          rc = handleStartEndSequenceBackward(ixLine, ixStop);
        }
        break;
    }
    return rc;
  }

  /// Handles a start stop sequence if the first (or last) line is matching.
  /// [ixLine] is the index of the first line to inspect.
  /// [step]: +1 or -1: signals forward or backward searching.
  /// [ixStop] is the the first "forbidden" index: reaching this index the
  /// search stops.
  /// Returns the number of lines belonging to the sequence.
  int handleStartEndSequenceBackward(int ixLine, int ixStop) {
    var rc = 1;
    while (ixLine != ixStop &&
        searcher.next(searcher.searchEngine.lineByIndex(ixLine),
                searcher.searchEngine.startColumnByIndex(ixLine)) ==
            null) {
      rc++;
      ixLine--;
    }
    return rc;
  }

  /// Handles a start stop sequence if the first (or last) line is matching.
  /// [ixLine] is the index of the first line to inspect.
  /// [step]: +1 or -1: signals forward or backward searching.
  /// [ixStop] is the the first "forbidden" index: reaching this index the
  /// search stops.
  /// Returns the number of lines belonging to the sequence.
  int handleStartEndSequenceForward(int ixLine, int ixStop) {
    var rc = 1;
    while (ixLine != ixStop &&
        searcherEnd!.next(searcherEnd!.searchEngine.lineByIndex(ixLine),
                searcherEnd!.searchEngine.startColumnByIndex(ixLine)) ==
            null) {
      rc++;
      ixLine++;
    }
    return rc;
  }

  /// Tests whether the block entry matches the [line] starting with [startColumn].
  /// true: the line matches.
  bool match(String line, int startColumn, {bool isFirstLine = true}) {
    var rc;
    switch (entryType) {
      case BlockEntryType.line:
        rc = searcher.next(line, startColumn) != null;
        break;
      case BlockEntryType.sequence:
        rc = searcher.next(line, startColumn) != null;
        break;
      case BlockEntryType.notSequence:
        rc = searcher.next(line, startColumn) == null;
        break;
      case BlockEntryType.startEndSequence:
        if (isFirstLine) {
          rc = searcher.next(line, startColumn) != null;
        } else {
          rc = searcherEnd?.next(line, startColumn) != null;
        }
        break;
    }
    return rc;
  }
}

enum BlockEntryType { line, sequence, notSequence, startEndSequence }

/// Stores the properties of the  last match done by search().
class LastMatch {
  var type = LastMatchType.undef;
  RegExpMatch? regExpMatch;
  String? stringMatch;
  Position position = Position(-1, 0);
  String? group(int no) {
    String? rc;
    switch (type) {
      case LastMatchType.undef:
        break;
      case LastMatchType.regularExpr:
        rc = regExpMatch!.group(no);
        break;
      case LastMatchType.string:
        if (no == 0) {
          rc = stringMatch;
        }
        break;
    }
    return rc;
  }

  /// Returns the length of the last match.
  int length() {
    var rc = 0;
    switch (type) {
      case LastMatchType.undef:
        break;
      case LastMatchType.regularExpr:
        rc = regExpMatch!.group(0)!.length;
        break;
      case LastMatchType.string:
        rc = stringMatch!.length;
        break;
    }
    return rc;
  }

  int groupCount() {
    var rc = 0;
    switch (type) {
      case LastMatchType.undef:
        break;
      case LastMatchType.regularExpr:
        rc = regExpMatch!.groupCount;
        break;
      case LastMatchType.string:
        break;
    }
    return rc;
  }
}

enum LastMatchType { undef, regularExpr, string }

class RegExpSearcher extends SearcherGroupHandler implements Searcher {
  RegExp regExp = RegExp('^');
  RegExpSearcher(SearchEngine searchEngine,
      {String? pattern, bool caseSensitive = false, RegExp? regExp})
      : super(searchEngine) {
    assert(pattern != null || regExp != null);
    if (pattern != null) {
      this.regExp = RegExp(pattern, caseSensitive: caseSensitive);
    } else {
      this.regExp = regExp!;
    }
  }

  @override
  int? next(String line, [int start = 0]) {
    final line2 = start == 0 ? line : line.substring(start);
    searchEngine.lastMatch.type = LastMatchType.regularExpr;
    searchEngine.lastMatch.regExpMatch = regExp.firstMatch(line2);
    final rc = searchEngine.lastMatch.regExpMatch == null
        ? null
        : start + searchEngine.lastMatch.regExpMatch!.start;
    searchEngine.lastMatch.position.column = rc ?? -1;
    return rc;
  }

  @override
  int? previous(String line, [int? start]) {
    final it = regExp.allMatches(line);
    RegExpMatch? lastMatch;
    if (it.isNotEmpty) {
      if (start == null) {
        lastMatch = it.last;
      } else {
        final bound = start + 1;
        for (var match in it) {
          if (match.end <= bound) {
            lastMatch = match;
          }
        }
      }
    }
    searchEngine.lastMatch.type = LastMatchType.regularExpr;
    searchEngine.lastMatch.regExpMatch = lastMatch;
    searchEngine.lastMatch.position.column = lastMatch?.start ?? -1;
    return lastMatch?.start;
  }
}

/// Offers search and replace services in a text represented as list of lines.
/// The service is only executed within in a region named [currentRegion].
/// Note: currentRegion can include the whole text (but does not have to be).
/// The service starts at the [currentPosition].
class SearchEngine extends TextEngine {
  /// the last hit found by a RegExpSearcher instance:
  LastMatch lastMatch = LastMatch();

  /// The basic constructor defined by a text given as [lines].
  SearchEngine(List<String> lines, BaseLogger logger) : super(lines, logger);

  /// This constructor defines the text given as single string.
  SearchEngine.fromString(String text, BaseLogger logger)
      : this(text.split('\n'), logger);

  /// Tests whether a given pattern matches the given [position].
  /// [searcher] defines the pattern.
  /// Returns true if the [searcher] is found at [position]
  bool containsAt(Position position, Searcher searcher) {
    final ix = searcher.next(lines[position.line], position.column);
    return ix == position.column;
  }

  /// Count the hits of a pattern from the current position to the
  /// region end.
  /// [searcher] specifies the kind of search: regular expression, raw string...
  /// If [regExp] is not null this expression is searched.
  /// If [pattern] is not null this string converted to a regular expression.
  /// [maximalHitsPerLine]: if this count of hits is reached search is continued
  /// in the next line.
  /// [maximalHits]: if this count is reached the search stops.
  /// Returns the number of hits.
  int count(Searcher searcher,
      {int maximalHitsPerLine = 1,
      int? maximalHits,
      bool saveCurrentPosition = true}) {
    var rc = 0;
    var skipLast = false;
    Position? position;
    if (maximalHitsPerLine <= 0) {
      maximalHitsPerLine = int52MaxValue;
    }
    if (saveCurrentPosition) {
      position = Position(0, 0, this);
      position.clone(currentPosition);
    }
    var lastLine = currentPosition.line - 1;
    var hitsInLine = 0;
    while (search(searcher, skipLastMatch: skipLast)) {
      skipLast = true;
      if (++rc >= (maximalHits ?? int52MaxValue)) {
        break;
      }
      if (currentPosition.line != lastLine) {
        hitsInLine = 1;
        lastLine = currentPosition.line;
      } else {
        hitsInLine++;
      }
      if (hitsInLine >= maximalHitsPerLine) {
        currentPosition.nextLine();
        skipLast = false;
      }
    }
    if (saveCurrentPosition) {
      currentPosition.clone(position!);
    }
    return rc;
  }

  /// Searches the end of the block starting at the current position.
  /// [block]: specifies the block parameters: start, end, body.
  /// [blockEnd]: The end of the block is stored here. If null [currentPosition]
  /// is taken.
  /// [startPosition]: defines the start of the search. If null [currentPosition]
  /// is taken.
  /// Returns true: the block has been found.
  bool findBlockEnd(Block block,
      {Position? blockEnd, Position? startPosition}) {
    var rc = false;
    tempPosition.clone(startPosition ?? currentPosition);
    if (currentRegion.contains(tempPosition)) {
      final ixStop = currentRegion.end.column > 0
          ? currentRegion.end.line + 1
          : currentRegion.end.line;
      rc = traverseBlock(block.entries, tempPosition.line, 1, ixStop,
          blockEnd ?? currentPosition);
    }
    return rc;
  }

  /// Searches (backwards) the start of the block starting at a given position.
  /// [block]: specifies the block parameters: start, end, body.
  /// The start of the block is stored in [startOfBlock]. If null [currentPosition]
  /// is taken.
  /// [startPosition]: defines the start of the search.
  /// [offsetBackward]: before starting the start position is moved this offset
  /// in direction of text start.
  /// Returns true: the block has been found.
  bool findBlockStart(Block block,
      {Position? startOfBlock,
      Position? startPosition,
      int offsetBackward = 0}) {
    tempPosition.clone(startPosition ?? currentPosition);
    if (offsetBackward != 0) {
      tempPosition.backward(offsetBackward);
    }
    var rc = false;
    if (currentRegion.contains(tempPosition)) {
      tempPosition.clone(startPosition ?? currentPosition);
      if (currentRegion.contains(tempPosition)) {
        rc = traverseBlock(block.reverseEntries, tempPosition.line, -1,
            currentRegion.start.line - 1, startPosition ?? currentPosition);
      }
    }
    return rc;
  }

  /// Searches the next block from a given [position].
  /// [blockList] is a list of alternative block descriptions.
  /// The search starts at [position]. If null the [currentPosition] is used.
  /// [blockStart]: OUT: if not null, the start of the found block is stored here.
  /// [blockEnd]: OUT: if not null, the end of the found block is stored here.
  /// [endPosition]: OUT: the block end is copied here. If null [currentPosition]
  /// is taken.
  /// Returns null if search has failed otherwise the block found.
  /// Note: the [Block] contains an optional name or an intrinsic id to distinct
  /// them from other.
  Block? nextBlockFromList(List<Block> blockList,
      {Position? position,
      Position? blockStart,
      Position? blockEnd,
      Position? endPosition}) {
    position ??= currentPosition;
    final cursor = Position(0, 0, this);
    endPosition ??= currentPosition;
    blockStart ??= Position(0, 0, this);
    blockEnd ??= Position(0, 0, this);
    Block? rc;
    var ixLine = position.line;
    final stopLine = currentRegion.end.line;
    while (rc == null && ixLine < stopLine) {
      for (var block in blockList) {
        cursor.set(ixLine, startColumnByIndex(ixLine));
        if (findBlockEnd(block, startPosition: cursor, blockEnd: blockEnd)) {
          rc = block;
          blockStart.clone(cursor);
          endPosition.clone(blockEnd);
          break;
        }
      }
      ixLine++;
    }
    return rc;
  }

  /// Searches a pattern from a given position.
  /// [searcher] specifies the kind of pattern: regular expression, raw string...
  /// [startPosition] defines the position to start. If null the [currentPosition]
  /// is taken.
  /// [hitPosition]: OUT: the position of the hit. If result is false the value
  /// is not changed. If null the [currentPosition] is used.
  /// [relativePosition] defines the result position relative to the found pattern.
  /// [skipLastMatch]: if true the current position is moved below the last
  /// found match before the search is started. This is only meaningful if there
  /// was a previous call of [search] and the [relativePosition] of the previous
  /// call was [RelativePosition.onFirst]. This parameter makes it easy to find
  /// the same pattern multiple times.
  /// Note: [currentPosition] is always set, depending on [relativePosition].
  /// Returns true if the pattern is found.
  bool search(
    Searcher searcher, {
    bool skipLastMatch = false,
    Position? hitPosition,
    Position? startPosition,
    RelativePosition relativePosition = RelativePosition.onFirst,
  }) {
    var rc = false;
    startPosition ??= currentPosition;
    if (currentRegion.contains(startPosition)) {
      int? start;
      currentPosition.clone(startPosition);
      if (skipLastMatch) {
        currentPosition.addColumn(lastMatch.length());
      }

      /// Is the region exactly one line?
      if (currentPosition.line == currentRegion.end.line &&
          currentPosition.column > 0 &&
          currentRegion.end.line > 0) {
        final line = lines[currentPosition.line]
            .substring(currentPosition.column, currentRegion.end.column);
        lastMatch.position.line = currentPosition.line;
        rc = (start = searcher.next(line)) != null;
        if (rc) {
          currentPosition.addColumn(start!);
        }
      } else {
        var firstColumn = currentPosition.column;
        final lastFullLine = currentRegion.end.line - 1;
        var currentLine = currentPosition.line;
        while (currentLine <= lastFullLine) {
          lastMatch.position.line = currentLine;
          rc = (start = searcher.next(lines[currentLine], firstColumn)) != null;
          if (rc) {
            currentPosition.set(currentLine, start!);
            break;
          }
          firstColumn = 0;
          currentLine++;
        }
        if (!rc && currentRegion.end.column != 0) {
          rc = (start = searcher.next(lines[currentRegion.end.line]
                  .substring(0, currentRegion.end.column))) !=
              null;
          if (rc) {
            currentPosition.set(currentRegion.end.line, start!);
          }
        }
      }
      if (rc) {
        hitPosition ??= currentPosition;
        hitPosition.clone(currentPosition);
        switch (relativePosition) {
          case RelativePosition.aboveFirst:
            currentPosition.backward(1);
            break;
          case RelativePosition.onFirst:
            break;
          case RelativePosition.onLast:
            currentPosition.addColumn(lastMatch.length() - 1);
            break;
          case RelativePosition.belowLast:
            currentPosition.addColumn(lastMatch.length());
            break;
        }
      }
    }
    return rc;
  }

  /// Searches a pattern from a given position in reverse direction.
  /// [startPosition] defines the start. If null the [currentPosition] is taken.
  /// [offsetBackward]: the start position is moved this count of characters
  /// in direction to the text start before searching. This is meaningful if
  /// the start position is the region end: Otherwise nothing will be found.
  /// [searcher] specifies the kind of pattern: regular expression, raw string...
  /// [hitPosition]: OUT: the position of the hit. If result is false the value
  /// is not changed. If null the [currentPosition] is used.
  /// [relativePosition] defines the result position relative to the found pattern.
  /// Returns true if the pattern is found.
  bool searchReverse(
    Searcher searcher, {
    Position? startPosition,
    int offsetBackward = 0,
    Position? hitPosition,
    RelativePosition relativePosition = RelativePosition.onFirst,
  }) {
    var rc = false;
    tempPosition.clone(startPosition ??= currentPosition);
    if (offsetBackward != 0) {
      tempPosition.backward(offsetBackward);
    }
    if (currentRegion.contains(tempPosition)) {
      int? start;

      /// Is the region exactly one line?
      if (tempPosition.line == currentRegion.start.line) {
        final line = lines[tempPosition.line]
            .substring(currentRegion.start.column, tempPosition.column);
        lastMatch.position.line = currentPosition.line;
        rc = (start = searcher.previous(line)) != null;
        if (rc) {
          tempPosition.addColumn(-start! - lastMatch.length());
        }
      } else {
        var currentLine = tempPosition.line;
        // special handling of the first line: respect the column in previous():
        if (tempPosition.column > 0) {
          rc = (start =
                  searcher.previous(lines[currentLine], tempPosition.column)) !=
              null;
          if (rc) {
            tempPosition.column = start!;
          } else {
            currentLine--;
          }
        }
        if (!rc) {
          final lastLine = currentRegion.start.line +
              (currentRegion.start.column > 0 ? 1 : 0);
          // inspect the full lines:
          while (currentLine >= lastLine) {
            lastMatch.position.line = currentLine;
            rc = (start = searcher.previous(lines[currentLine])) != null;
            if (rc) {
              tempPosition.set(currentLine, start!);
              break;
            }
            currentLine--;
          }
          // special handling of the last line (if incomplete):
          if (!rc &&
              currentLine == currentRegion.start.line &&
              currentRegion.start.column > 0) {
            final line =
                lines[currentLine].substring(currentRegion.start.column);
            rc = (start = searcher.previous(line)) != null;
            if (rc) {
              tempPosition.set(
                  currentLine, currentRegion.start.column + start!);
            }
          }
        }
      }
      if (rc) {
        switch (relativePosition) {
          case RelativePosition.aboveFirst:
            tempPosition.backward(1);
            break;
          case RelativePosition.onFirst:
            break;
          case RelativePosition.onLast:
            tempPosition.addColumn(lastMatch.length() - 1);
            break;
          case RelativePosition.belowLast:
            tempPosition.addColumn(lastMatch.length());
            break;
        }
        hitPosition ??= currentPosition;
        hitPosition.clone(tempPosition);
      }
    }
    return rc;
  }

  /// Tests whether the [entries] matches to the lines at a given start position.
  /// Note: this method handles both directions, controlled by [entries],
  /// [ixStart], [step] and [ixStop].
  /// [entries]: the description of the block in the needed order.
  /// [ixStart]: the first index of [lines] to inspect.
  /// [step]: the offset to get the next line: +1 or -1
  /// [ixStop]: the first index of [lines] that should not be inspected
  /// [endPosition]: if the block is found, the end position will be stored here.
  /// If [step] is 1 the end position is end of the block, if [step] is -1
  /// the start of block is meant.
  /// Returns true, if the entries match the lines at the current position.
  bool traverseBlock(List<BlockEntry> entries, int ixStart, int step,
      int ixStop, Position endPosition) {
    var rc = true;
    var ixEntry = 0;
    var ixLine = ixStart;
    while (rc && ixLine != ixStop) {
      var startColumn = startColumnByIndex(ixLine);
      var line = lineByIndex(ixLine);
      var rc2 = true;
      // Search for the next non optional entry or the first matching optional
      // entry:
      while (ixEntry < entries.length) {
        rc2 = entries[ixEntry].match(line, startColumn);
        if (!rc2) {
          if (!entries[ixEntry].optional) {
            rc = false;
            break;
          } else {
            ixEntry++;
          }
        } else {
          final count =
              entries[ixEntry].countMatchingLines(ixLine, step, ixStop);
          if (count == 0) {
            if (!entries[ixEntry].optional) {
              rc = false;
              break;
            }
          } else {
            ixEntry++;
            ixLine += step * count;
          }
          break;
        }
      }
      if (ixEntry >= entries.length) {
        break;
      }
    }
    if (rc) {
      endPosition.set(ixLine - (step < 0 ? step : 0), 0);
    }
    return rc;
  }
}

class SearcherGroupHandler {
  final SearchEngine searchEngine;
  SearcherGroupHandler(this.searchEngine);

  /// Returns the group with [groupNo] of the last hit.
  /// If [groupNo] is 0 the full match is returned.
  /// Returns null if this group does not exist, the group otherwise.
  String? group(int groupNo) {
    return searchEngine.lastMatch.group(groupNo);
  }

  /// Returns the number of groups of the last hit.
  int groups() {
    return searchEngine.lastMatch.groupCount();
  }

  /// Returns the column of the last hit found by this instance.
  int? hitStart() {
    return searchEngine.lastMatch.position.column;
  }
}

abstract class Searcher {
  SearchEngine get searchEngine;

  /// Returns the group with [groupNo] of the last hit.
  /// If [groupNo] is 0 the full match is returned.
  /// Returns null if this group does not exist, the group otherwise.
  String? group(int groupNo);

  /// Returns the number of groups of the last hit.
  int groups();

  /// Returns the column of the last hit found by this instance.
  int? hitStart();

  /// Looks for the next current pattern.
  /// The search starts at index [start] in [line].
  /// Returns null if not found or the index of the hit.
  int? next(String line, [int start = 0]);

  /// Looks for the previous current pattern.
  /// [start]: If null the whole line is inspected. Otherwise the search
  /// starts at this index
  /// Returns null if not found or the index of the hit.
  int? previous(String line, [int? start]);
}

/// Searcher for a simple string, case insensitive.
class StringInsensitiveSearcher extends RegExpSearcher {
  StringInsensitiveSearcher(SearchEngine engine, String toSearch)
      : super(engine,
            regExp: RegExp(RegExp.escape(toSearch), caseSensitive: false));
}

/// Searcher for a simple string.
class StringSearcher extends SearcherGroupHandler implements Searcher {
  String toSearch;
  StringSearcher(SearchEngine searchEngine, this.toSearch)
      : super(searchEngine);

  @override
  String? group(int groupNo) {
    final rc = groupNo == 0 ? searchEngine.lastMatch.stringMatch : null;
    return rc;
  }

  @override
  int groups() {
    /// This class does not support groups.
    return 0;
  }

  @override
  int? hitStart() {
    return searchEngine.lastMatch.position.column;
  }

  @override
  int? next(String line, [int start = 0]) {
    final rc = line.indexOf(toSearch, start);
    searchEngine.lastMatch.type = LastMatchType.string;
    searchEngine.lastMatch.stringMatch = rc < 0 ? null : toSearch;
    searchEngine.lastMatch.position.column = rc;
    return rc < 0 ? null : rc;
  }

  @override
  int? previous(String line, [int? start]) {
    final rc = line.lastIndexOf(toSearch, start);
    searchEngine.lastMatch.type = LastMatchType.string;
    searchEngine.lastMatch.stringMatch = rc < 0 ? null : toSearch;
    searchEngine.lastMatch.position.column = rc;
    return rc < 0 ? null : rc;
  }
}
