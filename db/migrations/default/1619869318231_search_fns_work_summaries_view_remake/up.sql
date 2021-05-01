set search_path to public;

create extension fuzzystrmatch;

create function normalize_text(s text) returns text
    immutable strict parallel safe as
$$
begin
    s := translate(s, 'ăâîșşțţĂÂÎȘŞȚŢ', 'aaissttAAISSTT');
    s := regexp_replace(s, '[^a-z]', ' ', 'gi');
    s := trim(regexp_replace(s, '\s+', ' ', 'g'));

    return lower(s);
end;
$$ language plpgsql;

create function match_text(source text, target text, dist int) returns int
    immutable strict parallel safe as
$$
begin
    source := normalize_text(source);
    target := normalize_text(target);

    if target ~ source then
        return 0;
    end if;

    return levenshtein_less_equal(target, source, dist);
end;
$$ language plpgsql;

create function to_url(s text) returns text
    immutable strict parallel safe as
$$
begin
    return translate(normalize_text(s), ' ', '-');
end;
$$ language plpgsql;

drop view work_summaries;
create view work_summaries as
select name, to_url(name) url, creator, type, count(work_id) work_count, id
from (
         select t.id                                               as id,
                t.name                                             as name,
                get_name(a.first_name, a.middle_name, a.last_name) as creator,
                e.work_id                                          as work_id,
                w.status as status,
                'essay'                                            as type
         from titles t
                  left join authors a on t.author_id = a.id
                  left join essays e on t.id = e.title_id
                  left join works w on w.id = e.work_id
         union
         select c.id               as id,
                c.name             as name,
                t2.name            as creator,
                c2.work_id         as work_id,
                w2.status          as status,
                'characterization' as type
         from characters c
                  left join titles t2 on c.title_id = t2.id
                  left join characterizations c2 on c.id = c2.character_id
                  left join works w2 on c2.work_id = w2.id
     ) as q
where status = 'approved'
group by id, name, creator, type
order by work_count, name, creator, type;

create function find_work_summaries(query text, workType text default null, fuzziness int default 3) returns setof work_summaries
    stable as
$$
begin
    return query
        select name, url, creator, type, work_count, id
        from (select *,
                     match_text(query, w.name, fuzziness)                                             mn,
                     match_text(query, w.creator, fuzziness)                                          mc,
                     match_text(query, get_name(a.first_name, a.middle_name, a.last_name), fuzziness) ma
              from work_summaries w
                       left join characters c on w.id = c.id and w.type = 'characterization'
                       left join titles t on c.title_id = t.id
                       left join authors a on a.id = t.author_id
              where type = workType
                 or workType is null) as q
        where mn <= fuzziness
           or mc <= fuzziness
           or (ma is not null and ma <= fuzziness)
        order by mn, mc, ma nulls last;
end;
$$ language plpgsql;

create function find_schools(query text, countyCode varchar(2), fuzziness int default 10) returns setof schools
    stable strict as
$$
begin
    return query
        select id, name, short_name, county_id
        from (select *,
                     match_text(query, s.name, fuzziness)       mn,
                     match_text(query, s.short_name, fuzziness) ms
              from schools s
              where county_id = countyCode) as q
        where mn <= fuzziness
           or ms <= fuzziness
        order by mn, ms;
end;
$$ language plpgsql;