import 'dart:io' as io;

import 'package:moor/ffi.dart';
import 'package:moor/moor.dart';
import 'package:path/path.dart' as p;

part 'imdb.g.dart';

@UseMoor(tables: [])
class InternetMovieDatabase extends _$InternetMovieDatabase {
  InternetMovieDatabase([String path = 'db/imdb.db']) : super(VmDatabase(io.File(p.normalize(path))));

  @override
  int get schemaVersion => 1;
}
