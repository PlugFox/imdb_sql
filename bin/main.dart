import 'dart:async';
import 'dart:io' as io;

import 'package:args/command_runner.dart';
import 'package:imdb_sql/imdb_sql.dart';

void main(List<String> args) => runZonedGuarded(
      () async {
        if (args.isEmpty) io.exit(0);
        final stopwatch = Stopwatch()..start();
        final db = InternetMovieDatabase();
        final runner = CommandRunner<String>('IMDB', 'IMDB Sample DB')
          ..addCommand(VacuumCommand(db))
          ..addCommand(PrepareCommand(db))
          ..addCommand(CountCommand(db));
        try {
          final result = await runner.run(args);
          io.stdout.writeln(result);
        } finally {
          final elapsedMilliseconds = (stopwatch..stop()).elapsedMilliseconds;
          io.stdout.writeln(
              '$elapsedMilliseconds ms ${elapsedMilliseconds > 1000 ? ' (${elapsedMilliseconds ~/ 1000} sec)' : ''}');
          await db.close().timeout(const Duration(seconds: 5));
        }
        io.exit(0);
      },
      (error, stackTrace) {
        io.stdout.writeln('\x1B[31m$error\x1B[0m');
        io.stdout.writeln('\x1B[31m$stackTrace\x1B[0m');
        io.exit(2);
      },
    );
