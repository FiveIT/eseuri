set search_path to public;

drop function find_schools;
drop function find_work_summaries;

drop view work_summaries;
create view work_summaries as
select name, creator, type, count(work_id) work_count
from (
         select t.name                                             as name,
                get_name(a.first_name, a.middle_name, a.last_name) as creator,
                e.work_id                                          as work_id,
                'essay'                                            as type
         from titles t
                  left join authors a on t.author_id = a.id
                  left join essays e on t.id = e.title_id
         union
         select c.name             as name,
                t2.name            as creator,
                c2.work_id         as work_id,
                'characterization' as type
         from characters c
                  left join titles t2 on c.title_id = t2.id
                  left join characterizations c2 on c.id = c2.character_id
     ) as q
group by name, creator, type
order by type, creator, name;

drop function to_url;
drop function match_text;
drop function normalize_text;

drop extension fuzzystrmatch;