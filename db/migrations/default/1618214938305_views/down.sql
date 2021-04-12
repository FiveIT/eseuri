SET search_path TO public;

DROP VIEW work_summaries;

DROP FUNCTION get_name;

CREATE OR REPLACE VIEW users AS
SELECT id, first_name, middle_name, last_name, school_id, created_at, auth0_id
FROM users_all
WHERE deleted_at IS NOT NULL;