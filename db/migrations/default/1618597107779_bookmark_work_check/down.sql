set search_path to public;

alter table bookmarks drop constraint bookmark_approved_works;

drop function get_work_status;
