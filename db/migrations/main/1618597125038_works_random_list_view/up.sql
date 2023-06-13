set search_path to public;

create domain seed as float check (value <= 1) check (value >= -1);

create function list_essays(titleID int, seed seed) returns setof essays stable as $$
begin
    perform setseed(seed);
    return query select work_id, title_id from essays
        left join works on work_id = id
    where title_id = titleID and status = 'approved' order by random();
end;
$$ language plpgsql;

create function list_characterizations(characterID int, seed seed) returns setof characterizations stable as $$
begin
    perform setseed(seed);
    return query select work_id, character_id from characterizations
        left join works on work_id = id
    where character_id = characterID and status = 'approved' order by random();
end;
$$ language plpgsql;
