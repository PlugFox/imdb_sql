import 'package:args/command_runner.dart';
import 'package:imdb_sql/src/db/imdb.dart';

class CountCommand extends Command<String> {
  final InternetMovieDatabase db;
  CountCommand(this.db);

  @override
  String get name => 'count';

  @override
  String get description => 'Подсчитать количество фильмов';

  @override
  Future<String> run() async {
    final titleCount = await db
        .customSelect('SELECT COUNT(1) AS count FROM titles')
        .getSingle()
        .then<String>((value) => value.data['count'].toString());
    final wordCount = await db
        .customSelect('SELECT COUNT(1) AS count FROM words')
        .getSingle()
        .then<String>((value) => value.data['count'].toString());
    return 'Количество фильмов: $titleCount шт.\n'
        'Количество слов: $wordCount шт.';
  }
}
