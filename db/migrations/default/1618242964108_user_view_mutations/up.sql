set search_path to public;

drop function create_user(text, text, text, integer, text);

drop trigger delete_users on users_all;
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

alter table users_all
    add column updated_at timestamp default null;

drop view users;
create view users as
select id, first_name, middle_name, last_name, get_role(id) "role", school_id, created_at, updated_at, auth0_id from users_all
where deleted_at is null;

create function trigger_update_user() returns trigger as
$$
declare
    timespan int;
    now      timestamp := localtimestamp;
begin
    if old.updated_at is not null then
        timespan := extract(days from now - old.updated_at);
        if timespan < 60 then
            raise exception 'îți poți reactualiza contul numai după 60 de zile de la ultima actualizare';
        end if;
    end if;
    new.updated_at = now;
    update users_all
    set first_name  = new.first_name,
        middle_name = new.middle_name,
        last_name   = new.last_name,
        school_id   = new.school_id,
        updated_at  = new.updated_at
    where id = new.id;
    return new;
end;
$$ language plpgsql;

create function trigger_insert_user() returns trigger as
$$
declare
    existingUser    users;
    role            int := new.role;
begin
    -- check if the user is already in the database and was not deleted before
    select * from users where auth0_id = new.auth0_id into existingUser;
    if existingUser.created_at is not null then
        return null;
    end if;
    -- determine role to be inserted with
    if role is null then
        role := 0;
    end if;
    insert into users_all (first_name, middle_name, last_name, school_id, auth0_id)
    values (new.first_name, new.middle_name, new.last_name, new.school_id, new.auth0_id)
    on conflict on constraint users_all_auth0_id_key do update
        set first_name  = new.first_name,
            middle_name = new.middle_name,
            last_name   = new.last_name,
            school_id   = new.school_id,
            deleted_at  = null,
            updated_at  = localtimestamp,
            created_at  = localtimestamp
    returning id, first_name, middle_name, last_name, role, school_id, created_at, updated_at, auth0_id into new;
    if new.role = 1 then
        insert into students (user_id) values (new.id);
    elseif new.role = 2 then
        insert into teachers (user_id) values (new.id);
    end if;
    return new;
end;
$$ language plpgsql;

create trigger insert_user
    instead of insert
    on users
    for each row
execute function trigger_insert_user();
create trigger update_user
    instead of update
    on users
    for each row
execute function trigger_update_user();
create trigger delete_user
    instead of delete
    on users
    for each row
execute function trigger_delete_user();