set search_path to public;

alter table
    works add constraint fk_status_works foreign key (status) references work_status (value) on delete restrict on update cascade;