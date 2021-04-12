SET search_path TO public;

ALTER FUNCTION get_name(first text, middle text, last text) IMMUTABLE;

CREATE FUNCTION get_role(userID int) RETURNS INT STABLE AS $$
BEGIN
    IF exists(SELECT 1 FROM students WHERE user_id = userID) THEN
        RETURN 1;
    ELSEIF exists(SELECT 1 FROM teachers WHERE user_id = userID) THEN
        RETURN 2;
    END IF;
    RETURN 0;
end;
$$ LANGUAGE plpgsql;

DROP VIEW users;
CREATE VIEW users AS
SELECT id, first_name, middle_name, last_name, get_role(id) "role", school_id, created_at, auth0_id FROM users_all
WHERE deleted_at IS NULL;

CREATE FUNCTION create_user(firstName text, middleName text, lastName text, schoolID int, auth0ID text)
RETURNS SETOF users AS $$
DECLARE existingUser users;
BEGIN
    SELECT * FROM users WHERE auth0_id = auth0ID INTO existingUser;
    IF existingUser.created_at IS NOT NULL THEN
        RETURN NEXT existingUser;
    ELSE
        RETURN QUERY
        INSERT INTO users_all (first_name, middle_name, last_name, school_id, auth0_id)
        VALUES (firstName, middleName, lastName, schoolID, auth0ID)
        ON CONFLICT ON CONSTRAINT users_all_auth0_id_key DO UPDATE SET
            first_name = firstName,
            middle_name = middleName,
            last_name = lastName,
            school_id = schoolID,
            deleted_at = null,
            created_at = localtimestamp
        RETURNING id, first_name, middle_name, last_name, 0, school_id, created_at, auth0_id;
    END IF;
END;
$$ LANGUAGE plpgsql;