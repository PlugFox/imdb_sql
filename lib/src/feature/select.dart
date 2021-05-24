/*
SELECT
    t.title_id                                  AS id
  , IFNULL(t.original_title, t.primary_title)   AS title
  , IFNULL(t.is_adult, 0)                       AS is_adult
  , IFNULL(t.premiered, -1)                     AS premiered
  , IFNULL(t.runtime_minutes, -1)               AS runtime_minutes
  , IFNULL(t.genres, '')                        AS genres
  , IFNULL(r.rating, -1)                        AS rating
  , IFNULL(r.votes, -1)                         AS votes
  , 'https://www.imdb.com/title/' || t.title_id AS url
FROM
  (
    SELECT DISTINCT
        title_id
    FROM
      (
        SELECT
            word
          , title_id
        FROM
          words
        WHERE
          first_3_char = substr('бабоч', 1, 3)
      )
    WHERE
      word LIKE 'бабоч%'
    ORDER BY
      title_id ASC
    LIMIT 100 OFFSET 0
  ) AS w
  INNER JOIN titles AS t
    ON w.title_id = t.title_id
  LEFT JOIN ratings AS r
    ON w.title_id = r.title_id
  ORDER BY
    r.rating DESC,
    r.votes DESC
 */
