set search_path to public;

alter table bookmarks drop constraint fk_work_bookmarks;
alter table bookmarks drop constraint fk_user_bookmarks;
drop index idx_bookmarks_work;
drop index idx_bookmarks_user;
drop table bookmarks;

drop view work_summaries;
drop table work_type;
drop function get_name;

drop trigger insert_characterization on characterizations;
drop function trigger_insert_characterization;
drop trigger insert_essay on essays;
drop function trigger_insert_essay;
alter table characterizations drop constraint fk_character_characterizations;
alter table characterizations drop constraint fk_work_characterization;
drop index idx_characterizations_character;
drop table characterizations;
alter table essays drop constraint fk_title_essays;
alter table essays drop constraint fk_work_essay;
drop index idx_essays_title;
drop table essays;

drop trigger update_works_status on works;
alter table works drop constraint fk_status_works;
alter table works drop constraint fk_teacher_works;
alter table works drop constraint fk_user_works;
alter table works drop constraint unique_content;
drop index idx_works_content;
drop index idx_works_status;
drop index idx_works_review_teacher;
drop index idx_works_user;
drop table works;
drop table work_status;

alter table teacher_student_associations drop constraint fk_user_teacher_student_associations;
alter table teacher_student_associations drop constraint fk_teacher_teacher_student_associations;
alter table teacher_student_associations drop constraint fk_student_teacher_student_associations;
alter table teacher_student_associations drop constraint fk_status_teacher_student_associations;
drop index idx_teacher_student_associations_status;
drop index idx_teacher_student_associations_teacher;
drop index idx_teacher_student_associations_student;
drop index idx_teacher_student_associations_initiator;
drop table teacher_student_associations;
drop table teacher_student_association_status;

alter table teacher_requests drop constraint fk_user_teacher_request;
alter table teacher_requests drop constraint fk_status_teacher_request;
drop trigger teacher_requests_after_status_update on teacher_requests;
drop index idx_teacher_requests_status;
drop table teacher_requests;
drop table teacher_request_status;

drop trigger delete_user on users;
drop function trigger_delete_user;
drop trigger update_user on users;
drop function trigger_update_user;
drop trigger insert_user on users;
drop function trigger_insert_user;
drop view users;
drop function get_role;
drop table user_role;
drop trigger insert_teacher on teachers;
drop function trigger_insert_teacher;
drop trigger insert_student on students;
drop function trigger_insert_student;
alter table teachers drop constraint fk_user_teacher;
drop table teachers;
alter table students drop constraint fk_user_student;
drop table students;
alter table users_all drop constraint school_user;
drop index idx_users_school;
drop table users_all;

alter table characters drop constraint fk_title_character;
drop index idx_characters_title;
drop table characters;
alter table titles drop constraint fk_author_title;
drop index idx_titles_author;
drop table titles;
drop table authors;
alter table schools drop constraint county_school;
drop index idx_schools_county;
drop table schools;
drop table counties;

drop function trigger_set_updated_at;