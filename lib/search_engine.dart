/// Searching in a list of lines or a given text file.
///
/// Glossary:
/// A "position" is a well known location in the text, given by a line index (0..N)
/// and a column index (0..M)
/// A "region" is a part of the text given by a start and an end position.
/// The end position of the region is outside the region (exclusive).
///
/// The search engine contains a "current region". The operations will be done
/// only inside this region.
library search_engine;

export 'src/text_engine.dart';
export 'src/search_engine.dart';
export 'src/dart_parser.dart';
export 'src/search_engine_none.dart'
    if (dart.library.io) 'src/search_engine_io.dart';
