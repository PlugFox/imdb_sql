import 'package:args/command_runner.dart';
import 'package:imdb_sql/src/db/imdb.dart';
import 'package:moor/moor.dart';
import 'package:multiline/multiline.dart';

class SelectCommand extends Command<String> {
  final InternetMovieDatabase db;

  SelectCommand(this.db) {
    argParser.addOption('query', abbr: 'q');
  }

  @override
  String get name => 'select';

  @override
  String get description => 'Найти заданный фильм';

  @override
  Future<String> run() async {
    final Object? arg = argResults?['query'];
    if (arg is! String || arg.trim().length < 3) {
      return 'Отсутсвует строка запроса или содержит меньше 3 символов';
    }
    final param = arg.trim().toLowerCase();
    final rows = await db.customSelect(
      '''
    |SELECT
    |    t.title_id                                  AS id
    |  , IFNULL(t.original_title, t.primary_title)   AS title
    |  , IFNULL(t.is_adult, 0)                       AS is_adult
    |  , IFNULL(t.premiered, -1)                     AS premiered
    |  , IFNULL(t.runtime_minutes, -1)               AS runtime_minutes
    |  , IFNULL(t.genres, '')                        AS genres
    |  , IFNULL(r.rating, -1)                        AS rating
    |  , IFNULL(r.votes, -1)                         AS votes
    |  , 'https://www.imdb.com/title/' || t.title_id AS url
    |FROM
    |  (
    |    SELECT DISTINCT
    |        title_id
    |    FROM
    |      (
    |        SELECT
    |            word
    |          , title_id
    |        FROM
    |          words
    |        WHERE
    |          first_3_char = substr(?, 1, 3)
    |      )
    |    WHERE
    |      word LIKE ?
    |    ORDER BY
    |      title_id ASC
    |    LIMIT 100 OFFSET 0
    |  ) AS w
    |  INNER JOIN titles AS t
    |    ON w.title_id = t.title_id
    |  LEFT JOIN ratings AS r
    |    ON w.title_id = r.title_id
    |  ORDER BY
    |    r.rating DESC,
    |    r.votes DESC
    '''
          .multiline(),
      variables: <Variable>[
        Variable.withString(param.substring(0, 3)),
        Variable.withString('$param%'),
      ],
    ).get();
    final builder = StringBuffer(_header);
    for (final row in rows) {
      builder.writeln(_buildRowRepresentation(row));
    }
    return builder.toString();
  }

  static String get _header => '${'ID'.padLeft(9)}|18+|TIME|TITLE\n'
      '${'VOTES'.padLeft(9)}|RTG|YEAR|URL\n'
      '${'-' * 55}\n';

  String _buildRowRepresentation(QueryRow row) {
    final d = row.data;
    String fmtLeft(String field, int length) => (d[field] ?? '').toString().padLeft(length, ' ').substring(0, length);
    String fmtRight(String field, int length) => (d[field] ?? '').toString().padRight(length, ' ').substring(0, length);
    return '${fmtLeft('id', 9)}|${d['is_adult'] == 1 ? 'yes' : ' no'}|${fmtLeft('runtime_minutes', 4)}|${fmtRight('title', 64)}\n'
        '${fmtLeft('votes', 9)}|${fmtLeft('rating', 3)}|${fmtLeft('premiered', 4)}|${fmtRight('url', 64)}\n'
        '${'-' * 55}';
  }
}
