set search_path to public;

create function is_registered_user(userID int) returns bool stable as $$
declare updatedAt timestamp;
begin
    select updated_at from users_all where id = userID into updatedAt;
    return updatedAt is not null;
end;
$$ language plpgsql;

alter table works add constraint work_user_is_registered check (is_registered_user(user_id));

alter table teacher_requests add constraint teacher_request_user_is_registered check (is_registered_user(user_id));

alter table teacher_student_associations add constraint association_parties_are_registered check (is_registered_user(student_id) and is_registered_user(teacher_id));