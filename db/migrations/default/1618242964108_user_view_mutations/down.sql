set search_path to public;

drop trigger delete_user on users;
drop trigger update_user on users;
drop trigger insert_user on users;

drop function trigger_insert_user;
drop function trigger_update_user;

drop view users;
create view users as
select id, first_name, middle_name, last_name, get_role(id) "role", school_id, created_at, auth0_id from users_all
where deleted_at is null;

alter table users_all drop column updated_at;

drop function trigger_delete_user;
create function trigger_delete_user() returns trigger as
$$
begin
    update users_all
    set first_name  = null,
        middle_name = null,
        last_name   = null,
        school_id   = null,
        created_at  = null,
        deleted_at  = localtimestamp
    where id = old.id;
    return null;
end;
$$ language plpgsql;

create trigger delete_users before delete on users_all for each row execute function trigger_delete_user();

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