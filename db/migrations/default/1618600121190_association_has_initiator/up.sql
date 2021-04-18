set search_path to public;

alter table teacher_student_associations
    add constraint teacher_student_association_has_initiator check (initiator_id = student_id or initiator_id = teacher_id);