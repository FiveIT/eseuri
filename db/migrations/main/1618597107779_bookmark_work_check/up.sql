set search_path to public;

create function get_work_status(workID int) returns text stable as $$
declare workStatus text;
begin
    select status from works where id = workID into workStatus;
    return workStatus;
end;
$$ language plpgsql;

alter table bookmarks
    add constraint bookmark_approved_works check (get_work_status(work_id) = 'approved');
