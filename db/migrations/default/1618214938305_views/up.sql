SET search_path TO public;

CREATE OR REPLACE VIEW users AS
SELECT id, first_name, middle_name, last_name, school_id, created_at, auth0_id
FROM users_all
WHERE deleted_at IS NULL;

CREATE FUNCTION get_name(first text, middle text, last text) RETURNS text AS
$$
BEGIN
    IF middle IS NULL THEN
        RETURN concat(first, ' ', last);
    END IF;
    RETURN concat(first, ' ', middle, ' ', last);
END;
$$ LANGUAGE plpgsql;

CREATE VIEW work_summaries AS
SELECT name, creator, type, count(work_id) work_count
FROM (
         SELECT t.name                                             AS name,
                get_name(a.first_name, a.middle_name, a.last_name) AS creator,
                e.work_id                                          AS work_id,
                0                                                  AS type
         FROM titles t
                  LEFT JOIN authors a on a.id = t.author_id
                  LEFT JOIN essays e on t.id = e.title_id
         UNION
         SELECT c.name     AS name,
                t2.name    AS creator,
                c2.work_id AS work_id,
                1          AS type
         FROM characters c
                  LEFT JOIN titles t2 on t2.id = c.title_id
                  LEFT JOIN characterizations c2 on c.id = c2.character_id
     ) AS q
GROUP BY name, creator, type
ORDER BY type, creator, name;
