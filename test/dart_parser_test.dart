import 'package:dart_bones/dart_bones.dart';
import 'package:search_engine/search_engine.dart';
import 'package:search_engine/src/search_engine.dart';
import 'package:test/test.dart';

void main() {
  final logger = MemoryLogger(LEVEL_FINE);
  final lines = r'''import 'dart:io';
class ExampleClass extends 
 AVeryLongClassNameToBreakAClassIntoMoreThanOneLine {
 List<Map<String, int>> map = [
   {'nothing': 1 },
   {'any': 2};
   ];
 int? _hiddenInt;
 final int publicInt;
 ExampleClass(this.publicInt): AVeryLongClassNameToBreakAClassIntoMoreThanOneLine
}
'''
      .split('\n');
  group('DartParser-Strings+comments', () {
    test('dummy', () {
      expect(lines, isNotEmpty);
    });
    test('single line comment', () {
      final parser = DartParser(SearchEngine(
          r'''  // Comment
a = 2; // Remember
/// Document
/// Line2
c = 3'''
              .split('\n'),
          logger));
      parser.replaceStringsAndComments();
      expect(parser.multiComments.length, 2);
      expect(parser.multiComments['_MulCCoMeNt0_'], '// Comment');
      expect(parser.multiComments['_MulCCoMeNt1_'], '/// Document\n/// Line2');
      expect(parser.engine.lines.join('\n'), '''  _MulCCoMeNt0_
a = 2; _MulCCoMeNt1_
_MulCCoMeNt2_
''');
    });
    test("multi line strings '''", () {
      final parser = DartParser(SearchEngine(
          r"""a = '''abc
def''';
xyz=r'''5 $
c:\String
''';
a2 = ''''Hi'''';
a3 = r'''(\d)''';
"""
              .split('\n'),
          logger));
      parser.replaceStringsAndComments();
      expect(parser.multiStrings.length, 4);
      expect(parser.multiStrings['_MulSStrInG0_'], "''abc\ndef'''");
      expect(parser.multiStrings['_MulSStrInG1_'], "r'''5 \$\nc:\\String\n'''");
      expect(parser.multiStrings['_MulSStrInG2_'], "''\'Hi\''''");
      expect(parser.multiStrings['_MulSStrInG3_'], "r'''(\\d+)'''");
      expect(parser.engine.lines.join('\n'), '''a = _MulSStrInG0_
;
xyz=_MulSStrInG1_
;
a2 = _MulSStrInG2_;
a3 = _MulSStrInG3_;
''');
    });
    test('multi line strings """', () {
      final parser = DartParser(SearchEngine(
          r'''a = """abc
def""";
xyz=r"""5 $
c:\String
""";
a2 = """'Hi'""";
a3 = r"""(\d+)""";
'''
              .split('\n'),
          logger));
      parser.replaceStringsAndComments();
      expect(parser.multiStrings.length, 4);
      expect(parser.multiStrings['_MulSStrInG0_'], '"""abc\ndef"""');
      expect(parser.multiStrings['_MulSStrInG1_'], 'r"""5 \$\nc:\\String\n"""');
      expect(parser.multiStrings['_MulSStrInG2_'], '"""\'Hi\'"""');
      expect(parser.multiStrings['_MulSStrInG3_'], 'r"""(\\d+)"""');
      expect(parser.engine.lines.join('\n'), '''a = _MulSStrInG0_
;
xyz=_MulSStrInG1_
;
a2 = _MulSStrInG2_;
a3 = _MulSStrInG3_;
''');
    });
    test('single line strings', () {
      final parser = DartParser(SearchEngine(
          r'''a='abc\n\'';
b="123\n\"";
d=r'\d+';
e=r"(\w+)xxx";
'''
              .split('\n'),
          logger));
      parser.replaceStringsAndComments();
      expect(parser.multiStrings.length, 4);
      expect(parser.multiStrings['_MulSStrInG0_'], "'abc\\n\\\'\'");
      expect(parser.multiStrings['_MulSStrInG1_'], '"123\\n\\""');
      expect(parser.multiStrings['_MulSStrInG2_'], r"r'\d+'");
      expect(parser.multiStrings['_MulSStrInG3_'], r'r"(\w+)xxx"');
      expect(parser.engine.lines.join('\n'), '''a=_MulSStrInG0_;
b=_MulSStrInG1_;
d=_MulSStrInG2_;
e=_MulSStrInG3_;
''');
    });
  });
}

void resetEngine(SearchEngine engine) {
  engine.currentPosition.set(0, 0);
  engine.currentRegion.start.set(0, 0);
  engine.currentRegion.end.setEndOfText();
}

class AVeryLongClassNameToBreakAClassDefinitionIntoMoreThanOneLine12345678901234 {
  final String name;
  AVeryLongClassNameToBreakAClassDefinitionIntoMoreThanOneLine12345678901234(
      this.name);
}

class DataClassWithAVeryLongNameThatFillsALineWithLengthOf80CharactersWithoutProblems {
  String data =
      'fdkafjdasklfdsalfdsalfdsaklfjdasaklfjdsakfjdsaklfjdsaklfjdsakfjdsakx';
  DataClassWithAVeryLongNameThatFillsALineWithLengthOf80CharactersWithoutProblems(
      this.data);
}

class ExampleClass
    extends AVeryLongClassNameToBreakAClassDefinitionIntoMoreThanOneLine12345678901234 {
  static ExampleClass? _lastInstance;
  List<Map<String, int>> map = [
    {'nothing': 1},
    {'any': 2},
  ];
  int? _hiddenInt;
  int? _id;
  final int publicInt;
  ExampleClass(this.publicInt)
      : super(
            'AVeryLongClassNameToBreakAClassDefinitionIntoMoreThanOneLine12345678901234') {
    _hiddenInt = 1;
    _id = 1;
    print('$_id');
  }
  ExampleClass.fromString(String number) : this(int.parse(number));

  /// standard getter
  int? get hiddenInt => _hiddenInt;

  /// standard setter
  set id(int id) => _id = id;

  /// a simple method with short body.
  void put(int? value) => _hiddenInt = value;

  /// standard method
  bool test(
      {required DataClassWithAVeryLongNameThatFillsALineWithLengthOf80CharactersWithoutProblems
          data}) {
    return _internalTest(data: data);
  }

  /// private standard method
  bool _internalTest(
      {required DataClassWithAVeryLongNameThatFillsALineWithLengthOf80CharactersWithoutProblems
          data}) {
    return data.data.isEmpty;
  }

  /// a static method
  static ExampleClass instance() {
    return _lastInstance ?? ExampleClass(0);
  }
}
