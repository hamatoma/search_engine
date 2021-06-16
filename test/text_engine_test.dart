import 'package:dart_bones/dart_bones.dart';
import 'package:search_engine/src/text_engine.dart';
import 'package:test/test.dart';

void main() {
  final logger = MemoryLogger(LEVEL_FINE);
  final lines = r'''abcd
> ab 12
> ab 345
456
'''
      .split('\n');
  final engine = TextEngine(lines, logger);
  group('Position', () {
    final engine2 = TextEngine.fromString('''123
abc

def''', logger);
    final position2 = Position(0, 0, engine2);
    test('isAbove', () {
      position2.set(1, 2);
      expect(position2.isAbove(Position(0, 2)), isFalse);
      expect(position2.isAbove(Position(1, 1)), isFalse);
      expect(position2.isAbove(Position(2, 2)), isTrue);
      expect(position2.isAbove(Position(1, 2)), isFalse);
      expect(position2.isAbove(Position(1, 2), orEqual: true), isTrue);
      expect(position2.isAbove(Position(1, 1), orEqual: true), isFalse);
      expect(position2.isAbove(Position(0, 2), orEqual: true), isFalse);
      expect(position2.isAbove(Position(2, 2), orEqual: true), isTrue);
    });
    test('isBelow', () {
      position2.set(1, 2);
      expect(position2.isBelow(Position(0, 2)), isTrue);
      expect(position2.isBelow(Position(1, 1)), isTrue);
      expect(position2.isBelow(Position(2, 2)), isFalse);
      expect(position2.isBelow(Position(1, 2)), isFalse);
      expect(position2.isBelow(Position(1, 2), orEqual: true), isTrue);
      expect(position2.isBelow(Position(1, 1), orEqual: true), isTrue);
      expect(position2.isBelow(Position(0, 2), orEqual: true), isTrue);
      expect(position2.isBelow(Position(2, 2), orEqual: true), isFalse);
    });
    test('forward-inside line', () {
      position2.set(0, 2);
      expect(position2.forward(1), true);
      expect(position2.line, 1);
      expect(position2.column, 0);
    });
    test('forward-skipping one line, begin of line', () {
      position2.set(0, 1);
      expect(position2.forward(5), true);
      expect(position2.line, 2);
      expect(position2.column, 0);
    });
    test('forward-skipping one line, inside the line', () {
      position2.set(0, 1);
      expect(position2.forward(6), true);
      expect(position2.line, 3);
      expect(position2.column, 1);
    });
    test('forward-exactly end of line', () {
      position2.set(0, 1);
      expect(position2.forward(8), true);
      expect(position2.line, 4);
      expect(position2.column, 0);
    });
    test('forward-below the end of line', () {
      position2.set(0, 1);
      expect(position2.forward(9), false);
      expect(position2.line, 4);
      expect(position2.column, 0);
    });
    test('backward-from beginOfLine', () {
      position2.set(1, 0);
      expect(position2.backward(1), true);
      expect(position2.line, 0);
      expect(position2.column, 2);
    });
    test('backward-skip empty line', () {
      // Position on "ef"
      position2.set(3, 1);
      expect(position2.backward(5), true);
      expect(position2.line, 0);
      expect(position2.column, 2);
    });
    test('backward-exactly to beginOfText', () {
      position2.set(3, 1);
      expect(position2.backward(7), true);
      expect(position2.line, 0);
      expect(position2.column, 0);
    });
    test('backward-below beginOfText', () {
      position2.set(3, 1);
      expect(position2.backward(8), false);
      expect(position2.line, 0);
      expect(position2.column, 0);
    });
    test('addColumn-inside line', () {
      position2.set(0, 1);
      expect(position2.addColumn(1), false);
      expect(position2.line, 0);
      expect(position2.column, 2);
    });
    test('addColumn-exceeds end of line', () {
      position2.set(0, 1);
      expect(position2.addColumn(2), true);
      expect(position2.line, 1);
      expect(position2.column, 0);
    });
    test('addColumn-negative offset', () {
      position2.set(0, 1);
      expect(position2.addColumn(-2), false);
      expect(position2.line, 0);
      expect(position2.column, 0);
    });
    test('clone', () {
      position2.set(0, 1);
      final position3 = Position(1, 2);
      position2.clone(position3);
      expect(position2.line, 1);
      expect(position2.column, 2);
    });
    test('endOfText', () {
      position2.set(0, 1);
      position2.endOfText();
      expect(position2.line, 4);
      expect(position2.column, 0);
    });
    test('nextLine-inside text', () {
      position2.set(0, 1);
      expect(position2.nextLine(), isFalse);
      expect(position2.line, 1);
      expect(position2.column, 0);
    });
    test('nextLine-to end of text', () {
      position2.set(3, 0);
      expect(position2.nextLine(), isFalse);
      expect(position2.line, 4);
      expect(position2.column, 0);
    });
    test('nextLine-at end of text', () {
      position2.set(4, 0);
      expect(position2.nextLine(), isTrue);
      expect(position2.line, 4);
      expect(position2.column, 0);
    });
    test('nextLine-count > 1, middle of the text', () {
      position2.set(1, 0);
      expect(position2.nextLine(2), isFalse);
      expect(position2.line, 3);
      expect(position2.column, 0);
    });
    test('nextLine-count > 1, beyond end of text', () {
      position2.set(2, 0);
      expect(position2.nextLine(3), isTrue);
      expect(position2.line, 4);
      expect(position2.column, 0);
    });
    test('normalize-inside line', () {
      position2.set(0, 1);
      expect(position2.normalize(), isFalse);
      expect(position2.line, 0);
      expect(position2.column, 1);
    });
    test('normalize-behind end of line', () {
      position2.set(2, 1);
      expect(position2.normalize(), isFalse);
      expect(position2.line, 3);
      expect(position2.column, 0);
    });
    test('normalize-behind end of text', () {
      position2.line = 4;
      position2.column = 1;
      expect(position2.normalize(), isTrue);
      expect(position2.line, 4);
      expect(position2.column, 0);
    });
    test('previousLine-middle of the text', () {
      position2.set(3, 1);
      expect(position2.previousLine(), isFalse);
      expect(position2.line, 2);
      expect(position2.column, 0);
    });
    test('previousLine-from first line', () {
      position2.set(0, 1);
      expect(position2.previousLine(), isTrue);
      expect(position2.line, 0);
      expect(position2.column, 0);
    });
    test('previousLine-count > 1, middle of the text', () {
      position2.set(3, 0);
      expect(position2.previousLine(2), isFalse);
      expect(position2.line, 1);
      expect(position2.column, 0);
    });
    test('previousLine-count > 1, beyond begin of text', () {
      position2.set(1, 1);
      expect(position2.previousLine(2), isTrue);
      expect(position2.line, 0);
      expect(position2.column, 0);
    });
    test('setEndOfText-middle of the text', () {
      position2.set(0, 1);
      position2.setEndOfText();
      expect(position2.line, 4);
      expect(position2.column, 0);
    });
    test('setEndOfText-from end of the text', () {
      position2.set(4, 0);
      position2.setEndOfText();
      expect(position2.line, 4);
      expect(position2.column, 0);
    });
    test('toString', () {
      position2.set(1, 2);
      expect(position2.toString(), equals('line 1 column 2'));
    });
  });
  group('Region', () {
    final region =
        Region(start: Position(0, 0, engine), end: Position(0, 0, engine));
    region.end.endOfText();
    test('toString', () {
      expect(region.toString(),
          equals('start: line 0 column 0 end: line 5 column 0'));
    });
    test('clone', () {
      final region2 =
          Region(start: Position(1, 2, engine), end: Position(3, 1, engine));
      region.clone(region2);
      expect(region.toString(),
          equals('start: line 1 column 2 end: line 3 column 1'));
    });
    test('contains', () {
      region.start.set(1, 2);
      region.end.set(2, 4);
      expect(region.contains(Position(1, 1)), isFalse);
      expect(region.contains(Position(1, 2)), isTrue);
      expect(region.contains(Position(0, 0)), isFalse);
      expect(region.contains(Position(2, 4)), isFalse);
      expect(region.contains(Position(2, 3)), isTrue);
      expect(region.contains(Position(3, 0)), isFalse);
    });
  });
  group('TextEngine-asList', () {
    test('single line', () {
      resetEngine(engine);
      expect(engine.asList(start: Position(1, 1), end: Position(1, 3)),
          equals([' a']));
      expect(
          engine.asList(
              start: Position(1, 1), end: Position(1, 3), isInclusive: true),
          equals([' ab']));
    });
    test('3 lines, last line empty', () {
      resetEngine(engine);
      expect(engine.asList(start: Position(1, 1), end: Position(4, 0)),
          equals([' ab 12', '> ab 345', '456']));
    });
    test('3 lines, last line not empty', () {
      resetEngine(engine);
      expect(engine.asList(start: Position(1, 1), end: Position(3, 2)),
          equals([' ab 12', '> ab 345', '45']));
    });
  });
  group('TextEngine-asString', () {
    test('single line', () {
      resetEngine(engine);
      expect(engine.asString(start: Position(1, 1), end: Position(1, 3)),
          equals(' a'));
      expect(
          engine.asString(
              start: Position(1, 1), end: Position(1, 3), isInclusive: true),
          equals(' ab'));
    });
    test('3 lines, last line empty', () {
      resetEngine(engine);
      expect(engine.asString(start: Position(1, 1), end: Position(4, 0)),
          equals(' ab 12\n> ab 345\n456'));
    });
    test('3 lines, last line not empty', () {
      resetEngine(engine);
      expect(engine.asString(start: Position(1, 1), end: Position(3, 2)),
          equals(' ab 12\n> ab 345\n45'));
    });
  });
  group('TextEngine-insert', () {
    test('single line, begin of line', () {
      final engine = TextEngine('12\n34'.split('\n'), logger);
      engine.insert('ABC');
      expect(engine.lines, equals(['ABC12', '34']));
    });
    test('single line, middle of the line', () {
      final engine = TextEngine('12\n34'.split('\n'), logger);
      engine.insert('ABC', position: Position(0, 1));
      expect(engine.lines, equals(['1ABC2', '34']));
    });
    test('single line, end of text', () {
      final engine = TextEngine('12\n34'.split('\n'), logger);
      engine.insert('ABC', position: Position(2, 0));
      expect(engine.lines, equals(['12', '34', 'ABC']));
    });
  });
  group('TextEngine-insertLines', () {
    test('single line, begin of line', () {
      final engine = TextEngine('12\n34'.split('\n'), logger);
      engine.insertLines(['ABC', 'X']);
      expect(engine.lines, equals(['ABC', 'X', '12', '34']));
    });
    test('single line, middle of the line', () {
      final engine = TextEngine('12\n34'.split('\n'), logger);
      engine.insertLines(['ABC', 'X'], position: Position(0, 1));
      expect(engine.lines, equals(['1ABC', 'X', '2', '34']));
    });
    test('single line, end of text', () {
      final engine = TextEngine('12\n34'.split('\n'), logger);
      engine.insertLines(['ABC', 'X'], position: Position(2, 0));
      expect(engine.lines, equals(['12', '34', 'ABC', 'X']));
    });
  });
  group('TextEngine-deleteFromTo', () {
    test('3 lines, middle of the line', () {
      final engine = TextEngine('123\n45\n67\n89'.split('\n'), logger);
      engine.deleteFromTo(start: Position(0, 1), end: Position(2, 1));
      expect(engine.lines, equals(['1', '7', '89']));
    });
    test('3 lines, start of the line', () {
      final engine = TextEngine('123\n45\n67\n89'.split('\n'), logger);
      engine.deleteFromTo(end: Position(2, 1));
      expect(engine.lines, equals(['7', '89']));
    });
    test('single line, begin of line', () {
      final engine = TextEngine('123\n34'.split('\n'), logger);
      engine.deleteFromTo(end: Position(0, 2));
      expect(engine.lines, equals(['3', '34']));
    });
    test('single line, middle of the line', () {
      final engine = TextEngine('123\n34'.split('\n'), logger);
      engine.deleteFromTo(start: Position(0, 1), end: Position(0, 2));
      expect(engine.lines, equals(['13', '34']));
    });
    test('2 lines, middle of the line', () {
      final engine = TextEngine('123\n45\n67'.split('\n'), logger);
      engine.deleteFromTo(start: Position(0, 1), end: Position(1, 1));
      expect(engine.lines, equals(['1', '5', '67']));
    });
    test('2 lines, start of the line', () {
      final engine = TextEngine('123\n45\n67'.split('\n'), logger);
      engine.deleteFromTo(end: Position(1, 1));
      expect(engine.lines, equals(['5', '67']));
    });
  });
  group('Position-isEndOfText', () {
    test('currentPosition', () {
      final engine = TextEngine('123\n45\n67\n89'.split('\n'), logger);
      expect(engine.currentPosition.isEndOfText(), isFalse);
      engine.currentPosition.endOfText();
      expect(engine.currentPosition.isEndOfText(), isTrue);
    });
    test('given position', () {
      final engine = TextEngine('123\n45\n67\n89'.split('\n'), logger);
      final position = Position(2, 3, engine);
      expect(position.isEndOfText(), isFalse);
      position.endOfText();
      expect(position.isEndOfText(), isTrue);
    });
  });
}

void resetEngine(TextEngine engine) {
  engine.currentPosition.set(0, 0);
  engine.currentRegion.start.set(0, 0);
  engine.currentRegion.end.setEndOfText();
}
