set search_path to public;

alter table teacher_student_associations drop constraint association_parties_are_registered;
alter table teacher_requests drop constraint teacher_request_user_is_registered;
alter table works drop constraint work_user_is_registered;

drop function is_registered_user;