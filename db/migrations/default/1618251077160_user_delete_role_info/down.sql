set search_path to public;

drop trigger delete_user on users;
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
        updated_at  = null,
        deleted_at  = localtimestamp
    where id = old.id;
    return null;
end;
$$ language plpgsql;
create trigger delete_user
    instead of delete
    on users
    for each row
execute function trigger_delete_user();