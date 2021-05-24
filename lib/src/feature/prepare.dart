// ignore_for_file: literal_only_boolean_expressions, avoid_escaping_inner_quotes
import 'dart:io' as io;
import 'dart:math' as math;

import 'package:args/command_runner.dart';
import 'package:imdb_sql/src/db/imdb.dart';
import 'package:multiline/multiline.dart';

class PrepareCommand extends Command<String> {
  final InternetMovieDatabase db;
  PrepareCommand(this.db);

  @override
  String get name => 'prepare';

  @override
  String get description => 'Подготовить базу данных к поиску';

  @override
  Future<String> run() async {
    await db.customStatement('''
      |DROP TABLE IF EXISTS "words";
      |DROP INDEX IF EXISTS "idx_title_first_3_char";
      |CREATE TABLE "words" (
      |  "title_id"      TEXT NOT NULL,
      |  "first_1_char"  TEXT NOT NULL,
      |  "first_3_char"  TEXT NOT NULL,
      |  "first_5_char"  TEXT NOT NULL,
      |  "word"          TEXT NOT NULL,
      |  "region"        TEXT NOT NULL,
      |  FOREIGN KEY("title_id")
      |    REFERENCES "titles"("title_id")
      |      ON DELETE CASCADE
      |);
      |CREATE INDEX "idx_first_1_char" ON "words" (
      |  "first_1_char"
      |);
      |CREATE INDEX "idx_first_3_char" ON "words" (
      |  "first_3_char"
      |);
      |CREATE INDEX "idx_first_5_char" ON "words" (
      |  "first_5_char"
      |);
      |CREATE INDEX "idx_word" ON "words" (
      |  "word"
      |);
      |CREATE INDEX "idx_region" ON "words" (
      |  "region"
      |);
    '''
        .multiline());

    await db.customStatement('''
      |DROP TABLE IF EXISTS tmp;
      |CREATE TABLE tmp (
      |	 id        INTEGER,
      |	 title_id  TEXT,
      |	 title     TEXT,
      |  region    TEXT,
      |	 PRIMARY KEY("id" AUTOINCREMENT)
      |);
      |INSERT INTO tmp
      |SELECT
      |    NULL
      |  , title_id
      |  , title
      |  , region
      |FROM
      |  akas
      |WHERE
      |  title_id NOTNULL
      |  AND title NOTNULL
      |  AND region NOTNULL
      |  AND region IN ("RU", "US");
    '''
        .multiline());

    final total = await db
        .customSelect('SELECT COUNT(1) AS count FROM tmp')
        .getSingle()
        .then((value) => value.data['count'] as int);
    const limit = 50000;
    var step = 0;
    final stopwatch = Stopwatch()..start();
    while (true) {
      if (stopwatch.elapsedMilliseconds > 60000) {
        stopwatch.reset();
        io.stdout.writeln('${step * 100 ~/ (total / limit)}%');
      }
      final rows = await db
          .customSelect('''
              |SELECT
              |    t.title_id AS title_id
              |  , t.title    AS title
              |  , t.region   AS region
              |FROM
              |  "tmp" AS t
              |ORDER BY id ASC
              |LIMIT $limit OFFSET ${step * limit}
            '''
              .multiline())
          .get();
      if (rows.isEmpty) break;
      await db.transaction<void>(() async {
        final buffer = StringBuffer('''
          |INSERT INTO "words"
          |  ( "title_id", "first_1_char", "first_3_char", "first_5_char", "word", "region" )
          |VALUES
          |
          '''
            .multiline());
        final rowsIterator = rows.iterator..moveNext();
        var count = 0;
        while (true) {
          final row = rowsIterator.current;
          final titleId = row.data['title_id'] as String;
          final region = row.data['region'] as String;
          final title = row.data['title'] as String;
          final words = _extractWords(title).toList(growable: false);
          if (words.isEmpty) {
            if (rowsIterator.moveNext()) {
              continue;
            } else {
              break;
            }
          }
          final wordsIterator = words.iterator..moveNext();
          while (true) {
            final word = wordsIterator.current;
            buffer.write('  (\'$titleId\', '
                '\'${word.substring(0, 1)}\', '
                '\'${word.substring(0, 3)}\', '
                '\'${word.substring(0, math.min(word.length, 5))}\', '
                '\'$word\', '
                '\'$region\'),');
            count++;
            if (!wordsIterator.moveNext()) break;
          }
          if (!rowsIterator.moveNext()) break;
        }
        if (count == 0) return;
        final query = buffer.toString();
        try {
          await db.customInsert('${query.substring(0, query.length - 1)};');
        } on Object {
          io.stdout.writeln('\x1B[31m$query\x1B[0m');
          rethrow;
        }
        return;
      });
      step++;
    }
    stopwatch.stop();
    await db.customStatement('DROP TABLE IF EXISTS "tmp";');
    return 'Успешно';
  }

  Iterable<String> _extractWords(String title) sync* {
    final codes = title.trim().toLowerCase().codeUnits;
    final buffer = <int>[];
    for (final code in codes) {
      if ((code >= 48 && code <= 57) || (code >= 97 && code <= 122) || (code >= 1072 && code <= 1103)) {
        buffer.add(code);
      } else {
        if (buffer.length > 2) {
          yield String.fromCharCodes(buffer);
        }
        buffer.clear();
      }
    }
    if (buffer.length > 2) {
      yield String.fromCharCodes(buffer);
    }
  }
}
