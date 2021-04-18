set search_path to public;

create domain seed as float check (value <= 1) check (value >= -1);

create function list_essays(titleID int, seed seed) returns setof essays stable as $$
begin
    perform setseed(seed);
    return query select * from essays where title_id = titleID order by random();
end;
$$ language plpgsql;

create function list_characterizations(characterID int, seed seed) returns setof characterizations stable as $$
begin
    perform setseed(seed);
    return query select * from characterizations where character_id = characterID order by random();
end;
$$ language plpgsql;