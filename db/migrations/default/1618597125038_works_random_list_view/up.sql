set search_path to public;

create domain seed as float check (value <= 1) check (value >= -1);

-- TODO: add join on works in order to check status
create function list_essays(titleID int, seed seed) returns setof essays stable as $$
begin
    perform setseed(seed);
    return query select * from essays where title_id = titleID and status = 'approved' order by random();
end;
$$ language plpgsql;

create function list_characterizations(characterID int, seed seed) returns setof characterizations stable as $$
begin
    perform setseed(seed);
    return query select * from characterizations where character_id = characterID and status = 'approved' order by random();
end;
$$ language plpgsql;
