import 'package:dart_bones/dart_bones.dart';
import 'package:search_engine/src/text_engine.dart';
import 'package:search_engine/src/search_engine.dart';
import 'package:test/test.dart';

void main() {
  final logger = MemoryLogger(LEVEL_FINE);
  final lines = r'''abcd
> ab 12
> ab 345
456
'''
      .split('\n');
  final engine = SearchEngine(lines, logger);
  final position = Position(0, 0, engine);
  group('RegExpSearcher', () {
    final searcher = RegExpSearcher(engine, pattern: r'\d');
    test('next', () {
      // ...........0123456789
      final line = 'a12 b3 c4x';
      expect(searcher.next(line, 0), 1);
      expect(searcher.next(line, 2), 2);
      expect(searcher.next(line, 3), 5);
      expect(searcher.next(line, 6), 8);
      expect(searcher.next(line, 9), isNull);
    });
    test('previous', () {
      // ...........012345678
      final line = 'a12 b3 c4x';
      expect(searcher.previous(line, 9), 8);
      expect(searcher.previous(line, 7), 5);
      expect(searcher.previous(line, 4), 2);
      expect(searcher.previous(line, 1), 1);
      expect(searcher.previous(line, 0), isNull);
    });
  });
  group('StringSearcher', () {
    final searcher = StringSearcher(engine, '.');
    test('next', () {
      // ...........0123456789
      final line = 'a.. b. c.x';
      expect(searcher.next(line, 0), 1);
      expect(searcher.next(line, 2), 2);
      expect(searcher.next(line, 3), 5);
      expect(searcher.next(line, 6), 8);
      expect(searcher.next(line, 9), isNull);
    });
    test('previous', () {
      // ...........012345678
      final line = 'a.. b. c.x';
      ;
      expect(searcher.previous(line, 9), 8);
      expect(searcher.previous(line, 7), 5);
      expect(searcher.previous(line, 4), 2);
      expect(searcher.previous(line, 1), 1);
      expect(searcher.previous(line, 0), isNull);
    });
  });
  group('StringInsensitiveSearcher', () {
    final searcher = StringInsensitiveSearcher(engine, 'y');
    test('next', () {
      // ...........0123456789
      final line = 'aYY bY cYx';
      expect(searcher.next(line, 0), 1);
      expect(searcher.next(line, 2), 2);
      expect(searcher.next(line, 3), 5);
      expect(searcher.next(line, 6), 8);
      expect(searcher.next(line, 9), isNull);
    });
    test('previous', () {
      // ...........012345678
      final line = 'aYY bY cYx';
      ;
      expect(searcher.previous(line, 9), 8);
      expect(searcher.previous(line, 7), 5);
      expect(searcher.previous(line, 4), 2);
      expect(searcher.previous(line, 1), 1);
      expect(searcher.previous(line, 0), isNull);
    });
    test('regular expression meta characters', () {
      final metaChars = r'\n\t[]{}|()';
      final searcher2 = StringInsensitiveSearcher(engine, metaChars);
      // ...........0123456789
      final line = 'a$metaChars ';
      expect(searcher2.next(line, 0), 1);
    });
  });
  group('BlockEntry-startEndSequence', () {
    resetEngine(engine);
    test('countMatchingLines-2 lines', () {
      final entry = BlockEntry(
          BlockEntryType.startEndSequence, StringSearcher(engine, 'abc'),
          searcherEnd: StringSearcher(engine, '12'));
      expect(entry.match(engine.lines[0], 0, isFirstLine: true), isTrue);
      expect(entry.match(engine.lines[1], 0, isFirstLine: false), isTrue);
      expect(entry.countMatchingLines(0, 1, 4), 2);
      expect(entry.countMatchingLines(1, -1, -1), 2);
    });
    test('countMatchingLines-1 line', () {
      final entry = BlockEntry(
          BlockEntryType.startEndSequence, StringSearcher(engine, 'ab'),
          searcherEnd: StringSearcher(engine, 'bc'));
      expect(entry.match(engine.lines[0], 0, isFirstLine: true), isTrue);
      expect(entry.match(engine.lines[0], 0, isFirstLine: false), isTrue);
      expect(entry.countMatchingLines(0, 1, 4), 1);
      expect(entry.countMatchingLines(0, -1, -1), 1);
    });
  });
  group('SearchEngine-search raw string', () {
    test('complete text', () {
      engine.currentPosition.set(0, 0);
      expect(
          engine.search(StringSearcher(engine, 'a'),
              hitPosition: engine.currentPosition),
          isTrue);
      expect(engine.currentPosition.line, 0);
      expect(engine.currentPosition.column, 0);
    });
    test('restricted by first line', () {
      engine.currentPosition.set(0, 0);
      expect(
          engine.search(StringSearcher(engine, 'b'),
              hitPosition: engine.currentPosition),
          isTrue);
      expect(engine.currentPosition.line, 0);
      expect(engine.currentPosition.column, 1);
      engine.currentRegion.start.clone(engine.currentPosition);
      expect(
          engine.search(StringSearcher(engine, 'a'),
              hitPosition: engine.currentPosition),
          isTrue);
      expect(engine.currentPosition.line, 1);
      expect(engine.currentPosition.column, 2);
    });
    test('restricted by last line', () {
      position.clone(engine.currentRegion.start);
      expect(
          engine.search(StringSearcher(engine, '4'),
              hitPosition: engine.currentRegion.end),
          isTrue);
      expect(engine.currentRegion.end.line, 2);
      expect(engine.currentRegion.end.column, 6);
      engine.currentPosition.set(2, 0);
      expect(engine.search(StringSearcher(engine, '4'), hitPosition: position),
          isFalse);
    });
    test('parameter relativePosition', () {
      resetEngine(engine);
      expect(
          engine.search(RegExpSearcher(engine, pattern: r'ab \d'),
              hitPosition: position,
              relativePosition: RelativePosition.aboveFirst),
          isTrue);
      expect(position.line, 1);
      expect(position.column, 2);
      expect(
          engine.search(RegExpSearcher(engine, pattern: r'ab \d'),
              hitPosition: position,
              relativePosition: RelativePosition.onFirst),
          isTrue);
      expect(position.line, 1);
      expect(position.column, 2);
      expect(
          engine.search(RegExpSearcher(engine, pattern: r'ab \d'),
              hitPosition: position, relativePosition: RelativePosition.onLast),
          isTrue);
      expect(position.line, 1);
      expect(position.column, 2);
      expect(engine.currentPosition.line, 1);
      expect(engine.currentPosition.column, 5);
      expect(
          engine.search(RegExpSearcher(engine, pattern: r'ab \d'),
              hitPosition: position,
              relativePosition: RelativePosition.belowLast),
          isTrue);
      expect(position.line, 2);
      expect(position.column, 2);
      expect(engine.currentPosition.line, 2);
      expect(engine.currentPosition.column, 6);
    });
    test('parameter skipLastMatch', () {
      resetEngine(engine);
      engine.currentPosition.set(1, 2);
      expect(engine.search(RegExpSearcher(engine, pattern: r'ab \d')), isTrue);
      expect(engine.currentPosition.line, 1);
      expect(engine.currentPosition.column, 2);
      expect(
          engine.search(RegExpSearcher(engine, pattern: r'ab \d'),
              skipLastMatch: true),
          isTrue);
      expect(engine.currentPosition.line, 2);
      expect(engine.currentPosition.column, 2);
    });
    test('parameter caseSensitive: false', () {
      resetEngine(engine);
      expect(
          engine.search(
              RegExpSearcher(engine, pattern: r'AB \d', caseSensitive: false),
              hitPosition: position),
          isTrue);
      expect(position.line, 1);
      expect(position.column, 2);
    });
  });
  group('SearchEngine-count', () {
    test('parameter maximalHitsPerLine', () {
      resetEngine(engine);
      expect(
          engine.count(RegExpSearcher(engine, pattern: r'\d'),
              maximalHitsPerLine: 2),
          6);
    });
    test('parameter maximalHits', () {
      resetEngine(engine);
      expect(
          engine.count(RegExpSearcher(engine, pattern: r'\d'), maximalHits: 3),
          3);
    });
    test('case sensitive: false', () {
      resetEngine(engine);
      expect(
          engine.count(
              RegExpSearcher(engine, pattern: r'AB \d', caseSensitive: false)),
          2);
    });
  });
  group('SearchEngine-searchReverse', () {
    test('normal case', () {
      resetEngine(engine);
      engine.currentPosition.clone(engine.currentRegion.end);
      engine.currentPosition.backward(1);
      expect(engine.searchReverse(RegExpSearcher(engine, pattern: r'AB \d')),
          isTrue);
      expect(engine.currentPosition.line, 2);
      expect(engine.currentPosition.column, 2);
    });
    test('outside region', () {
      resetEngine(engine);
      engine.currentPosition.clone(engine.currentRegion.end);
      expect(engine.searchReverse(RegExpSearcher(engine, pattern: r'AB \d')),
          isFalse);
    });
    test('exactly one line in region', () {
      resetEngine(engine);
      engine.currentRegion.start.set(1, 2);
      engine.currentRegion.end.set(1, 5);
      final searcher = RegExpSearcher(engine, pattern: r'\S\S');
      expect(
          engine.searchReverse(searcher,
              startPosition: engine.currentRegion.end, offsetBackward: 1),
          isTrue);
      expect(engine.currentPosition.line, 1);
      expect(engine.currentPosition.column, 2);
    });
    test('hit in first line of the region with region.start.column > 0', () {
      resetEngine(engine);
      engine.currentRegion.start.set(1, 2);
      engine.currentRegion.end.set(4, 0);
      final searcher = RegExpSearcher(engine, pattern: r'ab 1');
      expect(engine.searchReverse(searcher, startPosition: Position(3, 0)),
          isTrue);
      expect(engine.currentPosition.line, 1);
      expect(engine.currentPosition.column, 2);
    });
    test('hit in last line of the region with region.end.column > 0', () {
      resetEngine(engine);
      engine.currentRegion.start.set(1, 4);
      engine.currentRegion.end.set(2, 4);
      expect(
          engine.searchReverse(StringInsensitiveSearcher(engine, 'AB '),
              startPosition: engine.currentRegion.end, offsetBackward: 1),
          isFalse);
      expect(
          engine.searchReverse(StringInsensitiveSearcher(engine, 'AB'),
              startPosition: engine.currentRegion.end, offsetBackward: 1),
          isTrue);
      expect(engine.currentPosition.line, 2);
      expect(engine.currentPosition.column, 2);
    });
    test('hit in first line of the region with region.start.column == 0', () {
      resetEngine(engine);
      engine.currentRegion.start.set(1, 0);
      engine.currentRegion.end.set(2, 4);
      expect(
          engine.searchReverse(StringInsensitiveSearcher(engine, 'Ab 1'),
              startPosition: engine.currentRegion.end, offsetBackward: 1),
          isTrue);
      expect(engine.currentPosition.line, 1);
      expect(engine.currentPosition.column, 2);
    });
  });
  group('SearchEngine-findBlockStart', () {
    test('not matching', () {
      final block = Block(<BlockEntry>[
        BlockEntry(
            BlockEntryType.startEndSequence, StringSearcher(engine, ' ab'),
            searcherEnd: StringSearcher(engine, '34')),
        BlockEntry(BlockEntryType.line, StringSearcher(engine, '2')),
      ]);
      resetEngine(engine);
      engine.currentPosition.set(3, 0);
      expect(engine.findBlockStart(block), isFalse);
    });
    test('start+end', () {
      final block = Block(<BlockEntry>[
        BlockEntry(
            BlockEntryType.line, RegExpSearcher(engine, pattern: r'^\w')),
        BlockEntry(BlockEntryType.line, StringSearcher(engine, '2')),
      ]);
      resetEngine(engine);
      engine.currentPosition.set(1, 4);
      expect(engine.findBlockStart(block), isTrue);
      expect(engine.currentPosition.line, 0);
      expect(engine.currentPosition.column, 0);
    });
    test('start+body+end', () {
      final block = Block(<BlockEntry>[
        BlockEntry(BlockEntryType.line, StringSearcher(engine, '1')),
        BlockEntry(BlockEntryType.sequence, StringSearcher(engine, '3')),
        BlockEntry(BlockEntryType.line, StringSearcher(engine, '5')),
      ]);
      resetEngine(engine);
      engine.currentPosition.set(3, 2);
      expect(engine.findBlockStart(block), isTrue);
      expect(engine.currentPosition.line, 1);
      expect(engine.currentPosition.column, 0);
    });
    test('body, defined by match', () {
      final block = Block(<BlockEntry>[
        BlockEntry(
            BlockEntryType.sequence, RegExpSearcher(engine, pattern: '^>')),
      ]);
      resetEngine(engine);
      engine.currentPosition.set(2, 0);
      expect(engine.findBlockStart(block, offsetBackward: 1), isTrue);
      expect(engine.currentPosition.line, 1);
      expect(engine.currentPosition.column, 0);
    });
    test('body, defined by "no match"', () {
      final block = Block(<BlockEntry>[
        BlockEntry(BlockEntryType.notSequence,
            RegExpSearcher(engine, pattern: r'^\w')),
      ]);
      resetEngine(engine);
      engine.currentPosition.set(2, 0);
      expect(engine.findBlockStart(block, offsetBackward: 1), isTrue);
      expect(engine.currentPosition.line, 1);
      expect(engine.currentPosition.column, 0);
    });
  });
  group('SearchEngine-findBlockEnd', () {
    test('start+end', () {
      final block = Block(<BlockEntry>[
        BlockEntry(
            BlockEntryType.line, RegExpSearcher(engine, pattern: r'^\w')),
        BlockEntry(BlockEntryType.line, StringSearcher(engine, '2')),
      ]);
      resetEngine(engine);
      expect(engine.findBlockEnd(block), isTrue);
      expect(engine.currentPosition.line, 2);
      expect(engine.currentPosition.column, 0);
    });
    test('start+body+end', () {
      final block = Block(<BlockEntry>[
        BlockEntry(BlockEntryType.line, StringSearcher(engine, '1')),
        BlockEntry(BlockEntryType.sequence, StringSearcher(engine, '3')),
        BlockEntry(BlockEntryType.line, StringSearcher(engine, '5')),
      ]);
      resetEngine(engine);
      engine.currentPosition.set(1, 1);
      expect(engine.findBlockEnd(block), isTrue);
      expect(engine.currentPosition.line, 4);
      expect(engine.currentPosition.column, 0);
    });
    test('body, defined by match', () {
      final block = Block(<BlockEntry>[
        BlockEntry(
            BlockEntryType.sequence, RegExpSearcher(engine, pattern: '^>')),
      ]);
      resetEngine(engine);
      engine.currentPosition.set(1, 0);
      expect(engine.findBlockEnd(block), isTrue);
      expect(engine.currentPosition.line, 3);
      expect(engine.currentPosition.column, 0);
    });
    test('body, defined by "no match"', () {
      final block = Block(<BlockEntry>[
        BlockEntry(BlockEntryType.notSequence,
            RegExpSearcher(engine, pattern: r'^\w')),
      ]);
      resetEngine(engine);
      engine.currentPosition.set(1, 0);
      expect(engine.findBlockEnd(block), isTrue);
      expect(engine.currentPosition.line, 3);
      expect(engine.currentPosition.column, 0);
    });
  });
  group('SearchEngine-nextBlockFromList', () {
    test('basic loop', () {
      final block1 = Block(<BlockEntry>[
        BlockEntry(
            BlockEntryType.startEndSequence, StringSearcher(engine, ' ab'),
            searcherEnd: StringSearcher(engine, '34')),
      ], name: 'block1');
      final block2 = Block(<BlockEntry>[
        BlockEntry(BlockEntryType.startEndSequence, StringSearcher(engine, '4'),
            searcherEnd: StringSearcher(engine, '6')),
      ], name: 'block2');
      final alternatives = <Block>[block1, block2];
      resetEngine(engine);
      final start = Position(-1, 0);
      final end = Position(-1, 0);
      var currentBlock = engine.nextBlockFromList(alternatives,
          blockStart: start, blockEnd: end);
      expect(currentBlock?.name, 'block1');
      expect(start.toString(), 'line 1 column 0');
      expect(end.toString(), 'line 3 column 0');
      currentBlock = engine.nextBlockFromList(alternatives,
          blockStart: start, blockEnd: end);
      expect(currentBlock?.name, 'block2');
      expect(start.toString(), 'line 3 column 0');
      expect(end.toString(), 'line 4 column 0');
      currentBlock = engine.nextBlockFromList(alternatives,
          blockStart: start, blockEnd: end);
      expect(currentBlock, isNull);
    });
  });
  group('LastMatch', () {
    test('search-RegExpSearcher', () {
      resetEngine(engine);
      final searcher = RegExpSearcher(engine, pattern: '(.)[12]+');
      expect(engine.search(searcher), isTrue);
      expect(engine.lastMatch.type, LastMatchType.regularExpr);
      expect(engine.lastMatch.regExpMatch, isNotNull);
      expect(engine.lastMatch.group(0), ' 12');
      expect(engine.lastMatch.groupCount(), 1);
      expect(engine.lastMatch.group(1), ' ');
      expect(engine.lastMatch.position.toString(), 'line 1 column 4');
    });
    test('searchReverse-RegExpSearcher', () {
      resetEngine(engine);
      final searcher = RegExpSearcher(engine, pattern: '(.)[12]+');
      expect(engine.searchReverse(searcher, startPosition: Position(4, 0)),
          isTrue);
      expect(engine.lastMatch.type, LastMatchType.regularExpr);
      expect(engine.lastMatch.regExpMatch, isNotNull);
      expect(engine.lastMatch.group(0), ' 12');
      expect(engine.lastMatch.groupCount(), 1);
      expect(engine.lastMatch.group(1), ' ');
      expect(engine.lastMatch.position.toString(), 'line 1 column 4');
    });
    test('search-StringSearcher', () {
      resetEngine(engine);
      final searcher = StringSearcher(engine, '12');
      expect(engine.search(searcher), isTrue);
      expect(engine.lastMatch.type, LastMatchType.string);
      expect(engine.lastMatch.stringMatch, searcher.toSearch);
      expect(engine.lastMatch.group(0), searcher.toSearch);
      expect(engine.lastMatch.groupCount(), 0);
      expect(engine.lastMatch.position.toString(), 'line 1 column 5');
    });
    test('searchReverse-StringSearcher', () {
      resetEngine(engine);
      final searcher = StringSearcher(engine, '12');
      expect(engine.searchReverse(searcher, startPosition: Position(4, 0)),
          isTrue);
      expect(engine.lastMatch.type, LastMatchType.string);
      expect(engine.lastMatch.stringMatch, searcher.toSearch);
      expect(engine.lastMatch.group(0), searcher.toSearch);
      expect(engine.lastMatch.groupCount(), 0);
      expect(engine.lastMatch.position.toString(), 'line 1 column 5');
    });
  });
}

void resetEngine(SearchEngine engine) {
  engine.currentPosition.set(0, 0);
  engine.currentRegion.start.set(0, 0);
  engine.currentRegion.end.setEndOfText();
  engine.lastMatch.type = LastMatchType.undef;
  engine.lastMatch.regExpMatch = null;
  engine.lastMatch.stringMatch = null;
}
