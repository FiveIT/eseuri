SET search_path TO public;

DROP FUNCTION create_user;

DROP VIEW users;
CREATE VIEW users AS
SELECT id, first_name, middle_name, last_name, school_id, created_at, auth0_id
FROM users_all
WHERE deleted_at IS NULL;

DROP FUNCTION get_role;

ALTER FUNCTION get_name(first text, middle text, last text) VOLATILE;