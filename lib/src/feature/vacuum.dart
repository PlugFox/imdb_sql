import 'package:args/command_runner.dart';
import 'package:imdb_sql/src/db/imdb.dart';

class VacuumCommand extends Command<String> {
  final InternetMovieDatabase db;
  VacuumCommand(this.db);

  @override
  String get name => 'vacuum';

  @override
  String get description => '''
    |Команда VACUUM очищает основную базу данных,
    |копируя ее содержимое во временный файл базы данных
    |и перезагружая исходный файл базы данных из копии.
    |Это устраняет бесплатные страницы,
    |выравнивает данные таблицы, чтобы быть смежными,
    |и в противном случае очищает структуру файла базы данных.
    ''';

  @override
  Future<String> run() => db.customStatement('VACUUM;').then<String>((_) => 'Успешно');
}
