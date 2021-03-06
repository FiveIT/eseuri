create schema if not exists public;
set search_path to public;

create function trigger_set_updated_at() returns trigger as
$$
begin
    new.updated_at = localtimestamp;
    return new;
end;
$$ language plpgsql;


-- metadata tables

create table counties
(
    id   varchar(2) primary key,
    name text unique not null
);


create table schools
(
    id         serial primary key,
    name       text       not null,
    short_name text default null,
    county_id  varchar(2) not null
);

create index idx_schools_county on schools (county_id);

alter table schools
    add constraint county_school foreign key (county_id) references counties (id) on delete restrict on update cascade;


create table authors
(
    id          serial primary key,
    first_name  text not null,
    middle_name text default null,
    last_name   text default null
);

create table titles
(
    id        serial primary key,
    name      text not null,
    author_id int  not null
);

create index idx_titles_author on titles (author_id);

alter table titles
    add constraint fk_author_title foreign key (author_id) references authors (id) on delete restrict on update cascade;


create table characters
(
    id       serial primary key,
    name     text not null,
    title_id int  not null
);

create index idx_characters_title on characters (title_id);

alter table characters
    add constraint fk_title_character foreign key (title_id) references titles (id) on delete restrict on update cascade;


-- users tables, triggers, views, and functions

create extension citext;
create domain email as citext
    check (value ~
           '^[a-zA-Z0-9.!#$%&''''*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$');

create table users_all
(
    id          serial primary key,
    first_name  text
        constraint registered_user_first_name check (updated_at is null or first_name is not null and first_name <> ''),
    middle_name text
        constraint registered_user_middle_name check (middle_name <> ''),
    last_name   text
        constraint registered_user_last_name check (updated_at is null or last_name is not null and last_name <> ''),
    email       email
        constraint users_all_email_key check (deleted_at is not null or email is not null) unique,
    school_id   int
        constraint registered_user_school check (updated_at is null or school_id is not null),
    created_at  timestamp default (localtimestamp),
    updated_at  timestamp default null,
    deleted_at  timestamp default null,
    auth0_id    text not null
        constraint users_all_auth0_id_key unique
);

create index idx_users_school on users_all (school_id);

alter table users_all
    add constraint school_user foreign key (school_id) references schools (id) on delete restrict on update cascade;

create table students
(
    user_id int primary key
);

alter table students
    add constraint fk_user_student foreign key (user_id) references users_all (id) on delete cascade on update cascade;

create table teachers
(
    user_id   int primary key,
    about     text default null,
    image_url text default null
);

alter table teachers
    add constraint fk_user_teacher foreign key (user_id) references users_all (id) on delete cascade on update cascade;

create function trigger_insert_student() returns trigger as
$$
begin
    if exists(select 1 from teachers where user_id = new.user_id) then
        raise exception 'utilizatorul este deja profesor, nu poate fi ??i elev';
    end if;
    return new;
end
$$ language plpgsql;

create trigger insert_student
    before insert
    on students
    for each row
execute function trigger_insert_student();

create function trigger_insert_teacher() returns trigger as
$$
begin
    if exists(select 1 from students where user_id = new.user_id) then
        raise exception 'utilizatorul este deja elev, nu poate fi ??i profesor';
    end if;
    return new;
end
$$ language plpgsql;

create trigger insert_teacher
    before insert
    on teachers
    for each row
execute function trigger_insert_teacher();

create function get_role(userID int) returns text
    stable as
$$
begin
    if exists(select 1 from students where user_id = userID) then
        return 'student';
    elseif exists(select 1 from teachers where user_id = userID) then
        return 'teacher';
    end if;
    return null;
end;
$$ language plpgsql;

create view users as
select id,
       first_name,
       middle_name,
       last_name,
       email,
       get_role(id) as role,
       school_id,
       created_at,
       updated_at,
       auth0_id
from users_all
where deleted_at is null;

create function trigger_insert_user() returns trigger as
$$
declare
    existingUser users;
    role         text := new.role;
begin
    if role is null or role not in ('student', 'teacher') then
        role := 'student';
    end if;
    -- check if the user is already in the database and was not deleted before
    select * from users where auth0_id = new.auth0_id into existingUser;
    if existingUser.created_at is not null then
        return existingUser;
    end if;
    insert into users_all (first_name, middle_name, last_name, email, school_id, auth0_id)
    values (new.first_name, new.middle_name, new.last_name, new.email, new.school_id, new.auth0_id)
    on conflict on constraint users_all_auth0_id_key do update
        set first_name  = new.first_name,
            middle_name = new.middle_name,
            last_name   = new.last_name,
            email       = new.email,
            school_id   = new.school_id,
            deleted_at  = null,
            updated_at  = null,
            created_at  = localtimestamp
    returning id, first_name, middle_name, last_name, email, role, school_id, created_at, updated_at, auth0_id into new;
    if new.role = 'teacher' then
        insert into teachers (user_id) values (new.id);
    else
        insert into students (user_id) values (new.id);
    end if;
    return new;
end;
$$ language plpgsql;

create trigger insert_user
    instead of insert
    on users
    for each row
execute function trigger_insert_user();

create function trigger_update_user() returns trigger as
$$
begin
    new.updated_at = localtimestamp;
    update users_all
    set first_name  = new.first_name,
        middle_name = new.middle_name,
        last_name   = new.last_name,
        school_id   = new.school_id,
        updated_at  = new.updated_at
    where id = new.id;
    return new;
end
$$ language plpgsql;

create trigger update_user
    instead of update
    on users
    for each row
execute function trigger_update_user();

create function trigger_delete_user() returns trigger as
$$
begin
    update users_all
    set deleted_at  = localtimestamp,
        first_name  = null,
        middle_name = null,
        last_name   = null,
        school_id   = null,
        created_at  = null,
        updated_at  = null,
        email       = null
    where id = old.id;
    if old.role = 'teacher' then
        delete from teachers where user_id = old.id;
    else
        delete from students where user_id = old.id;
    end if;
    return null;
end;
$$ language plpgsql;

create trigger delete_user
    instead of delete
    on users
    for each row
execute function trigger_delete_user();


-- teacher requests and teacher-student associations

create table teacher_request_status
(
    value   text primary key,
    comment text default null
);

insert into teacher_request_status (value, comment)
values ('pending', 'The request awaits review from an administrator.'),
       ('approved', 'The request was accepted, and the request initiator is now a teacher.'),
       ('rejected', 'The request was rejected, and the request initiator''s role is unchanged.');

create table teacher_requests
(
    user_id    int primary key,
    status     text      not null default 'pending',
    created_at timestamp not null default (localtimestamp),
    updated_at timestamp default null
);

create index idx_teacher_requests_status on teacher_requests (status);

create trigger teacher_requests_after_status_update
    before update
    on teacher_requests
    for each row
    when (old.status is distinct from new.status)
execute function trigger_set_updated_at();

alter table teacher_requests
    add constraint fk_status_teacher_request foreign key (status) references teacher_request_status (value) on delete restrict on update cascade;
alter table teacher_requests
    add constraint fk_user_teacher_request foreign key (user_id) references users_all (id) on delete cascade on update cascade;

create table teacher_student_association_status
(
    value   text primary key,
    comment text default null
);

insert into teacher_student_association_status (value, comment)
values ('pending', 'The request awaits approval or rejection from the user the association was request to.'),
       ('approved', 'The user requested approved the association, and is now associated with the initiator.'),
       ('rejected', 'The user requested rejected the association, and the association status is unchanged.');

create table teacher_student_associations
(
    teacher_id   int  not null,
    student_id   int  not null,
    initiator_id int  not null,
    status       text not null default 'pending',
    primary key (student_id, teacher_id)
);

create index idx_teacher_student_associations_initiator on teacher_student_associations (initiator_id);
create index idx_teacher_student_associations_student on teacher_student_associations (student_id);
create index idx_teacher_student_associations_teacher on teacher_student_associations (teacher_id);
create index idx_teacher_student_associations_status on teacher_student_associations (status);

alter table teacher_student_associations
    add constraint fk_status_teacher_student_associations foreign key (status) references teacher_student_association_status (value) on delete restrict on update cascade;
alter table teacher_student_associations
    add constraint fk_student_teacher_student_associations foreign key (student_id) references students (user_id) on delete cascade on update cascade;
alter table teacher_student_associations
    add constraint fk_teacher_teacher_student_associations foreign key (teacher_id) references teachers (user_id) on delete cascade on update cascade;
alter table teacher_student_associations
    add constraint fk_user_teacher_student_associations foreign key (initiator_id) references users_all (id) on delete cascade on update cascade;


-- works, essays, and characterizations

create table work_status
(
    value   text primary key,
    comment text default null
);

insert into work_status (value, comment)
values ('draft', 'The work is in progress, and not ready for review.'),
       ('pending',
        'The work is done and awaits a teacher''s review. A teacher may also have been specifically requested for review at this stage.'),
       ('inReview', 'The work is currently reviewed by a teacher.'),
       ('approved', 'A teacher approved the work for publishing. The work is now visible to everyone.'),
       ('rejected', 'A teacher found the work unsuitable for publishing. The work isn''t visible to the public.');

create table works
(
    id         serial primary key,
    user_id    int       not null,
    teacher_id int default null,
    status     text      not null default 'draft',
    content    text      not null,
    created_at timestamp not null default (localtimestamp),
    updated_at timestamp default null
);

create index idx_works_user on works (user_id);
create index idx_works_review_teacher on works (teacher_id);
create index idx_works_status on works (status);
-- hash-based unique index for content
create index idx_works_content on works using hash (content);
alter table works
    add constraint unique_content exclude using hash (content with =);

alter table works
    add constraint fk_user_works foreign key (user_id) references users_all (id) on delete set null on update cascade;
alter table works
    add constraint fk_teacher_works foreign key (teacher_id) references teachers (user_id) on delete set null on update cascade;
alter table works
    add constraint fk_status_works foreign key (status) references work_status (value) on delete restrict on update cascade;

create trigger update_works_status
    before update
    on works
    for each row
    when (old.status is distinct from new.status)
execute function trigger_set_updated_at();


create table essays
(
    work_id  int primary key,
    title_id int not null
);

create index idx_essays_title on essays (title_id);

alter table essays
    add constraint fk_work_essay foreign key (work_id) references works (id) on delete cascade on update cascade;
alter table essays
    add constraint fk_title_essays foreign key (title_id) references titles (id) on delete restrict on update cascade;


create table characterizations
(
    work_id      int primary key,
    character_id int not null
);

create index idx_characterizations_character on characterizations (character_id);

alter table characterizations
    add constraint fk_work_characterization foreign key (work_id) references works (id) on delete cascade on update cascade;
alter table characterizations
    add constraint fk_character_characterizations foreign key (character_id) references characters (id) on delete restrict on update cascade;


create function trigger_insert_essay() returns trigger as
$$
begin
    if exists(select 1 from characterizations where work_id = new.work_id) then
        raise exception 'lucrarea este deja o caracterizare, nu poate fi ??i un eseu';
    end if;
    return new;
end;
$$ language plpgsql;

create trigger insert_essay
    before insert
    on essays
    for each row
execute function trigger_insert_essay();

create function trigger_insert_characterization() returns trigger as
$$
begin
    if exists(select 1 from essays where work_id = new.work_id) then
        raise exception 'lucrarea este deja un eseu, nu poate fi ??i o caracterizare';
    end if;
    return new;
end;
$$ language plpgsql;

create trigger insert_characterization
    before insert
    on characterizations
    for each row
execute function trigger_insert_characterization();


create function get_name(first text, middle text, last text) returns text
    immutable as
$$
begin
    if middle is null then
        return first || ' ' || last;
    end if;
    return first || ' ' || middle || ' ' || last;
end
$$ language plpgsql;

create table work_type
(
    value text primary key
);

insert into work_type (value)
values ('essay'),
       ('characterization');

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


-- bookmarks

create table bookmarks
(
    user_id int  not null,
    work_id int  not null,
    name    text not null,
    created_at timestamp not null default (localtimestamp),
    primary key (user_id, work_id)
);

create index idx_bookmarks_user on bookmarks (user_id);
create index idx_bookmarks_work on bookmarks (work_id);

alter table bookmarks
    add constraint fk_user_bookmarks foreign key (user_id) references users_all (id) on delete cascade on update cascade;
alter table bookmarks
    add constraint fk_work_bookmarks foreign key (work_id) references works (id) on delete cascade on update cascade;


-- load metadata
INSERT INTO "counties" ("id", "name")
VALUES ('AB', 'Alba');
INSERT INTO "counties" ("id", "name")
VALUES ('AG', 'Arge??');
INSERT INTO "counties" ("id", "name")
VALUES ('AR', 'Arad');
INSERT INTO "counties" ("id", "name")
VALUES ('B', 'Bucure??ti');
INSERT INTO "counties" ("id", "name")
VALUES ('BC', 'Bac??u');
INSERT INTO "counties" ("id", "name")
VALUES ('BH', 'Bihor');
INSERT INTO "counties" ("id", "name")
VALUES ('BN', 'Bistri??a-N??s??ud');
INSERT INTO "counties" ("id", "name")
VALUES ('BR', 'Br??ila');
INSERT INTO "counties" ("id", "name")
VALUES ('BT', 'Boto??ani');
INSERT INTO "counties" ("id", "name")
VALUES ('BV', 'Bra??ov');
INSERT INTO "counties" ("id", "name")
VALUES ('BZ', 'Buz??u');
INSERT INTO "counties" ("id", "name")
VALUES ('CJ', 'Cluj');
INSERT INTO "counties" ("id", "name")
VALUES ('CL', 'C??l??ra??i');
INSERT INTO "counties" ("id", "name")
VALUES ('CS', 'Cara??-Severin');
INSERT INTO "counties" ("id", "name")
VALUES ('CT', 'Constan??a');
INSERT INTO "counties" ("id", "name")
VALUES ('CV', 'Covasna');
INSERT INTO "counties" ("id", "name")
VALUES ('DB', 'D??mbovi??a');
INSERT INTO "counties" ("id", "name")
VALUES ('DJ', 'Dolj');
INSERT INTO "counties" ("id", "name")
VALUES ('GJ', 'Gorj');
INSERT INTO "counties" ("id", "name")
VALUES ('GL', 'Gala??i');
INSERT INTO "counties" ("id", "name")
VALUES ('GR', 'Giurgiu');
INSERT INTO "counties" ("id", "name")
VALUES ('HD', 'Hunedoara');
INSERT INTO "counties" ("id", "name")
VALUES ('HR', 'Harghita');
INSERT INTO "counties" ("id", "name")
VALUES ('IF', 'Ilfov');
INSERT INTO "counties" ("id", "name")
VALUES ('IL', 'Ialomi??a');
INSERT INTO "counties" ("id", "name")
VALUES ('IS', 'Ia??i');
INSERT INTO "counties" ("id", "name")
VALUES ('MH', 'Mehedin??i');
INSERT INTO "counties" ("id", "name")
VALUES ('MM', 'Maramure??');
INSERT INTO "counties" ("id", "name")
VALUES ('MS', 'Mure??');
INSERT INTO "counties" ("id", "name")
VALUES ('NT', 'Neam??');
INSERT INTO "counties" ("id", "name")
VALUES ('OT', 'Olt');
INSERT INTO "counties" ("id", "name")
VALUES ('PH', 'Prahova');
INSERT INTO "counties" ("id", "name")
VALUES ('SB', 'Sibiu');
INSERT INTO "counties" ("id", "name")
VALUES ('SJ', 'S??laj');
INSERT INTO "counties" ("id", "name")
VALUES ('SM', 'Satu Mare');
INSERT INTO "counties" ("id", "name")
VALUES ('SV', 'Suceava');
INSERT INTO "counties" ("id", "name")
VALUES ('TL', 'Tulcea');
INSERT INTO "counties" ("id", "name")
VALUES ('TM', 'Timi??');
INSERT INTO "counties" ("id", "name")
VALUES ('TR', 'Teleorman');
INSERT INTO "counties" ("id", "name")
VALUES ('VL', 'V??lcea');
INSERT INTO "counties" ("id", "name")
VALUES ('VN', 'Vrancea');
INSERT INTO "counties" ("id", "name")
VALUES ('VS', 'Vaslui');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Agricol ???Daniil Popovici Barcianu??? Sibiu', 'Col Agricol ???D.P. Barcianu??? Sibiu', 'SB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Agricol ???Dimitrie Cantemir???, Mun. Hu??i', 'Col Agr Hu??i', 'VS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Agricol ??i de Industrie Alimentar?? ???Vasile Adamachi???, Ia??i', 'Col Agr ???V. Adamachi??? Iasi', 'IS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Agricol ???Traian S??vulescu??? T??rgu Mure??', 'Col. Agr. ???T. S??vulescu??? Tg. Mure??', 'MS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul ???Alexandru Cel Bun??? Gura Humorului', 'Colegiul ???Al. Cel Bun??? Gura Humorului', 'SV');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul ???Andronic Motrescu??? R??d??u??i', 'SV');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul ???Aurel Vijoli??? F??g??ra??', 'BV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Auto ???Traian Vuia??? Tg-Jiu', 'Col Auto ???Traian Vuia??? Tg-Jiu', 'GJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Comercial ???Carol I??? Constan??a', 'Col Comercial ???Carol I??? C??a', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul ???Danubius???, Municipiul Galati', 'Col. ???Danubius??? Gl', 'GL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul de Art?? ???Carmen Sylva???, Municipiul Ploie??ti', 'Colegiul de Arta ???Carmen Sylva??? Ploiesti', 'PH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul de Art?? ???Ciprian Porumbescu??? Suceava', 'Colegiul de Art?? ???C. Porumbescu??? Suceava', 'SV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul de Arte Baia Mare', 'Col Arte Bm', 'MM');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul de Arte ???Sabin Dragoi??? Arad', 'AR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul de Industrie Alimentara ???Elena Doamna???, Localitatea Galati', 'Col. Ind. ???Elena Doamna??? Gl', 'GL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul de ??nv??????m??nt Ter??iar Nonuniversitar Usamvbt Timi??oara', 'Col. Inv. Usamvbt Timisoara', 'TM');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul de Muzic?? ???Sigismund Todu??????? Cluj-Napoca', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul de Servicii ??n Turism ???Napoca??? Cluj-Napoca', 'Colegiul de Servicii ??n Turism ???Napoca??? Cluj-N', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul de ??tiin??e ale Naturii ???Emil Racovi??????? Bra??ov', 'Colegiul ???Emil Racovi??????? Bra??ov', 'BV');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul de ??tiin??e ???Grigore Antipa??? Bra??ov', 'BV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Dobrogean ???Spiru Haret??? Tulcea', 'Colegiul ???S. Haret??? Tulcea', 'TL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Ecologic ???Prof. Univ. Dr. Alexandru Ionescu??? Pite??ti', 'Col. Ecologic Al. Ionescu Pite??ti', 'AG');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Economic Administrativ, Ia??i', 'Col Ec Adm Iasi', 'IS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Economic ???a.D. Xenopol???', 'Col. Ec. ???a.D. Xenopol???', 'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Economic Al Banatului Montan Re??i??a', 'CS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Economic ???Anghel Rugin?????, Mun. Vaslui', 'Col. Economic', 'VS');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Economic Arad', 'AR');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Economic Calarasi', 'CL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Economic ???Costin C. Kiri??escu???', 'Col. Ec. ???Costin C. Kiri??escu???', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Economic ???Delta Dun??rii??? Tulcea', 'Colegiul Economic', 'TL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Economic ???Dimitrie Cantemir??? Suceava', 'Colegiul Economic ???Dimitrie Cantemir??? Suceava', 'SV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Economic ???Dionisie Pop Martian??? Alba Iulia', 'Col. Ec. ???D.P.M.??? Alba Iulia', 'AB');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Economic ???Emanuil Gojdu??? Hunedoara', 'HD');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Economic ???Francesco Saverio Nitti??? Timi??oara', 'Col. Economic Timisoara', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Economic ???George Bari??iu??? Sibiu', 'Col Ec ???G. Bari??iu??? Sibiu', 'SB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Economic ???Gheorghe Chitu??? Craiova', 'Colegiul Gheorghe Chitu Craiova', 'DJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Economic ???Gheorghe Drago????? Satu Mare', 'Gheorghe Satu Mare', 'SM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Economic ???Hermes???', 'Col. Ec. ???Hermes???', 'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Economic ???Hermes??? Petro??ani', 'HD');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Economic ???Ion Ghica???', 'BR');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Economic ???Ion Ghica??? Bac??u', 'BC');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Economic ???Ion Ghica??? T??rgovi??te', 'DB');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Economic ???Iulian Pop??? Cluj-Napoca', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Economic Mangalia', 'Col Economic Mangalia', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Economic ???Maria Teiuleanu??? Pite??ti', 'Col. Economic Pite??ti', 'AG');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Economic ???Mihail Kogalniceanu??? Focsani', 'Col. Ec. ???M. Kogalniceanu??? Focsani', 'VN');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Economic, Mun. Rm. Valcea', 'Col Economic Rm. Valcea', 'VL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Economic Municipiul Buz??u', 'Col Economic Bz', 'BZ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Economic ???Nicolae Titulescu??? Baia Mare', 'Ce N Titulescu Bm', 'MM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Economic ???Octav Onicescu??? Botosani', 'Colegiul Economic ???O. Onicescu???', 'BT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Economic ???Partenie Cosma??? Oradea', 'Ce ???P. Cosma??? Oradea', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Economic ???Pintea Viteazul??? Cavnic', 'Ce P Viteazul Cavnic', 'MM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Economic ???Transilvania??? T??rgu Mure??', 'Col. Ec. ???Transilvania??? Tg. Mures', 'MS');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Economic ???V. Madgearu???', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Economic ???Viilor???', 'Col. Ec. ???Viilor???', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Economic ???Virgil Madgearu???, Localitatea Galati', 'Col. Ec. ???V. Madgearu??? Gl', 'GL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Economic ???Virgil Madgearu???, Municipiul Ploie??ti', 'Colegiul ???V. Madgearu??? Ploiesti', 'PH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Economic ???Virgil Madgearu??? Tg-Jiu', 'Col. Eco. ???Virgil Madgearu??? Tg-Jiu', 'GJ');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul ???Emil Negru??iu??? Turda', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Energetic, Mun. Rm. Valcea', 'Col Energetic Rm. Valcea', 'VL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul ???Ferdinand I???, Comuna M??neciu', 'Colegiul Maneciu', 'PH');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul German ???Goethe???', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul ???Gheorghe Tatarescu??? Rovinari', 'Col ???Gheorghe Tatarescu??? Rovinari', 'GJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul ???Ion Kalinderu???, Ora??ul Bu??teni', 'Colegiul ???Ion Kalinderu??? Busteni', 'PH');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul ???Mihai Eminescu??? Bac??u', 'BC');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul ???Mihai Viteazul??? Bumbesti-Jiu', 'Col. ???M. Viteazul??? Bumbesti-Jiu', 'GJ');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul ???Mihai Viteazul??? Ineu', 'AR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul ???Mihail Cantacuzino???, Ora??ul Sinaia', 'Colegiul ???M. Cantacuzino??? Sinaia', 'PH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul National ???Al. I. Cuza??? Focsani', 'Col. National ???Al. I. Cuza??? Focsani', 'VN');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul National ???Alexandru Ioan Cuza???, Localitatea Galati', 'Col. Nat. ???Al. I. Cuza??? Gl', 'GL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul National Alexandru Lahovari, Mun. Rm. Valcea', 'Cn Al. Lahovari Rm. Valcea', 'VL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul National ???a.T. Laurian??? Botosani', 'Colegiul Nat. ???a.T. Laurian??? Bt', 'BT');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul National ???Barbu Stirbei??? Calarasi', 'CL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul National ???Bethlen Gabor??? Aiud', 'Colegiul ???B.G.??? Aiud', 'AB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul National ???Calistrat Hogas???, Localitatea Tecuci', 'Col. Nat. ???C. Hogas??? Tc', 'GL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul National ???Carol I??? Craiova', 'Colegiul Carol I Craiova', 'DJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul National ???Costache Negri???, Localitatea Galati', 'Col. Nat. ???C. Negri??? Gl', 'GL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul National de Agricultura Si Economie, Localitatea Tecuci', 'C.N.a.E. Tecuci', 'GL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul National de Informatica Matei Basarab, Mun. Rm. Valcea', 'Cni M. Basarab Rm. Valcea', 'VL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul National ???Dragos Voda??? Sighetu Marmatiei', 'Cn D Voda Sighet', 'MM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul National ???Ecaterina Teodoroiu??? Tg-Jiu', 'Col. Nat. ???Ec. Teodoroiu??? Tg-Jiu', 'GJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul National ???Elena Cuza??? Craiova', 'Colegiul Elena Cuza Craiova', 'DJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul National ???Emil Botta??? Adjud', 'Col. National ???Emil Botta??? Adjud', 'VN');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul National ???Fratii Buzesti??? Craiova', 'Colegiul Fratii Buzesti Craiova', 'DJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul National ???George Cosbuc??? Motru', 'Col. Nat. ???George Cosbuc??? Motru', 'GJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul National ???Gheorghe Sincai??? Baia Mare', 'Cn G Sincai Bm', 'MM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul National ???Gib Mihaescu??? Dragasani', 'Col Gib Mihaescu Dragasani', 'VL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul National ???Grigore Ghica??? Dorohoi', 'Colegiul Nat. ???Gr. Ghica???', 'BT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul National ???Horea Closca Si Crisan??? Alba Iulia', 'Colegiul ???Hcc??? Alba Iulia', 'AB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul National ???Inochentie Micu Clain??? Blaj', 'Colegiul ???I.M. Clain??? Blaj', 'AB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul National ???Kolcsey Ferenc??? Satu Mare', 'Cn ???Kolcsey Ferenc??? Satu Mare', 'SM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul National ???Lucian Blaga??? Sebes', 'Colegiul ???L. Blaga??? Sebes', 'AB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul National ???Mihai Eminescu??? Baia Mare', 'Cn M Eminescu Bm', 'MM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul National ???Mihai Eminescu??? Botosani', 'Colegiul Nat. ???M. Eminescu??? Bt', 'BT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul National ???Mihail Kogalniceanu???, Localitatea Galati', 'Col. Nat. ???M. Kogalniceanu??? Gl', 'GL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul National Militar ???Mihai Viteazul??? Alba Iulia', 'Colmil Alba Iulia', 'AB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul National Militar ???Tudor Vladimirescu??? Craiova', 'Colegiul Tudor Vladimirescu Craiova', 'DJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul National Mircea Cel Batran, Mun. Rm. Valcea', 'Cn Mircea Cel Batrin Rm. Valcea', 'VL');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul National ???Neagoe Basarab??? Oltenita', 'CL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul National ???Nicolae Titulescu??? Craiova', 'Colegiul Nicolae Titulescu Craiova', 'DJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul National Pedagogic ???Regele Ferdinand??? Sighetu Marmatiei', 'Cnped R Ferdinand Sighet', 'MM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul National Pedagogic ???Regina Maria???, Municipiul Ploie??ti', 'Colegiul ???Regina Maria??? Ploiesti', 'PH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul National Pedagogic ???Spiru Haret??? Focsani', 'Col. Nat. Pedag. ???Spiru Haret??? Focsani', 'VN');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul National Pedagogic ???Stefan Velovan??? Craiova', 'Colegiul Stefan Velovan Craiova', 'DJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul National ???Spiru Haret???, Localitatea Tecuci', 'Col. Nat. ???S. Haret??? Tc', 'GL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul National ???Spiru Haret??? Tg-Jiu', 'Col. Nat. ???Spiru Haret??? Tg-Jiu', 'GJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul National ???Titu Maiorescu??? Aiud', 'Colegiul ???T. M??? Aiud', 'AB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul National ???Tudor Arghezi??? Tg-Carbunesti', 'Col. Nat. ???T. Arghezi??? Tg-Carbunesti', 'GJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul National ???Tudor Vladimirescu??? Tg-Jiu', 'Col. Nat. ???T. Vladimirescu??? Tg-Jiu', 'GJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul National ???Unirea??? Focsani', 'Col. National ???Unirea??? Focsani', 'VN');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul National ???Vasile Alecsandri???, Localitatea Galati', 'Col. Nat. ???V. Alecsandri??? Gl', 'GL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul National ???Vasile Lucaciu??? Baia Mare', 'Cn V Lucaciu Bm', 'MM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???Alexandru Ioan Cuza??? Alexandria', 'Cn ???Alexandru Ioan Cuza??? Alexandria', 'TR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???Alexandru Ioan Cuza???, Municipiul Ploie??ti', 'Colegiul Nat ???Al. I. Cuza??? Ploiesti', 'PH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???Alexandru Odobescu??? Pite??ti', 'Cn Al. Odobescu Pite??ti', 'AG');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???Alexandru Papiu Ilarian??? T??rgu Mure??', 'Col. Na??. ???Al. Papiu Ilarian??? Tg. Mure??', 'MS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???Alexandru Vlahu??????? Municipiul R??mnicu S??rat', 'Colegiul ???Al. Vlahu???????', 'BZ');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Na??ional ???Ana Aslan???', 'BR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???Ana Aslan??? Timi??oara', 'Col. Nat. a. Aslan Timisoara', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???Anastasescu??? Ro??iori de Vede', 'Cn ???Anastasescu??? Ro??iori de Vede', 'TR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???Andrei Mure??anu??? Bistri??a', 'Col Na?? ???a. Mure??anu??? Bistri??a', 'BN');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???Andrei Mure??anu??? Dej', 'Colegiul National ???Andrei Mure??anu??? Dej', 'CJ');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Na??ional ???Andrei ??aguna??? Bra??ov', 'BV');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Na??ional ???Aprily Lajos??? Bra??ov', 'BV');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Na??ional ???Aurel Vlaicu???', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???Avram Iancu??? C??mpeni', 'Col. ???Ai??? C??mpeni', 'AB');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Na??ional ???Avram Iancu??? ??tei', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???B.P. Hasdeu??? Municipiul Buz??u', 'Col. Nat. ???B.P. Hasdeu???', 'BZ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional B??n????ean Timi??oara', 'Col. Nat. Banatean Timisoara', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional Bilingv ???George Co??buc???', 'Col. Na??. Bilingv ???George Co??buc???', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???Calistrat Hoga?????, Municipiul Piatra-Neam??', 'Cnch, Piatra Neam??', 'NT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???Cantemir Vod?????', 'Col. Na??. ???Cantemir Vod?????', 'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Na??ional Catolic ???Sf. Iosif??? Bac??u', 'BC');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Na??ional ???C.D. Loga??? Caransebe??', 'CS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???Constantin Cantacuzino??? T??rgovi??te', 'Colegiul Na??ional ???Constantin Cantacuzino??? Tgv',
        'DB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???Constantin Carabella??? T??rgovi??te', 'Colegiul Na??ional ???Constantin Carabella??? Tgv', 'DB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???Constantin Diaconovici Loga??? Timi??oara', 'Col. Nat. C.D. Loga Timisoara', 'TM');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Na??ional ???Costache Negri??? T??rgu Ocna', 'BC');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???Costache Negruzzi???, Ia??i', 'Col ???C. Negruzzi??? Iasi', 'IS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???Cuza Vod?????, Mun. Hu??i', 'Col. Na?? Cuza Vod??', 'VS');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Na??ional de Art?? ???George Apostu??? Bac??u', 'BC');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional de Art?? ???Octav B??ncil?????, Ia??i', 'Col Nat de Arta ???O. Bancila??? Iasi', 'IS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional de Arte ???Dinu Lipatti???', 'Col. Na??. de Arte ???D. Lipatti???', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional de Arte ???Regina Maria??? Constan??a', 'Col Nat de Art?? C??a', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional de Informatic?? ???Carmen Sylva??? Petro??ani',
        'Colegiul Na??ional de Inf. ???Carmen Sylva??? Petro??ani', 'HD');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional de Informatic?? ???Gr. Moisil??? Bra??ov', 'Colegiul Na??ional de Informatic?? Bra??ov', 'BV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional de Informatic??, Municipiul Piatra-Neam??', 'Cni, Piatra Neam??', 'NT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional de Informatic?? ???Spiru Haret??? Suceava', 'Cn de Informatic?? ???Spiru Haret??? Suceava', 'SV');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Na??ional de Informatic?? ???Tudor Vianu???', 'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Na??ional de Muzic?? ???George Enescu???', 'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Na??ional ???Decebal??? Deva', 'HD');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???Diaconovici Tietz??? Re??i??a', 'Lic Diaconovici-Tietz Resita', 'CS');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Na??ional ???Dimitrie Cantemir??? One??ti', 'BC');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???Dinicu Golescu??? C??mpulung', 'Cn Dinicu Golescu C??mpulung', 'AG');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Na??ional ???Doamna Stanca??? F??g??ra??', 'BV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???Doamna Stanca??? Satu Mare', 'Cn ???Doamna Stanca??? Sm', 'SM');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Na??ional ???Dr. Ioan Me??ot????? Bra??ov', 'BV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???Drago?? Vod????? C??mpulung Moldovenesc', 'Cn ???Drago?? Vod????? C??mpulung Moldovenesc', 'SV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional Economic ???Andrei B??rseanu??? Bra??ov', 'Colegiul Na??ional Economic Bra??ov', 'BV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional Economic ???Theodor Costescu???', 'Col. Economic ???Th. Costescu???', 'MH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???Elena Cuza???', 'Col. Na??. ???Elena Cuza???', 'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Na??ional ???Elena Ghiba Birta??? Arad', 'AR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???Emanuil Gojdu??? Oradea', 'Cn E. Gojdu Oradea', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???Emil Racovi???????', 'Col. Na??. ???Emil Racovi???????', 'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Na??ional ???Emil Racovi??????? Cluj-Napoca', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???Emil Racovi???????, Ia??i', 'Col Nat ???E. Racovita??? Iasi', 'IS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???Eudoxiu Hurmuzachi??? R??d??u??i', 'Cn ???Eudoxiu Hurmuzachi??? R??d??u??i', 'SV');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Na??ional ???Ferdinand I??? Bac??u', 'BC');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???Garabet Ibr??ileanu???, Ia??i', 'Col Nat ???G. Ibraileanu??? Iasi', 'IS');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Na??ional ???George Bari??iu??? Cluj-Napoca', 'CJ');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Na??ional ???George Co??buc??? Cluj-Napoca', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???George Co??buc??? N??s??ud', 'Col Na?? ???G. Co??buc??? N??s??ud', 'BN');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???Gh. Ro??ca Codreanu???, Mun. B??rlad', 'Col. Na?? Gh. R. Codreanu', 'VS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???Gheorghe Asachi???, Municipiul Piatra-Neam??', 'Cnga, Piatra Neam??', 'NT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???Gheorghe Laz??r???', 'Col. Na??. ???Gheorghe Laz??r???', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???Gheorghe Laz??r??? Sibiu', 'Col Na?? ???Gh. Laz??r??? Sibiu', 'SB');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Na??ional ???Gheorghe Munteanu Murgoci???', 'BR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???Gheorghe ??incai???', 'Col. Na??. ???Gheorghe ??incai???', 'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Na??ional ???Gheorghe ??incai??? Cluj-Napoca', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???Gheorghe ??i??eica???', 'Col. Nat. ???G. Titeica???', 'MH');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Na??ional ???Gheorghe Vr??nceanu??? Bac??u', 'BC');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???Grigore Moisil???', 'Col. Na??. ???Grigore Moisil???', 'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Na??ional ???Grigore Moisil??? One??ti', 'BC');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Na??ional ???Iancu de Hunedoara??? Hunedoara', 'HD');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional, Ia??i', 'Col National Iasi', 'IS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???Ien??chi???? V??c??rescu??? T??rgovi??te', 'Colegiul Na??ional ???Ien??chi???? V??c??rescu??? T??rgovi??t',
        'DB');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Na??ional ???I.L. Caragiale???', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???Ioan Slavici??? Satu Mare', 'Cn I. Slavici', 'SM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???Ion C. Br??tianu??? Pite??ti', 'Cn I.C. Br??tianu Pite??ti', 'AG');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???Ion Creang?????', 'Col. Na??. ???Ion Creang?????', 'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Na??ional ???Ion Luca Caragiale??? Moreni', 'DB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???Ion Luca Caragiale???, Municipiul Ploie??ti', 'Colegiul ???Il. Caragiale??? Ploiesti', 'PH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???Ion Maiorescu??? Giurgiu', 'Col. Nat. ???Ion Maiorescu???', 'GR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???Ion Minulescu??? Slatina', 'Colegiu Nat ???I. Minulescu??? Slatina', 'OT');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Na??ional ???Ion Neculce???', 'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Na??ional ???Iosif Vulcan??? Oradea', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???Iulia Ha??deu???', 'Col. Na??. ???Iulia Ha??deu???', 'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Na??ional ???Johannes Honterus??? Bra??ov', 'BV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???Kemal Ataturk??? Medgidia', 'Col Na??ional ???Kemal Ataturk??? Medgidia', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???Liviu Rebreanu??? Bistri??a', 'Col Na?? ???L. Rebreanu??? Bistri??a', 'BN');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???M??rton ??ron??? Miercurea Ciuc', 'Cn ???Marton Aron??? Miercurea Ciuc', 'HR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???Matei Basarab???', 'Col. Na??. ???Matei Basarab???', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???Mihai Eminescu???', 'Col. Na??. ???Mihai Eminescu???', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???Mihai Eminescu??? Constan??a', 'Col Na??ional ???Mihai Eminescu??? C??a', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???Mihai Eminescu???, Ia??i', 'Col Nat ???M. Eminescu??? Iasi', 'IS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???Mihai Eminescu??? Municipiul Buz??u', 'Colegiul ???M. Eminescu???', 'BZ');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Na??ional ???Mihai Eminescu??? Oradea', 'BH');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Na??ional ???Mihai Eminescu??? Petro??ani', 'HD');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???Mihai Eminescu??? Satu Mare', 'Cn Mihai Eminescu Sm', 'SM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???Mihai Eminescu??? Suceava', 'Cn ???Mihai Eminescu??? Suceava', 'SV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???Mihai Eminescu??? Topli??a', 'Cn ???Mihai Eminescu??? Toplita', 'HR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???Mihai Viteazul???', 'Col. Na??. ???Mihai Viteazul???', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???Mihai Viteazul???, Municipiul Ploie??ti', 'Colegiul ???M. Viteazul??? Ploiesti', 'PH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???Mihai Viteazul??? Sf??ntu Gheorghe', 'Col. Na??. ???Mihai Viteazul??? Sf??ntu Gheorghe', 'CV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???Mihai Viteazul??? Slobozia', 'Colegiul Na??. ???Mihai Viteazul??? Slobozia', 'IL');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Na??ional ???Mihai Viteazul??? Turda', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???Mihail Sadoveanu???, Pa??cani', 'Col Nat ???M. Sadoveanu??? Pascani', 'IS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional Militar ???Alexandru Ioan Cuza??? Constan??a', 'Cnmil a I Cuza', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional Militar ???Dimitrie Cantemir??? Breaza', 'Colegiul Mil. ???D. Cantemir??? Breaza', 'PH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional Militar ?????tefan Cel Mare??? C??mpulung Moldovenesc',
        'Cn Militar ?????t. Cel Mare??? C??mpulung Moldovenesc', 'SV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???Mircea Cel B??tr??n??? Constan??a', 'Col Na??ional ???Mircea Cel Batran??? C??a', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???Mircea Eliade??? Re??i??a', 'Colegiul Mircea Eliade Resita', 'CS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???Mircea Eliade??? Sighi??oara', 'Col. Na??. ???M. Eliade??? Sighisoara', 'MS');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Na??ional ???Moise Nicoar????? Arad', 'AR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???Nichita St??nescu???, Municipiul Ploie??ti', 'Colegiul ???Nichita Stanescu??? Ploiesti', 'PH');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Na??ional ???Nicolae B??lcescu???', 'BR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???Nicolae Grigorescu???, Municipiul C??mpina', 'Colegiul ???N. Grigorescu??? Cimpina', 'PH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???Nicolae Iorga???, Ora??ul V??lenii de Munte', 'Colegiul ???N. Iorga??? Valenii de M.', 'PH');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Na??ional ???Nicolae Titulescu??? Pucioasa', 'DB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???Nicu Gane??? F??lticeni', 'Cn ???Nicu Gane??? F??lticeni', 'SV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???Octav Onicescu???', 'Col. Na??. ???Octav Onicescu???', 'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Na??ional ???Octavian Goga??? Marghita', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???Octavian Goga??? Miercurea Ciuc', 'Cn ???Octavian Goga??? Miercurea Ciuc', 'HR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???Octavian Goga??? Sibiu', 'Col Na?? ???O. Goga??? Sibiu', 'SB');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Na??ional ???Onisifor Ghibu??? Oradea', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional Pedagogic ???Andrei ??aguna??? Sibiu', 'Col Na?? Pedagogic ???a. ??aguna??? Sibiu', 'SB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional Pedagogic ???Carmen Sylva??? Timi??oara', 'Col. Ped ???Carmen Sylva??? Timisoara', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional Pedagogic ???Carol I??? C??mpulung', 'Cn Ped. Carol I C??mpulung', 'AG');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional Pedagogic ???Constantin Br??tescu??? Constan??a',
        'Col Na??ional Pedagogic ???Constantin Br??tescu??? C??a', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional Pedagogic ???Dumitru Panaitescu Perpessicius???',
        'Colegiul Na??ional Pedagogic ???D.P. Perpessicius???', 'BR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional Pedagogic ???Gheorghe Laz??r??? Cluj-Napoca', 'Colegiul Na??ional Pedagogic ???Gheorghe Laz??r??? Cluj',
        'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional Pedagogic ???Mihai Eminescu??? T??rgu Mure??', 'Col. Na??. Ped. ???M. Eminescu??? Tg. Mure??', 'MS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional Pedagogic ???Mircea Scarlat??? Alexandria', 'Cnp ???Mircea Scarlat??? Alexandria', 'TR');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Na??ional Pedagogic ???Regina Maria??? Deva', 'HD');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional Pedagogic ???Spiru Haret??? Municipiul Buz??u', 'Col. Pedagogic ???S. Haret???', 'BZ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional Pedagogic ?????tefan Cel Mare??? Bac??u', 'Col. Pedag. ??tefan Cel Mare Bac??u', 'BC');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional Pedagogic ?????tefan Odobleja???', 'Col. Nat. Peda. ???St. Odobleja???', 'MH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???Petru Rare????? Beclean', 'Col Na?? ???P. Rare????? Beclean', 'BN');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???Petru Rare?????, Municipiul Piatra-Neam??', 'Cnpr, Piatra Neam??', 'NT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???Petru Rare????? Suceava', 'Cn ???Petru Rare????? Suceava', 'SV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???Preparandia-Dimitrie ??ichindeal??? Arad',
        'Colegiul Na??ional ???Preparandia-D. ??ichindeal??? Arad', 'AR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???Radu Greceanu??? Slatina', 'Colegiul Nat. ???R. Greceanu??? Slatina', 'OT');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Na??ional ???Radu Negru??? F??g??ra??', 'BV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???Roman Vod?????, Municipiul Roman', 'Cnrv, Roman', 'NT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???Samuel Von Brukenthal??? Sibiu', 'Col Na?? ???Samuel Von Brukenthal??? Sibiu', 'SB');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Na??ional ???Samuil Vulcan??? Beiu??', 'BH');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Na??ional ???Sf??ntul Sava???', 'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Na??ional ???Silvania??? Zal??u', 'SJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???Simion B??rnu??iu??? ??imleu Silvaniei', 'Colegiul Na??ional ???S. B??rnu??iu??? ??imleu Silvaniei',
        'SJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???Spiru Haret???', 'Col. Na??. ???Spiru Haret???', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???Sz??kely Mik????? Sf??ntu Gheorghe', 'Col. Na??. ???Sz??kely Mik????? Sf??ntu Gheorghe', 'CV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ?????coala Central?????', '??coala Central??', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ?????tefan Cel Mare???, H??rl??u', 'Col Nat ???Stefan Cel Mare??? Harlau', 'IS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ?????tefan Cel Mare???, Ora?? T??rgu Neam??', 'Cn ?????tefan Cel Mare???, T??rgu Neam??', 'NT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ?????tefan Cel Mare??? Suceava', 'Cn ???Stefan Cel Mare??? Suceava', 'SV');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Na??ional ???Teodor Ne????? Salonta', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???Traian???', 'Col. ???Traian???', 'MH');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Na??ional ???Traian Doda??? Caransebe??', 'CS');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Na??ional ???Traian Lalescu??? Re??i??a', 'CS');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Na??ional ???Unirea??? Bra??ov', 'BV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???Unirea??? T??rgu Mure??', 'Col. Na??. ???Unirea??? Tg. Mure??', 'MS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???Unirea??? Turnu M??gurele', 'Cn ???Unirea??? Turnu M??gurele', 'TR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???Vasile Alecsandri??? Bac??u', 'Colegiul Na??ional ???V. Alecsandri??? Bacau', 'BC');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Na??ional ???Vasile Goldi????? Arad', 'AR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???Victor Babe?????', 'Col. Na??. ???Victor Babe?????', 'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Na??ional ???Vladimir Streinu??? G??e??ti', 'DB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???Vlaicu Vod????? Curtea de Arge??', 'Cn Vlaicu Vod?? Curtea de Arge??', 'AG');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???Zinca Golescu??? Pite??ti', 'Cn Zinca Golescu Pite??ti', 'AG');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Na??ional ???Grigore Moisil??? Urziceni', 'Colegiul Na??. ???Grigore Moisil??? Urziceni', 'IL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul ???Nicolae Paulescu??? Municipiul Rm. S??rat', 'Col N Paulescu Rms', 'BZ');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul ???Nicolae Titulescu??? Bra??ov', 'BV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul N.V. Bac??u', 'Col. N.V. Bac??u', 'BC');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Particular ???Vasile Goldi????? Arad', 'AR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Pedagogic ???Vasile Lupu???, Ia??i', 'Col Pedagogic Iasi', 'IS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Pentru Agricultur?? ??i Industrie Alimentar?? ?????ara B??rsei??? Prejmer', 'Colegiul Prejmer', 'BV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Reformat ???Baczkamadarasi Kis Gergely??? Odorheiu Secuiesc', 'Ste Reformat Odorhei', 'HR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul ???Richard Wurmbrand???, Iasi', 'Crw', 'IS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Romano-Catolic ???Sf??ntul Iosif???', 'Col. Rom. Cat. ???Sf. Iosif???', 'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Silvic ???Bucovina??? C??mpulung Moldovenesc', 'SV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Silvic ???Theodor Pietraru??? Br??ne??ti', 'Colegiul Silvic ???Theodor Pietraru??? Branesti', 'IF');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul ???Spiru Haret???, Municipiul Ploie??ti', 'Colegiul ???Spiru Haret??? Ploiesti', 'PH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul ?????coala Na??ional?? de Gaz??? Media??', 'Col Sng Media??', 'SB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic ???Alesandru Papiu Ilarian??? Zal??u', 'Colegiul Tehnic ???a.P. Ilarian??? Zal??u', 'SJ');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Tehnic ???Alexandru Ioan Cuza??? Suceava', 'SV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic ???Alexandru Roman??? Ale??d', 'Ct ???Alexandru Roman??? Ale??d', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic ???Ana Aslan??? Cluj-Napoca', 'Col. Tehn. Ana Ex.', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic ???Anghel Saligny???', 'Col. Tehn. ???Anghel Saligny???', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic ???Anghel Saligny??? Baia Mare', 'Ct a Saligny Bm', 'MM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic ???Anghel Saligny??? Cluj-Napoca', 'Colegiul Tehnic de Constructii ???Anghel Saligny???', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic ???Apulum??? Alba Iulia', 'Ct ???Apulum??? Alba Iulia', 'AB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic ???Armand C??linescu??? Pite??ti', 'Col. Teh. Armand C??linescu Pite??ti', 'AG');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic ???August Treboniu Laurian??? Agnita', 'Col Tehn ???a.T. Laurian??? Agnita', 'SB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic ???Aurel Vlaicu??? Baia Mare', 'Ct a Vlaicu Bm', 'MM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic Auto ???Traian Vuia??? Focsani', 'Col. Tehn. Auto ???Traian Vuia??? Focsani', 'VN');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic ???Batthy??ny Ign??c??? Gheorgheni', 'Col ???Batthyany Ignac??? Gheorgheni', 'HR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic ???Carol I???', 'Col. Teh. ???Carol I???', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic C??mpulung', 'Col. Teh. C??mpulung', 'AG');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic ???Cd Nenitescu??? Baia Mare', 'Ct Cd Nenitescu Bm', 'MM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic ???Cibinium??? Sibiu', 'Col Tehn ???Cibinium??? Sibiu', 'SB');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Tehnic ???Constantin Br??ncu??i??? Petrila', 'HD');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic ???Costin D. Neni??escu???', 'Col. Tehn. ???C.D. Neni??escu???', 'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Tehnic ???Costin D. Neni??escu???', 'BR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic ???Costin D. Neni??escu??? Pite??ti', 'Col. Teh. C.D. Neni??escu Pite??ti', 'AG');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic ???Danubiana???, Municipiul Roman', 'Ctd, Roman', 'NT');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Tehnic de Aeronautic?? ???Henri Coand?????', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic de Arhitectur?? ??i Lucr??ri Publice ???Ioan N. Socolescu???', 'Colegiul Tehnic ???Ioan N. Socolescu???',
        'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic de C??i Ferate ???Unirea???, Pa??cani', 'Col Teh ???Unirea??? Pascani', 'IS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic de Comunica??ii ???Augustin Maior??? Cluj-Napoca', 'Colegiul Tehnic ???Augustin Maior??? Cluj', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic de Industrie Alimentar?? ???Dumitru Mo??oc???', 'Col. Teh. de Ind. Alim. ???Dumitru Mo??oc???', 'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Tehnic de Industrie Alimentar?? Suceava', 'SV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic de Po??t?? ??i Telecomunica??ii ???Gheorghe Airinei???', 'Col. Teh. de Po??t?? ??i Tc. ???Gh. Airinei???',
        'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Tehnic de Transporturi Bra??ov', 'BV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic de Transporturi, Municipiul Piatra-Neam??', 'Ctt, Piatra Neam??', 'NT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic de Transporturi ???Transilvania??? Cluj-Napoca', 'Colegiul Tehnic de Transporturi ???Transilvania???',
        'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic ???Dimitrie Ghika??? Com??ne??ti', 'Colegiul Tehnic ???D. Ghika??? Com??ne??ti', 'BC');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic ???Dimitrie Leonida???', 'Col. Tehn. ???Dimitrie Leonida???', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic ???Dinicu Golescu???', 'Col. Teh. ???Dinicu Golescu???', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic ???Dr. Alexandru B??rbat??? Victoria', 'Colegiul Tehnic Victoria', 'BV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic ???Edmond Nicolau???', 'Col. Tehn. ???Edmond Nicolau???', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic ???Edmond Nicolau??? Focsani', 'Col. Tehn. ???Edmond Nicolau??? Focsani', 'VN');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic ???Emanuil Ungureanu??? Timi??oara', 'Col. Teh. ???E. Ungureanu??? Timisoara', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic Energetic', 'Col. Teh. Energetic', 'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Tehnic Energetic Cluj-Napoca', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic Energetic ???Remus R??dule????? Bra??ov', 'Colegiul Tehnic ???Remus R??dule????? Bra??ov', 'BV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic Energetic Sibiu', 'Col Teh Energetic Sibiu', 'SB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic Feroviar ???Mihai I???', 'Col. Tehn. Feroviar ???Mihai I???', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic Forestier, Municipiul C??mpina', 'Colegiul Tehnic Forestier Campina', 'PH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic Forestier, Municipiul Piatra-Neam??', 'Ctf, Piatra Neam??', 'NT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic ???George Baritiu??? Baia Mare', 'Ct G Baritiu Bm', 'MM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic ???Gheorghe Asachi???', 'Col. Teh. ???Gh. Asachi???', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic ???Gheorghe Asachi??? Botosani', 'Col. Teh. ???Gheorghe Asachi???', 'BT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic ???Gheorghe Asachi??? Focsani', 'Col. Tehn. ???Gh. Asachi??? Focsani', 'VN');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic ???Gheorghe Asachi???, Ia??i', 'Col Teh ???Gh. Asachi??? Iasi', 'IS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic ???Gheorghe Asachi??? One??ti', 'Colegiul Tehnic ???Gh. Asachi??? One??ti', 'BC');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic ???Gheorghe Bals??? Adjud', 'Col. Tehn. ???Gheorghe Bals??? Adjud', 'VN');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic ???Gheorghe Cartianu???, Municipiul Piatra-Neam??', 'Ctgc, Piatra Neam??', 'NT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic ???G-Ral Gheorghe Magheru??? Tg-Jiu', 'Col Tehnic ???G-Ral Gh. Magheru??? Tg-Jiu', 'GJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic ???Grigore Cob??lcescu??? Moine??ti', 'Col. Teh. Gr. Moine??ti', 'BC');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic ???Henri Coanda??? Tg-Jiu', 'Col. Tehnic ???H. Coanda??? Tg-Jiu', 'GJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic ???Henri Coand????? Timi??oara', 'Col. Teh. ???H. Coanda??? Timisoara', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic ???Infoel??? Bistri??a', 'Col Teh ???Infoel??? Bistri??a', 'BN');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic ???Ioan C. ??tef??nescu???, Ia??i', 'Col Teh ???I.C. Stefanescu??? Iasi', 'IS');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Tehnic ???Ioan Ciorda????? Beiu??', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic ???Ion Creang?????, Ora?? T??rgu Neam??', 'Ctic, T??rgu Neam??', 'NT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic ???Ion D. Lazarescu??? Cugir', 'Colegiul ???I.D.L.??? Cugir', 'AB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic ???Ion Holban???, Ia??i', 'Col Teh ???Ion Holban??? Iasi', 'IS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic ???Ion Mincu??? Focsani', 'Col. Tehn. ???Ion Mincu??? Focsani', 'VN');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Tehnic ???Ion Mincu??? Tg-Jiu', 'GJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic ???Iuliu Maniu???', 'Col. Teh. ???Iuliu Maniu???', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic ???Iuliu Maniu??? ??imleu Silvaniei', 'Colegiul Tehnic ???I. Maniu??? ??imleu Silvaniei', 'SJ');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Tehnic ???La??cu Vod????? Siret', 'SV');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Tehnic ???Maria Baiulescu??? Bra??ov', 'BV');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Tehnic Matasari', 'GJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic Mecanic ???Grivi??a???', 'Col. Tehn. Mec. ???Grivi??a???', 'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Tehnic ???Media???', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic ???Mediensis??? Media??', 'Col Teh ???Mediensis??? Media??', 'SB');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Tehnic ???Mihai B??cescu??? F??lticeni', 'SV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic ???Mihai Bravu???', 'Col. Tehn. ???Mihai Bravu???', 'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Tehnic ???Mihai Viteazul??? Oradea', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic ???Mihail Sturdza???, Ia??i', 'Col Teh ???M. Sturdza??? Iasi', 'IS');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Tehnic ???Mircea Cel B??tr??n???', 'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Tehnic ???Mircea Cristea??? Bra??ov', 'BV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic ???Miron Costin???, Municipiul Roman', 'Ctmc, Roman', 'NT');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Tehnic Motru', 'GJ');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Tehnic Nr 2 Tg-Jiu', 'GJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic Nr. 1 Vadu Cri??ului', 'Ct Nr. 1 Vadu Cri??ului', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic ???Petru Maior???', 'Col. Teh. ???Petru Maior???', 'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Tehnic ???Petru Mu??at??? Suceava', 'SV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic ???Petru Poni???, Municipiul Roman', 'Ctpp, Roman', 'NT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic ???Raluca Ripan??? Cluj-Napoca', 'Colegiul Tehnic ???Raluca Ripan??? Cluj', 'CJ');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Tehnic R??d??u??i', 'SV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic Re??i??a', 'Colegiul Tehnic Resita', 'CS');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Tehnic ???Samuil Isopescu??? Suceava', 'SV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic ???Simion Mehedin??i??? Codlea', 'Colegiul Tehnic Codlea', 'BV');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Tehnic ???Traian Vuia??? Oradea', 'BH');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Tehnic ???Transilvania??? Bra??ov', 'BV');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Tehnic Turda', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic ???Valeriu D. Cotea??? Focsani', 'Col. Tehn. ???Valeriu D. Cotea??? Focsani', 'VN');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic ???Viceamiral Ioan B??l??nescu??? Giurgiu', 'Col. Teh. ???Viceamiral Ioan B??l??nescu???', 'GR');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Tehnic ???Victor Ungureanu??? C??mpia Turzii', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnologic ???Constantin Br??ncoveanu???', 'C.Teh. ???C. Brincoveanu???', 'MH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnologic ???Grigore Cerchez???', 'Col. Tehn. ???Grigore Cerchez???', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnologic ???Spiru Haret???, Municipiul Piatra-Neam??', 'Ctsh, Piatra Neam??', 'NT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnologic ???Viaceslav Harnaj???', 'Col. Tehn. ???V. Harnaj???', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Ter??iar Nonuniversitar', 'Upet', 'HD');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Ter??iar Usamvb', 'Colegiul Usamvb', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Ter??iar Nonuniversitar ???Eftimie Murgu??? Re??i??a', 'Colegiul Ter??iar Nonuniversitar', 'CS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Ter??iar Nonuniversitar Pite??ti', 'Col. Ter??iar Pite??ti', 'AG');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Ter??iar Nonuniversitar-Usamvb', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Ucecom ???Spiru Haret???', 'Col. Ucecom ???Spiru Haret???', 'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Universitar Spiru Haret', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Universitar ???Spiru Haret??? Craiova', 'Colegiul Universitar Craiova', 'DJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Universit????ii ???Hyperion???', 'Colegiul ???Hyperion???', 'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul ???Vasile Lovinescu??? F??lticeni', 'SV');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul ???Csiky Gergely??? Arad', 'AR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Agricol ???Dr. C. Angelescu??? Municipiul Buz??u', 'Lic Agr Angelescu', 'BZ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Agricol Poarta Alb??', 'Lic Agricol Poarta Alb??', 'CT');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul ???Alexandru Cel Bun??? Botosani', 'BT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul ???Alexandru Odobescu??? Lehliu Gara', 'Lic. ???Al. Odobescu??? Lehliu Gara', 'CL');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul ???Andrei Mure??anu??? Bra??ov', 'BV');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul ???Atanasie Marienescu??? Lipova', 'AR');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul ???Aurel Rainu??? Fieni', 'DB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul B??n????ean O??elu Ro??u', 'Lic B??n????ean O??elu Ro??u', 'CS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Borsa', 'L Borsa', 'MM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul ???Carol I???, Ora??ul Plopeni', 'Liceul ???Carol I??? Plopeni', 'PH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul ???Carol I???, Ora?? Bicaz', 'Lic Teoretic, Bicaz', 'NT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul ???Charles Laugier??? Craiova', 'Liceul Charles Laugier Craiova', 'DJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Cobadin', 'Lic Cobadin', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Constantin Brancoveanu, Oras Horezu', 'Lic C. Brancoveanu Horezu', 'VL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul ???Corneliu Medrea??? Zlatna', 'Lic. ???C. Medrea??? Zlatna', 'AB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Cre??tin ???Logos??? Bistri??a', 'Lic ???Logos??? B-??a', 'BN');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Cu Program Sportiv', 'BR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Cu Program Florin Sebes', 'Lps Sebes', 'AB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Cu Program Sportiv Alba Iulia', 'Lic. Sportiv Alba Iulia', 'AB');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Cu Program Sportiv Arad', 'AR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Cu Program Sportiv ???Avram Iancu??? Zal??u', 'Lic. Pr. Sp. ???a. Iancu??? Zal??u', 'SJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Cu Program Sportiv Bac??u', 'Liceul Cu Program Sportiv Bacau', 'BC');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Cu Program Sportiv Baia Mare', 'Lps Bm', 'MM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Cu Program Sportiv ???Banatul??? Timi??oara', 'Lic. Sportiv Banatul Timisoara', 'TM');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Cu Program Sportiv ???Bihorul??? Oradea', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Cu Program Sportiv Bistri??a', 'Lic Progr Sport Bistri??a', 'BN');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Cu Program Sportiv Botosani', 'BT');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Cu Program Sportiv Bra??ov', 'BV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Cu Program Sportiv C??mpulung', 'Lps C??mpulung', 'AG');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Cu Program Sportiv ???Cetate??? Deva', 'HD');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Cu Program Sportiv Cluj-Napoca', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Cu Program Sportiv Focsani', 'Lic. Cu Prg. Sportiv Focsani', 'VN');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Cu Program Sportiv ???Helmut Duckadam??? Clinceni', 'Liceul Cu Program Sportiv ???Helmut Duckadam???', 'IF');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Cu Program Sportiv, Ia??i', 'Lps Iasi', 'IS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Cu Program Sportiv ???Iolanda Bala?? ??oter??? Municipiul Buz??u', 'Lps', 'BZ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Cu Program Sportiv, Localitatea Galati', 'Lic. Sportiv Gl', 'GL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Cu Program Sportiv ???Mircea Eliade???', 'Lic. Cu Prog. Sp. ???Mircea Eliade???', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Cu Program Sportiv, Mun. Vaslui', 'Lef Vaslui', 'VS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Cu Program Sportiv, Municipiul Piatra-Neam??', 'Lps, Piatra-Neam??', 'NT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Cu Program Sportiv, Municipiul Roman', 'Lps, Roman', 'NT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Cu Program Sportiv ???Nadia Com??neci??? One??ti', 'Lps ???N. Com??neci??? One??ti', 'BC');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Cu Program Sportiv ???Nicolae Rotaru??? Constan??a', 'Lic Sp ???Nicolae Rotaru??? C??a', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Cu Program Sportiv ???Petrache Triscu??? Craiova', 'Liceul Petrache Triscu Craiova', 'DJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Cu Program Sportiv Satu Mare', 'Lps Satu Mare', 'SM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Cu Program Sportiv Slatina', 'Liceul Sportiv Slatina', 'OT');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Cu Program Sportiv Suceava', 'SV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Cu Program Sportiv ???Szasz Adalbert??? T??rgu Mure??', 'Lps ???S. Adalbert??? Tg. Mure??', 'MS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Cu Program Sportiv Tg-Jiu', 'Lic Cu Program Sportiv Tg-Jiu', 'GJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Cu Program Sportiv ???Viitorul??? Pite??ti', 'Lps Pite??ti', 'AG');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul ???Danubius??? Calarasi', 'Lic. ???Danubius??? Calarasi', 'CL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul de Agricultura Si Industrie Alimentara Odobesti', 'Lic. de Agricultura Si Ind. Alimentara Odobesti',
        'VN');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul de Arta ???Gheorghe Tattarescu??? Focsani', 'Lic. de Arta ???Gheorghe Tattarescu??? Focsani', 'VN');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul de Arta ???Stefan Luchian??? Botosani', 'Lic. Arta ???St. Luchian??? Botosani', 'BT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul de Art?? ???Ioan Sima??? Zal??u', 'Lic. Art?? ???I. Sima??? Zal??u', 'SJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul de Art?? ???Ion Vidu??? Timi??oara', 'Lic. Arta ???Ion Vidu??? Timisoara', 'TM');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul de Art?? Sibiu', 'SB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul de Arte ???Aurel Popp??? Satu Mare', 'Lar ???Aurel Popp??? Satu Mare', 'SM');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul de Arte ???B??la??a Doamna??? T??rgovi??te', 'DB');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul de Arte ???Constantin Brailoiu??? Tg-Jiu', 'GJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul de Arte ???Corneliu Baba??? Bistri??a', 'Lic ???C. Baba??? Bistrita', 'BN');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul de Arte ???Dimitrie Cuclin???, Localitatea Galati', 'Lic. Arte ???D. Cuclin??? Gl', 'GL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul de Arte ???Dinu Lipatti??? Pite??ti', 'Lic. Arte Dinu Lipatti Pite??ti', 'AG');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul de Arte ???Dr. Pall?? Imre??? Odorheiu Secuiesc', 'Lar ???Dr. Pallo Imre??? Odorhei', 'HR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul de Arte ???George Georgescu??? Tulcea', 'Liceul ???G. Georgescu??? Tulcea', 'TL');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul de Arte ???Hariclea Darclee???', 'BR');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul de Arte ???Ionel Perlea??? Slobozia', 'IL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul de Arte ???I.??t.  Paulian???', 'Lic. Art. ???I.St.  Paulian???', 'MH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul de Arte ???Margareta Sterian??? Municipiul Buz??u', 'Lic. Arte Bz', 'BZ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul de Arte ???Marin Sorescu??? Craiova', 'Liceul Marin Sorescu Craiova', 'DJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul de Arte ???Nagy Istv??n??? Miercurea Ciuc', 'Lar ???Nagy Istvan??? Miercurea Ciuc', 'HR');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul de Arte Oradea', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul de Arte Plastice ???Nicolae Tonitza???', 'Lic. ???Nicolae Tonitza???', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul de Arte Plastice Timi??oara', 'Lic. Arte Plastice Timisoara', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul de Arte ???Plugor S??ndor??? Sf??ntu Gheorghe', 'Lic. de Arte ???Plugor S??ndor??? Sf??ntu Gheorghe', 'CV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul de Arte ???Regina Maria??? Alba Iulia', 'Lic. Arte Alba Iulia', 'AB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul de Arte ???Sabin P??u??a??? Re??i??a', 'Lic de Arte ???Sabin P??u??a??? Re??i??a', 'CS');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul de Arte ???Sigismund Todu??????? Deva', 'HD');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul de Arte ???Victor Brauner???, Municipiul Piatra-Neam??', 'Lavb, Piatra Neam??', 'NT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul de Arte Victor Giuleanu, Mun. Rm. Valcea', 'Lic V. Giuleanu Ramnicu Valcea', 'VL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul de Arte Vizuale ???Romulus Ladea??? Cluj-Napoca', 'Liceul de Arte Vizuale ???Romulus Ladea??? Cluj-Napoc',
        'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul de Coregrafie ???Floria Capsali???', 'Lic. de Coregrafie ???F. Capsali???', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul de Coregrafie ??i Art?? Dramatic?? ???Octavian Stroia??? Cluj-Napoca',
        'Liceul de Coregrafie ???Octavian Stroia??? Cluj', 'CJ');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul de Industrie Alimentara Craiova', 'DJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul de Informatic?? ???Tiberiu Popoviciu??? Cluj-Napoca', 'Liceul de Informatic?? ???Tiberiu Popoviciu??? Cluj',
        'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul de Marin?? Constan??a', 'Lic de Marin?? C??a', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul de Muzic?? ???Tudor Jarda??? Bistri??a', 'Lic Muzic?? ???T. Jarda??? Bistrita', 'BN');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul de Transporturi Auto', 'Lic. Auto', 'MH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul de Transporturi Auto ???Traian Vuia???, Municipiul Galati', 'Lic. ???T. Vuia??? Gl', 'GL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul de Turism Si Alimentatie ???Dumitru Motoc???, Municipiul Galati', 'Lic. ???D. Motoc??? Gl', 'GL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul ???Demostene Botez??? Tru??e??ti', 'Liceul ???Demostene Botez??? Trusesti', 'BT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul ???Dimitrie Cantemir??? Babadag', 'Liceul Babadag', 'TL');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul ???Dimitrie Cantemir??? Darabani', 'BT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul ???Dimitrie Negreanu??? Botosani', 'Liceul ???Dimitrie Negreanu???', 'BT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul ???Dimitrie Paciurea???', 'Lic. ???Dimitrie Paciurea???', 'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul ???Don Orione??? Oradea', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul ???Dr. Lazar Chirila??? Baia de Aries', 'Lic. Baia de Aries', 'AB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Economic ???Alexandru Ioan Cuza???, Municipiul Piatra-Neam??', 'Le ???Alexandru Ioan Cuza???, Piatra Neam??',
        'NT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Economic ???Berde ??ron??? Sf??ntu Gheorghe', 'Lic. Ec. ???Berde ??ron??? Sf??ntu Gheorghe', 'CV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Economic N??s??ud', 'Lic Ec N??s??ud', 'BN');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Economic ???Virgil Madgearu??? Constan??a', 'Lic Ec ???Virgil Madgearu??? C??a', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul ???Educa??ia Viitorului??? Constan??a', 'Lic Educ Viitorului', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Energetic Constan??a', 'Lic Energetic C??a', 'CT');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Energetic Craiova', 'DJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Energetic Tg-Jiu', 'Lic Energetic Tg-Jiu', 'GJ');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Feg', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Feg, Iasi', 'Lic Feg Iasi', 'IS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul George Tarnea, Oras Babeni', 'Lic George Tarnea Babeni', 'VL');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul German ???Hermann Oberth??? Voluntari', 'IF');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul German Sebes', 'Lic. German Sebes', 'AB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul ???Gh. Ruset Roznovanu???, Ora?? Roznov', 'L ???Gh. Ruset Roznovanu???, Roznov', 'NT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Greco-Catolic ???Inochentie Micu??? Cluj-Napoca', 'Liceul Greco-Catolic ???Inochentie Micu??? Cluj-Napoc',
        'CJ');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Greco-Catolic ???Iuliu Maniu??? Oradea', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Greco-Catolic ???Timotei Cipariu???', 'Lic. Greco-Catolic ???Timotei Cipariu???', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul ???Hercules??? Baile Herculane', 'Lic ???Hercules??? Baile Herculane', 'CS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul ???Horea, Closca Si Crisan??? Abrud', 'Lic ???Hcc??? Abrud', 'AB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Interna??ional Ioanid', 'Liceul Ioanid', 'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul ???Ioan Buteanu??? Gurahon??', 'AR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul ???K??r??si Csoma S??ndor??? Covasna', 'Lic. ???K??r??si Csoma S??ndor??? Covasna', 'CV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul ???Marin Preda??? Odorheiu Secuiesc', 'Lit ???Marin Preda??? Odorhei', 'HR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul ???Matei Basarab??? Craiova', 'Liceul Matei Basarab Craiova', 'DJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul ???Mathias Hammer??? Anina', 'Lic ???Mathias Hammer??? Anina', 'CS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul ???Mihail Sadoveanu???, Comuna Borca', 'L ???Mihail Sadoveanu???, Borca', 'NT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul ???Miron Cristea??? Subcetate', 'Lit ???Miron Cristea??? Subcetate', 'HR');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul ???Natanael??? Suceava', 'SV');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Na??ional de Informatic?? Arad', 'AR');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Ortodox ???Episcop Roman Ciorogariu??? Oradea', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Ortodox ???Sf. Nicolae??? Zal??u', 'Lic. Ortodox ???Sf. Nicolae??? Zal??u', 'SJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Particular ???Henri Coanda??? Baia Mare', 'Lic Part H Coanda Bm', 'MM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Particular Nr. 1, Sat Bistri??a, Comuna Alexandru Cel Bun', 'L Part Nr. 1, Sat Bistri??a', 'NT');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Particular ???Onicescu-Mihoc???', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Pedagogic ???Anastasia Popescu???', 'Liceul ???Anastasia Popescu???', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Pedagogic ???Benedek Elek??? Odorheiu Secuiesc', 'Lit ???Benedek Elek??? Odorhei', 'HR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Pedagogic ???Bod P??ter??? T??rgu Secuiesc', 'Lic. Ped. ???Bod P??ter??? T??rgu Secuiesc', 'CV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Pedagogic ???Gheorghe ??incai??? Zal??u', 'Lic. Pedagogic ???Gh. ??incai??? Zal??u', 'SJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Pedagogic ???Ioan Popescu???, Mun. B??rlad', 'Lic Ped B??rlad', 'VS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Pedagogic ???Matei Basarab??? Slobozia', 'Liceul Ped. ???Matei Basarab??? Slobozia', 'IL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Pedagogic ???Nicolae Iorga??? Botosani', 'Liceul Pedagogic ???N. Iorga??? Botosani', 'BT');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Pedagogic ???Stefan Banulescu??? Calarasi', 'CL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Pedagogic ???Taras Sevcenko??? Sighetu Marmatiei', 'Lped T Sevcenko Sighet', 'MM');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Penitenciar Jilava', 'IF');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul ???Petru Rare????? Feldioara', 'BV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Preda Buzescu, Oras Berbesti', 'Lic Preda Buzescu Berbesti', 'VL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul ???Prima School??? Municipiul Buz??u', 'Lic Prima School', 'BZ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul ???Profesia???', 'Liceul Profesia', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul ???Radu Miron???, Mun. Vaslui', 'Lic Rmiron Vs', 'VS');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Reformat ???Lorantffy Zsuzsanna??? Oradea', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Reformat Satu Mare', 'Licteo Reformat Sm', 'SM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Reformat ???Wesselenyi??? Zal??u', 'Lic. Reformat ???Wesselenyi??? Zal??u', 'SJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul ???Regele Carol I??? Ostrov', 'Lic Ostrov', 'CT');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul ???Regina Maria??? Dorohoi', 'BT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Romano-Catolic ???Josephus Calasantius??? Carei', 'Lic Rom-Cat Carei', 'SM');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul ???Rom??no-Finlandez???', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Sanitar ???Antim Ivireanu???, Mun. Rm. Valcea', 'Lic Sanitar a. Ivireanu Rm. Valcea', 'VL');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul ???Sever Bocu??? Lipova', 'AR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul ???Sextil Pu??cariu??? Bran', 'Liceul Bran', 'BV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Silvic Gurghiu', 'Lic. Silvic Gurghiu', 'MS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Silvic ???Transilvania??? N??s??ud', 'Lic Silvic ???Transilvania??? N??s??ud', 'BN');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul ???Simion Mehedinti??? Vidra', 'Lic. ???Simion Mehedinti??? Vidra', 'VN');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul ???Simion Stolnicu???, Ora??ul Comarnic', 'Liceul ???S. Stolnicu??? Comarnic', 'PH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Special ???Moldova???, T??rgu Frumos', 'Lic Spec ???Moldova??? Tg. Frumos', 'IS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Special Pentru Deficien??i de Vedere Cluj-Napoca', 'Liceul Special Pentru Deficien??i de Vedere Cluj',
        'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Special Pentru Deficien??i de Vedere Municipiul Buz??u', 'Lsdv Bz', 'BZ');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Special ???Sf??nta Maria??? Arad', 'AR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul ?????tefan Cel Mare???, Sat Cod??e??ti', 'Lic Cod??e??ti', 'VS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul ?????tefan Diaconescu??? Potcoava', 'Liceul ???St. Diaconescu??? Potcoava', 'OT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul ?????tefan Procopiu???, Mun. Vaslui', 'Lic ??tefan Procopiu', 'VS');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul ?????t. O. Iosif??? Rupea', 'BV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnic Municipiul Buz??u', 'Liceul Tehnic Buz??u', 'BZ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Administrativ ??i de Servicii ???Victor Sl??vescu???, Municipiul Ploie??ti',
        'Liceul Tehnologic ???Victor Slavescu??? Pl', 'PH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Agricol ???Alexandru Borza??? Ciumbrud', 'Lic. Teh. ???a. Borza??? Ciumbrud', 'AB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Agricol ???Alexandru Borza??? Geoagiu', 'Liceul Agricol ???Alexandru Borza??? Geoagiu', 'HD');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Agricol ???Alexiu Berinde??? Seini', 'Lth a Berinde Seini', 'MM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Agricol Beclean', 'Lic Teh Agricol Beclean', 'BN');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Agricol Bistri??a', 'Lic Teh Agricol Bistri??a', 'BN');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Agricol, Comuna B??rc??ne??ti', 'Liceul Tehnologic Agricol Barcanesti', 'PH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Agricol Comuna Smeeni', 'Lic Teh Smeeni', 'BZ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Agricol ???Mihail Kogalniceanu???, Miroslava', 'Lic Teh Agr Miroslava', 'IS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Agricol ???Nicolae Corn????eanu??? Tulcea', 'Liceul Agricol Tulcea', 'TL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Agroindustrial ???Tamasi Aron??? Bor??', 'Liceul Tehnologic Agroindustrial ???T. Aron??? Bor??', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Agromontan ???Romeo Constantinescu???, Ora??ul V??lenii de Munte',
        'Liceul Tehn. ???R. Constantinescu??? Valeni de Munte', 'PH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Aiud', 'Lic. Teh. Aiud', 'AB');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic ???Alexandru Borza??? Cluj-Napoca', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Alexandru Domsa??? Alba Iulia', 'Lic. Tehn. ???Al. Domsa??? Alba Iulia', 'AB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Alexandru Filipascu??? Petrova', 'Lth a Filipascu Petrova', 'MM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Alexandru Ioan Cuza???, Mun. B??rlad', 'Lic. Tehn Al. I. Cuza', 'VS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Alexandru Ioan Cuza??? Panciu', 'Lic. Tehn. ???Alexandru Ioan Cuza??? Panciu', 'VN');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Alexandru Macedonski??? Melinesti', 'Liceul Melinesti', 'DJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Alexandru Vlahu??????? Podu Turcului', 'Liceul Teh ???Al. Vlahuta??? P. Turcului', 'BC');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Alexe Marin??? Slatina', 'Liceul Tehn ???Alexe Marin??? Slatina', 'OT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Al. Ioan Cuza??? Slobozia', 'Liceul Teh. ???Al. Ioan Cuza??? Slobozia', 'IL');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic ???Al. Vlahuta??? Sendriceni', 'BT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Andrei ??aguna??? Botoroaga', 'Lth ???Andrei ??aguna??? Botoroaga', 'TR');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic ???Anghel Saligny???', 'BR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Anghel Saligny??? Bac??u', 'Liceul Tehnologic a. Saligny Bac??u', 'BC');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Anghel Saligny??? Fete??ti', 'Liceul Teh ???Anghel Saligny??? Fete??ti', 'IL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Anghel Saligny???, Localitatea Galati', 'Lic. Teh. ???a. Saligny??? Gl', 'GL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Anghel Saligny???, Municipiul Ploie??ti', 'Liceul Tehnologic ???Anghel Saligny??? Ploiesti', 'PH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Anghel Saligny??? Ro??iori de Vede', 'Lth ???Anghel Saligny??? Ro??iori de Vede', 'TR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Anghel Saligny??? Tulcea', 'Liceul ???a. Saligny??? Tulcea', 'TL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Anghel Saligny??? Tur??', 'Lteh ???Anghel Saligny??? Tur??', 'SM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Apor P??ter??? T??rgu Secuiesc', 'Lic. Tehn. ???Apor P??ter??? T??rgu Secuiesc', 'CV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Ardud', 'Lteh Ardud', 'SM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Arhimandrit Chiriac Nicolau???, Comuna V??n??tori-Neam??',
        'L Teh ???Arhim. Chiriac Nicolau???, V??n??tori-Neam??', 'NT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Astra??? Pite??ti', 'Lic. Teh. Astra Pite??ti', 'AG');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Aurel Persu??? T??rgu Mure??', 'Lic. Tehn. ???a. Persu??? Tg. Mure??', 'MS');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic ???Aurel Vlaicu??? Arad', 'AR');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic ???Aurel Vlaicu??? Cluj-Napoca', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Aurel Vlaicu??? Lugoj', 'Lic. Teh. ???a. Vlaicu??? Mun. Lugoj', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Aurel Vlaicu???, Municipiul Galati', 'Lic. Teh. ???a. Vlaicu??? Gl', 'GL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Auto C??mpulung', 'Lic. Teh. Auto C??mpulung', 'AG');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Auto Craiova', 'Liceul Auto Craiova', 'DJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Auto Curtea de Arge??', 'Lic. Teh. Auto Curtea de Ag', 'AG');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Automecanica??? Media??', 'Lic Tehn Automecanica Media??', 'SB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Avram Iancu??? Sibiu', 'Lic Tehn ???Avram Iancu??? Sibiu', 'SB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Avram Iancu??? T??rgu Mure??', 'Lic. Tehn. ???a. Iancu??? Tg. Mure??', 'MS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Axiopolis??? Cernavod??', 'Lic Teh ???Axiopolis??? Cernavod??', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Azur??? Timi??oara', 'Lic. Teh. ???Azur??? Timisoara', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Baia de Fier', 'Lic Teh Baia de Fier', 'GJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Balteni', 'Lic Teh Balteni', 'GJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???B??nyai J??nos??? Odorheiu Secuiesc', 'Gri ???Banyai Janos??? Odorhei', 'HR');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic ???Barbu a. ??tirbey??? Buftea', 'IF');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Bar??ti Szab?? D??vid??? Baraolt', 'Lic. Tehn. ???Bar??ti Szab?? D??vid??? Baraolt', 'CV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Barsesti', 'Lic Teh Barsesti', 'GJ');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic Beliu', 'AR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Berzovia', 'So8 Berzovia', 'CS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Bistri??a', 'Lic Teh Bistri??a', 'BN');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Brad Segal??? Tulcea', 'Liceul ???Brad Segal??? Tulcea', 'TL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Bratianu, Mun. Dragasani', 'Lic Teh Bratianu Dragasani', 'VL');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic Bucecea', 'BT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Bustuchin', 'Lic Teh Bustuchin', 'GJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Capitan Nicolae Plesoianu, Mun. Rm. Valcea', 'Lic Teh Plesoianu Rm. Valcea', 'VL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Carol I???, Comuna Valea Doftanei', 'Liceul Tehnologic ???Carol I???, Comuna Valea Doftane',
        'PH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Carol I???, Municipiul Galati', 'Lic. Teh. ???Carol I??? Gl', 'GL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Carol I??? Slatina', 'Liceul Tehn ???Carol I??? Slatina', 'OT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???C.a. Rosetti??? Constan??a', 'Lic Teh ???C a Rosetti??? C??a', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Carsium??? H??r??ova', 'Lic Tehnologic ???Carsium??? H??r??ova', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Cezar Nicolau??? Br??ne??ti', 'Liceul Tehnologic ???Cezar Nicolau??? Branesti', 'IF');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic Chi??ineu Cri??', 'AR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Ciobanu', 'Lic Teh Ciobanu', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Cisn??die', 'Lic Tehn Cisn??die', 'SB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Clisura Dun??rii??? Moldova Nou??', 'Lth Moldova Noua', 'CS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Cogealac', 'Lic Teh Cogealac', 'CT');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic Cojasca', 'DB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic, Comuna Filipe??tii de P??dure', 'Liceul Tehnologic Filipestii de Padure', 'PH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Comuna Lop??tari', 'Lic Teh Lop??tari', 'BZ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Comuna Ru??e??u', 'Lic Teh Ru??e??u', 'BZ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Comuna Verne??ti', 'Lic Teh Verne??ti', 'BZ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Concord??? Constan??a', 'Lic Teh ???Concord??? C??a', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Constantin Brancusi??? Craiova', 'Liceul Constantin Brancusi Craiova', 'DJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Constantin Br??ncoveanu??? T??rgovi??te', 'Liceul Tehnologic ???Constantin Br??ncoveanu??? Tgv',
        'DB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Constantin Br??ncu??i???', 'Lic. Tehn. ???Constantin Br??ncu??i???', 'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic ???Constantin Br??ncu??i??? Dej', 'CJ');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic ???Constantin Br??ncu??i??? Oradea', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Constantin Br??ncu??i??? Pite??ti', 'Lic. Teh. C. Br??ncu??i Pite??ti', 'AG');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Constantin Br??ncu??i??? Satu Mare', 'Ltehn ???Constantin Br??ncu??i??? Sm', 'SM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Constantin Br??ncu??i??? Sf??ntu Gheorghe', 'Lic. Tehn. ???Constantin Br??ncu??i??? Sf??ntu Gheorghe',
        'CV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Constantin Br??ncu??i??? T??rn??veni', 'Lic. Tehn. ???C. Br??ncu??i??? T??rn??veni', 'MS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Constantin Br??ncu??i??? T??rgu Mure??', 'Lic. Tehn. ???C. Br??ncu??i??? Tg. Mure??', 'MS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Constantin Br??ncoveanu??? Scornice??ti', 'Liceul Teh. ???C. Brincoveanu??? Scornicesti', 'OT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Constantin Bursan??? Hunedoara', 'Lic. Tehn. ???C. Bursan??? Hunedoara', 'HD');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Constantin Cantacuzino???, Ora??ul B??icoi', 'Liceul Tehnologic ???C. Cantacuzino??? Baicoi', 'PH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Constantin Dobrescu??? Curtea de Arge??', 'Lic. Teh. Constantin Dobrescu Curtea de Arge??',
        'AG');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Constantin Filipescu??? Caracal', 'Liceul Tehnologic ???C. Filipescu??? Caracal', 'OT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Constantin George Calinescu??? Gradistea', 'Lic. Tehnologic ???George Calinescu??? Gradistea',
        'CL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Constantin Ianculescu??? Carcea', 'Liceul Carcea', 'DJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Constantin Istrati???, Municipiul C??mpina', 'Liceul ???C. Istrati??? Campina', 'PH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Constantin Lucaci??? Boc??a', 'Lth ???Constantin Lucaci??? Boc??a', 'CS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Constantin Nicolaescu-Plopsor??? Plenita', 'Liceul Plenita', 'DJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Construc??ii de Ma??ini Mioveni', 'Lic. Teh. Construc??ii Ma??ini Mioveni', 'AG');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Construc??ii ??i Arhitectur?? ???Carol I??? Sibiu', 'Lic Tehn C-??ii ??i Arh ???Carol I??? Sibiu', 'SB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Corbu', 'Gri Corbu', 'HR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Corund', 'Gri Corund', 'HR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Costache Conachi???, Comuna Pechea', 'Lic. Teh. ???C. Conachi??? Pechea', 'GL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Coste??ti', 'Lic. Teh. Coste??ti', 'AG');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Costin D. Nenitescu??? Craiova', 'Liceul Costin D. Nenitescu Craiova', 'DJ');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic Co??u??ca', 'BT');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic Cr??mpoia', 'OT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Cristofor Nako??? S??nnicolau Mare', 'Lic. Tehn. C. Nako Sannicolau Mare', 'TM');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic ???Cri??an??? Cri??cior', 'HD');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Crucea', 'Lic Tehnologic Crucea', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Cserey-Goga??? Crasna', 'Lic. Tehnologic ???Cserey-Goga??? Crasna', 'SJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???C-Tin Brancusi???- Pestisani', 'Lic Teh ???C. Brancusi??? Pestisani', 'GJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Dacia???', 'Lic. Tehnol. ???Dacia???', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Dacia??? Caransebe??', 'Lth Dacia Caransebes', 'CS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Dacia??? Pite??ti', 'Lic. Teh. Dacia Pite??ti', 'AG');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Dan Mateescu??? Calarasi', 'Lic. Tehnologic ???Dan Mateescu??? Calarasi', 'CL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Danubius??? Corabia', 'Liceul Tehn ???Danubius??? Corabia', 'OT');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic D??rm??ne??ti', 'BC');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic de Construc??ii ??i Protec??ia Mediului Arad',
        'Liceul Tehnolo. Construc??ii Protec??ia Mediului Arad', 'AR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic de Electronic?? ??i Automatiz??ri ???Caius Iacob??? Arad', 'Liceul Tehnologic ???Caius Iacob??? Arad',
        'AR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic de Electronic?? ??i Telecomunica??ii ???Gheorghe M??rzescu???, Ia??i', 'Lic Teh Etc Iasi', 'IS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic de Electrotehnic?? ??i Telecomunica??ii Constan??a',
        'Lic Tehnologic de Electrotehnic?? Telecomunica??ii', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic de Industrie Alimentar?? Arad', 'Liceul Tehnologic Industrie Alimentar?? Arad', 'AR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic de Industrie Alimentar?? Fete??ti', 'Liceul Teh. de Ind. Alim. Fete??ti', 'IL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic de Industrie Alimentar?? ???George Emil Palade??? Satu Mare', 'Ltehn ???George Emil Palade??? Sm',
        'SM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic de Industrie Alimentar?? ???Terezianum??? Sibiu', 'Lic Tehn Ind Alim ???Terezianum??? Sibiu', 'SB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic de Industrie Alimentar?? Timi??oara', 'Lic. Teh. de Ind. Alimentara Timisoara', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic de Mecatronic?? ??i Automatiz??ri, Ia??i', 'Ltma Iasi', 'IS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic de Meserii ??i Servicii Municipiul Buz??u', 'Lic. Teh. Meserii', 'BZ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic de Metrologie ???Traian Vuia???', 'Lic. Tehnol. de Metrologie ???Traian Vuia???', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic de Servicii Bistri??a', 'Lic Teh de Serv Bistri??a', 'BN');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic de Servicii ???Sf??ntul Apostol Andrei???, Municipiul Ploie??ti',
        'Liceul Tehnologic ???Sf. Apostol Andrei??? Ploiesti', 'PH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic de Silvicultur?? ??i Agricultur?? ???Casa Verde??? Timi??oara',
        'Lic. Teh. Silvic ???Casa Verde??? Timisoara', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic de Transport Feroviar ???Anghel Saligny??? Simeria',
        'Liceul Tehnologic Tf. ???Anghel Saligny??? Simeria', 'HD');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic de Transporturi Auto Baia Sprie', 'Ltehn Transp Auto Bs', 'MM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic de Transporturi Auto Craiova', 'Liceul de Transporturi Auto Craiova', 'DJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic de Transporturi Auto ???Henri Coand????? Arad', 'Liceul Tehnologic Transp. Auto ???H. Coand????? Arad',
        'AR');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic de Transporturi Auto T??rgovi??te', 'DB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic de Transporturi, Municipiul Ploie??ti', 'Liceul Tehnologic de Transporturi Ploiesti', 'PH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic de Transporturi ??i de Construc??ii, Ia??i', 'Lic Teh Transp Si Constr Iasi', 'IS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic de Turism, Oras Calimanesti', 'Lic Teh Turism Calimanesti', 'VL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic de Turism Si Alimentatie Arieseni', 'Lic. Teh. Arieseni', 'AB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic de Vest Timi??oara', 'Lic. Teh. Vest Timisoara', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Decebal???', 'Lic. Teh. Decebal', 'MH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Decebal??? Caransebe??', 'Lth ???Decebal??? Caransebe??', 'CS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Dierna???', 'Lic. Teh. Dierna', 'MH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Dimitrie Bolintineanu??? Bolintin Vale', 'Lic. Tehn. ???Dimitrie Bolintineanu???', 'GR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Dimitrie Cantemir???, Sat F??lciu', 'Lic. Tehn F??lciu', 'VS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Dimitrie Dima??? Pite??ti', 'Lic. Teh. Dimitrie Dima Pite??ti', 'AG');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Dimitrie Filipescu??? Municipiul Buz??u', 'Lic. Teh. Filipescu', 'BZ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Dimitrie Filisanu??? Filiasi', 'Liceul Filiasi', 'DJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Dimitrie Gusti???', 'Lic. Tehn. ???Dimitrie Gusti???', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Dimitrie Leonida??? Constan??a', 'Lic Tehnologic ???Dimitrie Leonida??? C??a', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Dimitrie Leonida???, Ia??i', 'Lic Teh ???D. Leonida??? Iasi', 'IS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Dimitrie Leonida???, Municipiul Piatra-Neam??', 'Ltdl, Piatra Neam??', 'NT');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic ???Dimitrie Leonida??? Petro??ani', 'HD');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Dimitrie Petrescu??? Caracal', 'Liceul Tehn ???D. Petrescu??? Caracal', 'OT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Dinu Br??tianu??? ??tef??ne??ti', 'Lic. Teh. Dinu Br??tianu ??tef??ne??ti', 'AG');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Doamna Chiajna??? Chiajna', 'Liceul Tehnologic ???Doamna Chiajna??? Rosu', 'IF');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Dobrogea??? Castelu', 'Lic Teh ???Dobrogea??? Castelu', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Domnul Tudor???', 'Lic. Teh. Domnul Tudor', 'MH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Domokos Kazmer??? Sovata', 'Lic. Tehn. ???D. Kazmer??? Sovata', 'MS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Dorin Pavel??? Alba Iulia', 'Lic. Tehn. ???Dorin Pavel??? Alba Iulia', 'AB');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic Dorna Candrenilor', 'SV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Dr. Florian Ulmeanu??? Ulmeni', 'Lth Dr F Ulmeanu Ulmeni', 'MM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Dr. Ioan ??enchea??? F??g??ra??', 'Liceul Tehnologic ???I. ??enchea??? F??g??ra??', 'BV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Dragomir Hurmuzescu???', 'Lic. Tehn. ???Dragomir Hurmuzescu???', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Dragomir Hurmuzescu??? Medgidia', 'Lic Tehnologic ???Dragomir Hurmuzescu??? Medgidia', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Dr??g??ne??ti-Olt', 'Liceul Teh. Draganesti-Olt', 'OT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Dr??g??ne??ti-Vla??ca', 'Lth Dr??g??ne??ti-Vla??ca', 'TR');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic ???Dr. C. Angelescu??? G??e??ti', 'DB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Duiliu Zamfirescu??? Dragalina', 'Lic. Tehnologic ???Duiliu Zamfirescu??? Dragalina', 'CL');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic ???Dumitru Dumitrescu??? Buftea', 'IF');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic ???Dumitru Mangeron??? Bac??u', 'BC');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Economic de Turism, Ia??i', 'Lic Ec de Turism Iasi', 'IS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Economic ???Elina Matei Basarab??? Municipiul R??mnicu S??rat', 'Lic. Teh. Economic Rs', 'BZ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Economic ???Nicolae Iorga???, Pa??cani', 'Lic ???Nicolae Iorga??? Pascani', 'IS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Economic ???Virgil Madgearu???, Ia??i', 'Lic Ec ???V. Madgearu??? Iasi', 'IS');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic ???Edmond Nicolau??? Br??ila', 'BR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Electromure????? T??rgu Mure??', 'Lic. Tehn. ???Electromure????? Tg. Mure??', 'MS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Electrotimi????? Timi??oara', 'Lic. Teh. ???Electrotimi????? Timisoara', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Elena Caragiani???, Localitatea Tecuci', 'Lic. Teh. ???E. Caragiani??? Tc', 'GL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Elie Radu???', 'Lic. Tehn. ???Elie Radu???', 'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic ???Elie Radu??? Botosani', 'BT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Elisa Zamfirescu??? Satu Mare', 'Lteh ???Elisa Zamfirescu??? Sm', 'SM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Emil Racovi??????? Ro??iori de Vede', 'Lth ???Emil Racovi??????? Ro??iori de Vede', 'TR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Energetic ???Dragomir Hurmuzescu??? Deva', 'Liceul Tehnologic Energetic ???D. Hurmuzescu??? Deva',
        'HD');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Energetic ???Elie Radu???, Municipiul Ploie??ti', 'Liceul Tehnic ???Elie Radu??? Ploiesti', 'PH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Energetic, Municipiul C??mpina', 'Liceul Tehnologic Energetic Campina', 'PH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Energetic ???Regele Ferdinand I??? Timi??oara', 'Lic. Teh. ???Regele Ferdinand I??? Timisoara', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???E??tv??s J??zsef??? Odorheiu Secuiesc', 'Gri ???Eotvos Jozsef??? Odorhei', 'HR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Eremia Grigorescu??? Marasesti', 'Lic. Tehn. ???Eremia Grigorescu??? Marasesti', 'VN');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Eremia Grigorescu???, Oras Tg. Bujor', 'Lic. Teh. ???E. Grigorescu??? Tg. Bujor', 'GL');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic F??get', 'BC');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Feldru', 'Lic Teh Feldru', 'BN');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic ???Felix??? S??nmartin', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Ferdinand I??? Curtea de Arge??', 'Lic. Teh. Ferdinand I Curtea de Arge??', 'AG');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Ferdinand I, Mun. Rm. Valcea', 'Lic Teh Ferdinand I Rm. Valcea', 'VL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Fierbin??i-T??rg', 'Liceul Teh. Fierbin??i-T??rg', 'IL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Florian Porcius??? Rodna', 'Lic Teh ???F. Porcius??? Rodna', 'BN');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Fogarasy Mih??ly??? Gheorgheni', 'Gri ???Fogarasy??? Gheorgheni', 'HR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Forestier, Mun. Rm. Valcea', 'Lic Tehn Forestier, Mun. Rm. Valcea', 'VL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Forestier Sighetu Marmatiei', 'Lth Forestier Sighet', 'MM');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic ???Francisc Neuman??? Arad', 'AR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???G??bor ??ron??? T??rgu Secuiesc', 'Lic. Tehn. ???G??bor ??ron??? T??rgu Secuiesc', 'CV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???G??bor ??ron??? Vl??hi??a', 'Gri ???Gabor Aron??? Vlahita', 'HR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???General David Praporgescu??? Turnu M??gurele', 'Lth ???G-Ral David Praporgescu??? Turnu M??gurele',
        'TR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???General de Marina Nicolae Dumitrescu Maican???, Localitatea Galati', 'Lic. Teh. Marina Gl',
        'GL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic General Magheru, Mun. Rm. Valcea', 'Lic Teh G. Magheru Rm. Valcea', 'VL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???George Bari??iu??? Livada', 'Lteh ???George Bari??iu??? Livada', 'SM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???George Bibescu??? Craiova', 'Liceul George Bibescu Craiova', 'DJ');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic ???Georgeta J. Cancicov??? Parincea', 'BC');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic ???Georgiana??? Oradea', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???G.G. Longinescu??? Focsani', 'Lic. Tehn. ???G.G. Longinescu??? Focsani', 'VN');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Ghenu???? Coman???, Ora?? Murgeni', 'Lic. Tehn Murgeni', 'VS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Gheorghe Duca??? Constan??a', 'Lic Tehnologic ???Ghe Duca??? C??a', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Gheorghe Ionescu-Sise??ti???, Comuna Valea C??lug??reasc??',
        'Liceul ???Ghe. Ionescu-Sisesti??? Valea Calugareasca', 'PH');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic ???Gheorghe K. Constantinescu???', 'BR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Gheorghe Laz??r???, Ora??ul Plopeni', 'Liceul Tehnologic Plopeni', 'PH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Gheorghe Miron Costin??? Constan??a', 'Lic Teh Gheorghe Miron C-??a', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Gheorghe Pop de B??se??ti??? Cehu Silvaniei',
        'Lic. Tehnologic ???G.P. de B??se??ti??? Cehu Silvaniei', 'SJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Gheorghe ??incai??? T??rgu Mure??', 'Lic. Tehn. ???G. ??incai??? Tg. Mure??', 'MS');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic Gherla', 'CJ');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic ???Goga Ionescu??? Titu', 'DB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???G-Ral C-Tin Sandru??? Balta, Runcu', 'Lic Teh ???G-Ral C-Tin Sandru??? Balta, Runcu', 'GJ');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic ???Grigore Antipa??? Bac??u', 'BC');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Grigore C. Moisil??? Municipiul Buz??u', 'Lic. Teh. Moisil', 'BZ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Grigore C Moisil??? Targu Lapus', 'Lth Gc Moisil Tg Lapus', 'MM');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic ???Grigore Moisil???', 'BR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Grigore Moisil??? Bistri??a', 'Lic Teh ???Gr. Moisil??? Bistri??a', 'BN');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Grigore Moisil??? Deva', 'Lic. Tehn. ???Grigore Moisil??? Deva', 'HD');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Hal??nga', 'Lic. Teh. Halanga', 'MH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Haralamb Vasiliu???, Podu Iloaiei', 'Lic Teh Podu Iloaiei', 'IS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic, H??rl??u', 'Lic Teh Harlau', 'IS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Henri Coand????? Beclean', 'Lic Teh ???H. Coanda??? Beclean', 'BN');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Henri Municipiul Buz??u', 'Lic. Coand?? Bz', 'BZ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Henri Coand????? Sibiu', 'Lic Tehn ???H. Coand????? Sibiu', 'SB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Henri Coand????? Tulcea', 'Liceul ???H. Coand????? Tulcea', 'TL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Horea Clo??ca ??i Cri??an??? Cluj-Napoca', 'Liceul Tehnologic ???Horea Clo??ca ??i Cri??an??? Cluj',
        'CJ');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic ???Horea??? Marghita', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Horia Vintila??? Segarcea', 'Liceul Horia Vintila Segarcea', 'DJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???I.a. R??dulescu Pogoneanu??? Ora?? Pogoanele', 'Lic Teh Pogoanele', 'BZ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Iacobeni', 'Lic Tehn Iacobeni', 'SB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Iancu Jianu', 'Liceul Teh. Iancu Jianu', 'OT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???I.C. Petrescu??? St??lpeni', 'Lic. Teh. I.C. Petrescu St??lpeni', 'AG');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???I.C. Br??tianu??? Nicolae B??lcescu', 'Lic Tehnologic Nicolae B??lcescu', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Iernut', 'Lic. Tehn. Iernut', 'MS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Ilie M??celariu??? Miercurea Sibiului', 'Lic Tehn ???I. M??celariu??? Miercurea Sibiului', 'SB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Independen??a', 'Lic Tehnologic Independen??a', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Independen??a??? Sibiu', 'Lic Tehn ???Independen??a??? Sibiu', 'SB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Ioachim Pop??? Ileanda', 'Lic. Tehnologic ???I. Pop??? Ileanda', 'SJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Ioan Bojor??? Reghin', 'Lic. Tehn. I. Reghin', 'MS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Ioan Corivan???, Mun. Hu??i', 'Lic. Tehn Hu??i', 'VS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Ioan Lupa????? S??li??te', 'Lic Tehn ???Ioan Lupa????? S??li??te', 'SB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Ioan N. Roman??? Constan??a', 'Lic Tehnologic ???Ioan N Roman??? C??a', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Ioan Ossian??? ??imleu Silvaniei', 'Lic. Tehnologic ???I. Ossian??? ??imleu Silvaniei', 'SJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Ioan Slavici??? Timi??oara', 'Lic Teh. I. Slavici Timisoara', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Ion Barbu??? Giurgiu', 'Lic. Teh. ???Ion Barbu???', 'GR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Ion B??nescu??? Mangalia', 'Lic Teh ???Ion B??nescu??? Mangalia', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Ion C??ian Rom??nul??? C??ianu Mic', 'Lic Teh ???I.C.R.??? C??ianu Mic', 'BN');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Ion Creang?????, Comuna Pipirig', 'Ltic, Pipirig', 'NT');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic ???Ion Creang????? Curtici', 'AR');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic ???Ion Ghica??? Oltenita', 'CL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Ion I.C. Br??tianu??? Satu Mare', 'Lteh ???Ion I.C. Br??tianu??? Sm', 'SM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Ion I.C. Br??tianu???', 'Lic. Tehn. ???Ion I.C. Br??tianu???', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Ion Ionescu de La Brad???, Comuna Horia', 'Lt ???Ion Ionescu de La Brad???, Horia', 'NT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Ion Mincu???, Mun. Vaslui', 'Lic. Tehn Ion Mincu', 'VS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Ion Mincu??? Tulcea', 'Liceul ???I. Mincu??? Tulcea', 'TL');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic ???Ion Nistor??? Vicovu de Sus', 'SV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Ion Podaru??? Ovidiu', 'Lic Tehnologic ???Ion Podaru??? Ovidiu', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Ion Popescu-Cilieni??? Cilieni', 'Liceul Teh. ???I.Popescu- Cilieni??? Cilieni', 'OT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Ion Vlasiu??? T??rgu Mure??', 'Lic. Tehn. ???I. Vlasiu??? Tg. Mure??', 'MS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Ion. I.C. Br??tianu??? Timi??oara', 'Lic. Teh. I.I.C. Bratianu Timisoara', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Ioni???? G. Andron??? Negre??ti-Oa??', 'Lteh ???Ioni???? G. Andron??? Negre??ti-Oa??', 'SM');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic ???Iordache Golescu??? G??e??ti', 'DB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Iordache Zossima??? Arm????e??ti', 'Liceul Teh. ???Iordache Zossima??? Arm????e??ti', 'IL');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic ???Iorgu V??rnav Liteanu??? Liteni', 'SV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Iosif Coriolan Buracu??? Prigor', 'Lth Prigor', 'CS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Iuliu Maniu??? Carei', 'Lteh ???Iuliu Maniu??? Carei', 'SM');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic ???Iuliu Moldovan??? Arad', 'AR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Izvoarele', 'Liceul Teh. Izvoarele', 'OT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ?????n??l??area Domnului??? Slobozia', 'Liceul Teh. ?????n??l??area Domnului??? Slobozia', 'IL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Jacques M. Elias??? Sascut', 'Liceul Tehnologic ???J.M. Elias??? Sascut', 'BC');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Jean Dinu??? Adamclisi', 'Lic Teh Adamclisi', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Jidvei', 'Lic. Teh. Jidvei', 'AB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Jimbolia', 'Lic. Teh. Jimbolia', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Joannes Kajoni??? Miercurea Ciuc', 'Gri ???Joannes Kajoni??? Miercurea Ciuc', 'HR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Johannes Lebel??? T??lmaciu', 'Lic Tehn ???J. Lebel??? T??lmaciu', 'SB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Justinian Marina, Oras Baile Olanesti', 'Lic Teh Justinian Marina Baile Olanesti', 'VL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???K??s K??roly??? Miercurea Ciuc', 'Gri ???Kos Karoly??? Miercurea Ciuc', 'HR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???K??s K??roly??? Odorheiu Secuiesc', 'Gri ???Kos Karoly??? Odorhei', 'HR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???K??s K??roly??? Sf??ntu Gheorghe', 'Lic. Tehn. ???K??s K??roly??? Sf??ntu Gheorghe', 'CV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Laz??r Edeleanu???, Municipiul Ploie??ti', 'Liceul ???Lazar Edeleanu??? Ploiesti', 'PH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Laz??r Edeleanu??? N??vodari', 'Lic Tehnologic ???Laz??r Edeleanu??? N??vodari', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Lechin??a', 'Lic Teh Lechin??a', 'BN');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Liviu Rebreanu??? B??lan', 'Gri ???Liviu Rebreanu??? Balan', 'HR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Liviu Rebreanu??? Hida', 'Lic. Tehnologic ???L. Rebreanu??? Hida', 'SJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Liviu Rebreanu??? Maieru', 'Lic Teh ???L.R.??? Maieru', 'BN');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Liviu Rebreanu??? Moz??ceni', 'Lic. Teh. Liviu Rebreanu Moz??ceni', 'AG');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Lorin S??l??gean???', 'Lic. Teh. L. Salagean', 'MH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Lucian Blaga??? Reghin', 'Lic. Tehn. ???L. Blaga??? Reghin', 'MS');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic Lupeni', 'HD');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Malaxa??? Z??rne??ti', 'Liceul Tehnologic Z??rne??ti', 'BV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Marcel Guguianu???, Sat Zorleni', 'Lic. Tehn Marcel Guguianu', 'VS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Marin Grigore N??stase??? T??rt????e??ti', 'Liceul Tehnologic T??rt????e??ti', 'DB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Marmatia??? Sighetu Marmatiei', 'Lth Marmatia Sighet', 'MM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Matei Basarab???', 'Lic. Teh. ???Matei Basarab???', 'MH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Matei Basarab??? Caracal', 'Liceul Tehn ???Matei Basarab??? Caracal', 'OT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Matei Basarab??? Manastirea', 'Lic. Tehnologic ???Matei Basarab??? Manastirea', 'CL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Matei Basarab??? M??xineni', 'Liceul Tehnologic ???Matei Basarab???', 'BR');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic ???Matei Corvin??? Hunedoara', 'HD');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Max Ausnit??? Caransebe??', 'Lth Max Ausnit Caransebes', 'CS');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic M??cin', 'TL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic M??r??a', 'Lic Tehn M??r??a', 'SB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Mecanic, Municipiul C??mpina', 'Liceul Tehnologic Mecanic, Municipiul Campina', 'PH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Metalurgic Slatina', 'Liceul Tehn Metalurgic Slatina', 'OT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Mihai Busuioc???, Pa??cani', 'Lic Teh ???M. Busuioc??? Pascani', 'IS');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic ???Mihai Eminescu??? Dumbr??veni', 'SV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Mihai Eminescu??? Slobozia', 'Liceul Teh. ???Mihai Eminescu??? Slobozia', 'IL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Mihai Novac??? Oravi??a', 'Lth ???Mihai Novac??? Oravi??a', 'CS');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic ???Mihai Viteazu??? Vulcan', 'HD');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Mihai Viteazul??? C??lug??reni', 'Lic. Teh. ???Mihai Viteazul??? Calugareni', 'GR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Mihai Viteazul??? Mihai Viteazu', 'Lic Tehnologic Mihai Viteazu', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Mihai Viteazul??? Zal??u', 'Lic. Tehnologic ???M. Viteazul??? Zal??u', 'SJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Mircea Vulc??nescu???', 'Lic. Tehnol. ???M. Vulc??nescu???', 'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic ???Moga Voievod??? H??lmagiu', 'AR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Nicanor Moro??an??? P??rtestii de Jos', 'Liceul Tehnologic ???N. Moro??an??? P??rte??tii de Jos',
        'SV');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic ???Nicolae Balcescu??? Flam??nzi', 'BT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Nicolae Balcescu??? Oltenita', 'Lic. Tehnologic ???N. Balcescu??? Oltenita', 'CL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Nicolae B??lcescu??? Alexandria', 'Lth ???Nicolae B??lcescu??? Alexandria', 'TR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Nicolae B??lcescu??? Bal??', 'Liceul Tehn ???N. Balcescu??? Bals', 'OT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Nicolae B??lcescu??? ??ntorsura Buz??ului', 'Lic. Tehn. ???Nicolae B??lcescu??? ??ntorsura Buz??ului',
        'CV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Nicolae B??lcescu??? Voluntari', 'Liceul Tehnologic ???Nicolae Balcescu??? Voluntari', 'IF');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic ???Nicolae Cior??nescu??? T??rgovi??te', 'DB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Nicolae Dumitrescu??? Cump??na', 'Lic Tehnologic Cump??na', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Nicolae Iorga???, Ora?? Negre??ti', 'Lic. Tehn Negre??ti', 'VS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Nicolae Istr????oiu??? Deleni', 'Lic Tehnologic Deleni', 'CT');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic ???Nicolae Oncescu???', 'BR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Nicolae Stoica de Ha??eg??? Mehadia', 'Lth ???Nicolae Stoica de Hateg??? Mehadia', 'CS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Nicolae Teclu??? Cop??a Mic??', 'Lic Tehn ???N. Teclu??? Cop??a Mic??', 'SB');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic ???Nicolae Titulescu??? ??nsur????ei', 'BR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Nicolae Titulescu??? Medgidia', 'Lic Tehn ???Nicolae Titulescu??? Medgidia', 'CT');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic ???Nicolai Nanu??? Bro??teni', 'SV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Nicolaus Olahus??? Or????tie', 'Lic. Tehn. ???Nicolaus Olahus??? Or????tie', 'HD');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Nikola Tesla???', 'Lic. Tehn. ???Nikola Tesla???', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Nisipore??ti, Comuna Bote??ti', 'Lt, Nisipore??ti', 'NT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Nr. 1 Alexandria', 'Lth Nr. 1 Alexandria', 'TR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Nr. 1 Bal??', 'Liceul Tehn Nr. 1 Bals', 'OT');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic Nr. 1 C??mpulung Moldovenesc', 'SV');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic Nr. 1 Cluj-Napoca', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Nr. 1 M??r??cineni', 'Lic. Teh. Nr. 1 M??r??cineni', 'AG');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Nr. 2 Ro??iori de Vede', 'Lth Nr. 2 Ro??iori de Vede', 'TR');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic Nr. 1 Borcea', 'CL');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic Nr. 1 Cadea', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Nr. 1 Comana', 'Lic. Tehn. Nr. 1 Comana', 'GR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Nr. 1, Comuna Corod', 'Lic. Teh. Nr. 1 Corod', 'GL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Nr. 1, Comuna Cudalbi', 'Lic. Teh. Nr. 1 Cudalbi', 'GL');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic Nr. 1 Dobre??ti', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Nr. 1 Fundulea', 'Lic. Tehnologic Nr. 1 Fundulea', 'CL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Nr. 1 G??lg??u', 'Lic. Tehnologic Nr. 1 G??lg??u', 'SJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Nr. 1 Ludu??', 'Lic. Tehn. Nr. 1 Ludu??', 'MS');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic Nr. 1 Pope??ti', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Nr. 1 Prundu', 'Lic. Teh. Nr. 1 Prundu', 'GR');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic Nr. 1 Salonta', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Nr. 1 S??rm????ag', 'Lic. Tehnologic Nr. 1 S??rm????ag', 'SJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Nr. 1 Sighi??oara', 'Lic. Tehn. Nr. 1 Sighi??oara', 'MS');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic Nr. 1 Suplacu de Barc??u', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Nr. 1 Surduc', 'Lic. Tehnologic Nr. 1 Surduc', 'SJ');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic Nr. 1 ??uncuiu??', 'BH');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic Nr. 1 Valea Lui Mihai', 'BH');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic Nucet', 'DB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Ocna Mures', 'Lic. Teh. Ocna Mures', 'AB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Ocna Sugatag', 'Lth Ocna Sugatag', 'MM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Octavian Goga??? Jibou', 'Lic. Tehnologic ???O. Goga??? Jibou', 'SJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Octavian Goga??? Rozavlea', 'Lth O Goga Rozavlea', 'MM');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic ???Oltea Doamna??? Dolhasca', 'SV');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic One??ti', 'BC');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic, Oras Baile Govora', 'Lic Teh Baile-Govora', 'VL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Ora?? P??t??rlagele', 'Lic Tehn P??t??rlagele', 'BZ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Ovid Caledoniu???, Localitatea Tecuci', 'Lic. Teh. ???O. Caledoniu??? Tc', 'GL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Ovid Densusianu??? C??lan', 'Lic Tehn. ???O. Densusianu??? C??lan', 'HD');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Pamfil ??eicaru??? Ciorog??rla', 'Liceul Tehnologic ???Pamfil Seicaru??? Ciorogarla', 'IF');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic ???Panait Istrati??? Br??ila', 'BR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Paul Bujor???, Oras Beresti', 'Lic. Teh. ???P. Bujor??? Beresti', 'GL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Paul Dimo???, Municipiul Galati', 'Lic. Teh. ???P. Dimo??? Gl', 'GL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Pet??fi S??ndor??? D??ne??ti', 'Lit ???Petofi Sandor??? Danesti', 'HR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Petrache Poenaru, Oras Balcesti', 'Lic Teh P. Poenaru Balcesti', 'VL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Petre Banita??? Calarasi', 'Liceul Calarasi', 'DJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Petre Ionescu Muscel??? Domne??ti', 'Lic. Teh. Petre Ionescu Muscel Domne??ti', 'AG');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Petre Mitroi??? Biled', 'Lic. Teh. P. Mitroi Biled', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Petre P. Carp???, ??ib??ne??ti', 'Lic Teh Tibanesti', 'IS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Petri Mor??? Nu??fal??u', 'Lic. Tehnologic ???Petri Mor??? Nu??fal??u', 'SJ');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic Petrol Moreni', 'DB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Petru Cupcea??? Supuru de Jos', 'Lteh ???Petru Cupcea??? Supuru de Jos', 'SM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Petru Maior??? Reghin', 'Lic. Tehn. ???P. Maior??? Reghin', 'MS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Petru Poni???', 'Lic. Tehnol. ???Petru Poni???', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Petru Poni???, Ia??i', 'Lic Teh ???P. Poni??? Iasi', 'IS');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic ???Petru Poni??? One??ti', 'BC');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic ???Petru Rare????? Bac??u', 'BC');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic ???Petru Rare????? Botosani', 'BT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Petru Rare?????, Mun. B??rlad', 'Lic. Tehn B??rlad', 'VS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Petru Rare?????, Sat Vetri??oaia', 'Lic. Tehn Vetri??oaia', 'VS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Petru Rare?????, T??rgu Frumos', 'Lic Teh Tg. Frumos', 'IS');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic Piatra-Olt', 'OT');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic Plopenii Mari', 'BT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Poienile de Sub Munte', 'L Tehn Pdsm', 'MM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Pontica??? Constan??a', 'Lic Teh ???Pontica??? C??a', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???P.S. Aurelian??? Slatina', 'Liceul Tehn ???P.S. Aurelian??? Slatina', 'OT');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic Pucioasa', 'DB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Pusk??s Tivadar??? Ditr??u', 'Gri ???Puskas Tivadar??? Ditrau', 'HR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Pusk??s Tivadar??? Sf??ntu Gheorghe', 'Lic. Tehn. ???Pusk??s Tivadar??? Sf??ntu Gheorghe', 'CV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Radu Negru???, Localitatea Galati', 'Lic. Teh. ???R. Negru??? Gl', 'GL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Radu Pri??cu??? Dobromir', 'Lic Tehnologic Dobromir', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic R??chitoasa', 'Liceul Tehnologic Rachitoasa', 'BC');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic R????nov', 'BV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Regele Mihai I Curtea de Arge??', 'Lic. Teh. Forestier Curtea de Arge??', 'AG');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic ???Regele Mihai I??? S??v??r??in', 'AR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Repedea', 'Lth Repedea', 'MM');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic ???Retezat??? Uricani', 'HD');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Romulus Paraschivoiu??? Lovrin', 'Lic. Teh. R. Paraschivoiu Lovrin', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Rosia de Amaradia', 'Lic Teh Rosia de Amaradia', 'GJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Rosia Jiu, Farcasesti', 'Lic. Teh. Rosia Jiu Farcasesti', 'GJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Ruscova', 'Lth Ruscova', 'MM');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic ???Sandu Aldea??? Calarasi', 'CL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Sanitar ???Vasile Voiculescu??? Oradea', 'Liceul Tehnologic Sanitar ???V. Voiculescu??? Oradea',
        'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic, Sat Cioranii de Jos, Comuna Ciorani', 'Liceul Tehnologic Cioranii de Jos', 'PH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic, Sat M??rg??ri??i Comuna Beceni', 'Liceul Beceni', 'BZ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic, Sat Puie??ti', 'Lic. Tehn Puie??ti', 'VS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic, Sat Vladia', 'Lic. Tehn Vladia', 'VS');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic ???Sava Brancovici??? Ineu', 'AR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Sebes', 'Lic. Teh. Sebes', 'AB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Sf. Antim Ivireanu???', 'Lic. Tehnol. ???Sf. Antim Ivireanu???', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Sf. Haralambie??? Turnu M??gurele', 'Lth ???Sf. Haralambie??? Turnu M??gurele', 'TR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Sf. Mucenic Sava??? Comuna Berca', 'Lic Teh Berca', 'BZ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Sfantul Ioan???, Localitatea Galati', 'Lic. Teh. ???Sf. Ioan??? Gl', 'GL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Sf??ntu Nicolae??? Deta', 'Lic. Tehn. ???Sf. Nicolae??? Deta', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Sf??ntul Gheorghe??? S??ngeorgiu de P??dure', 'Lic. Tehn. ???Sf. Gheorghe??? S??ngeorgiu de P??dure',
        'MS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Sf??ntul Ioan de La Salle???, Sat Pilde??ti, Comuna Cordun',
        'Lt ???Sf??ntul Ioan de La Salle???, Pilde??ti', 'NT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Sf??ntul Pantelimon???', 'Lic. Tehn. ???Sf??ntul Pantelimon???', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Sf. Dimitrie??? Teregova', 'Lth Teregova', 'CS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Sf. Ecaterina??? Urziceni', 'Liceul Teh. ???Sf. Ecaterina??? Urziceni', 'IL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Silvic Cimpeni', 'Lic. Teh. Silvic Cimpeni', 'AB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Silvic ???Dr. Nicolae Ruc??reanu??? Bra??ov', 'Liceul Silvic Bra??ov', 'BV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Simion B??rnu??iu??? Carei', 'Lteh ???Simion B??rnu??iu??? Carei', 'SM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Simion Leonescu??? Luncavi??a', 'Liceul ???S. Leonescu??? Luncavi??a', 'TL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Simion Mehedinti???, Localitatea Galati', 'Lic. Teh. ???S. Mehedinti??? Gl', 'GL');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic ???Some????? Dej', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???S??v??r Elek??? Joseni', 'Gri ???Sover Elek??? Joseni', 'HR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Special ???Beethoven??? Craiova', 'Liceul Special Beethoven Craiova', 'DJ');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic Special Bivolarie', 'SV');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic Special Dej', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Special Drobeta', 'Lic. Teh. Drobeta', 'MH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Special ???Gheorghe Atanasiu??? Timi??oara', 'Lic. Teh. Spec. Gheorghe Atanasiu Timisoara', 'TM');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic Special Gherla', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Special Nr. 3', 'Lic. Tehn. Spec. Nr. 3', 'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic Special Nr. 1 Oradea', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Special Pentru Copii Cu Deficien??e Auditive Municpiul Buz??u', 'Lic Def Aud Buz??u', 'BZ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Special Pentru Deficien??i de Auz Cluj-Napoca',
        'Liceul Tehnologic Special Pentru Def. de Auz Cluj', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Special ???Regina Elisabeta???', 'Lic. Tehn. Spec. ???Regina Elisabeta???', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Special ???Vasile Pavelcu???, Ia??i', 'Lic Spec ???V. Pavelcu??? Iasi', 'IS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Special ???Pelendava??? Craiova', 'Lic. Special ???Pelendava??? Craiova', 'DJ');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic ???Spiru Haret??? T??rgovi??te', 'DB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???St??nescu Valerian??? T??rnava', 'Lic Tehn ???St??nescu Valerian??? Tirnava', 'SB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Stefan Anghel??? Bailesti', 'Liceul Stefan Anghel Bailesti', 'DJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Stefan Cel Mare Si Sfant??? Vorona', 'Lic. Tehnologic ???Stefan Cel Mare Si Sfant??? Vorona',
        'BT');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic ???Stefan Hell??? S??ntana', 'AR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Stefan Manciulea??? Blaj', 'Lic. Teh. ???St. Manciulea??? Blaj', 'AB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Stefan Milcu??? Calafat', 'Liceul Stefan Milcu Calafat', 'DJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Stefan Odobleja??? Craiova', 'Liceul Stefan Odobleja Craiova', 'DJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Stoina', 'Lic Teh Stoina', 'GJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Sz??kely K??roly??? Miercurea Ciuc', 'Gri ???Szekely Karoly??? Miercurea Ciuc', 'HR');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic ?????tefan Cel Mare??? Cajvana', 'SV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Tara Motilor??? Albac', 'Lic. Teh. Albac', 'AB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Tarna Mare', 'Lteh Tarna Mare', 'SM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Tase Dumitrescu???, Ora??ul Mizil', 'Liceul Tehnologic ???Tase Dumitrescu??? Mizil', 'PH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic T????nad', 'Lteh T????nad', 'SM');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic T??rgu Ocna', 'BC');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic T??rn??veni', 'Lic. Tehn. T??rn??veni', 'MS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Telciu', 'Lic Teh Telciu', 'BN');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Teodor Diamant???, Ora??ul Bolde??ti-Sc??eni',
        'Liceul Tehnologic ???Teodor Diamant??? Boldesti-Scaen', 'PH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Theodor Pallady', 'Lic. Teh. Theodor Pallady', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Ticleni', 'Lic Teh Ticleni', 'GJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Timotei Cipariu??? Blaj', 'Lic. Teh. ???T. Cipariu??? Blaj', 'AB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Tismana', 'Lic Teh Tismana', 'GJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Tiu Dumitrescu??? Mih??ile??ti', 'Lic. Tehnologic ???Tiu Dumitrescu??? Mihailesti', 'GR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Tivai Nagy Imre??? S??nmartin', 'Gri ???Tivai Nagy Imre??? S??nmartin', 'HR');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic Todireni', 'BT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Toma Socolescu???, Municipiul Ploie??ti', 'Liceul Tehnic ???Toma Socolescu??? Ploiesti', 'PH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Tomis??? Constan??a', 'Lic Teh ???Tomis??? C??a', 'CT');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic ???Tom??a Vod????? Solca', 'SV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Topolog', 'Liceul Topolog', 'TL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Topoloveni', 'Lic. Teh. Topoloveni', 'AG');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Topraisar', 'Lic Tehnologic Topraisar', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Traian Groz??vescu??? N??drag', 'Lic. Teh. Tr. Grozavescu Nadrag', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Traian S??vulescu??? Municipiul R??mnicu S??rat', 'Lic. Teh. S??vulescu', 'BZ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Traian Vuia??? Tautii-Magheraus', 'Lth T Vuia Tautii-Magheraus', 'MM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Traian Vuia??? T??rgu Mure??', 'Lic. Tehn. ???T. Vuia??? Tg. Mure??', 'MS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Trandafir Coc??rl????? Caransebe??', 'Lth ???Trandafir Coc??rl????? Caransebe??', 'CS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Transilvania??? Baia Mare', 'Lth Transilvania Bm', 'MM');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic ???Transilvania??? Deva', 'HD');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Transporturi Auto Calarasi', 'Lic. Tehnologic de Transporturi Auto Calarasi', 'CL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Transporturi Auto Timi??oara', 'Lic. Teh. Transp. Auto Timisoara', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Transporturi Cai Ferate Craiova', 'Liceul Transporturi Cfr Craiova', 'DJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Tudor Vladimirescu???', 'Lic. Teh. T. Vladimirescu', 'MH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Tudor Vladimirescu???, Comuna Tudor Vladimirescu', 'Lic. Teh. ???T. Vladimirescu??? T.Vladim.',
        'GL');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic Tufeni', 'OT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Turburea', 'Lic Teh Turburea', 'GJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Turceni', 'Lic Teh Turceni', 'GJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ????nd??rei', 'Liceul Teh. ????nd??rei', 'IL');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic Ucecom ???Spiru Haret??? Arad', 'AR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Ucecom ???Spiru Haret??? Baia Mare', 'Lth Ucecom Spiru Haret Bm', 'MM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Ucecom ???Spiru Haret??? Breaza', 'Liceul Ucecom ???Spiru Haret??? Breaza', 'PH');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic Ucecom ???Spiru Haret??? Cluj-Napoca', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Ucecom ???Spiru Haret??? Constan??a', 'Lic Tehnologic ???Spiru Haret??? C??a', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Ucecom ???Spiru Haret??? Craiova', 'Liceul Ucecom', 'DJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Ucecom ???Spiru Haret???, Iasi', 'Lic Teh Ucecom Iasi', 'IS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Ucecom ???Spiru Haret??? Ploie??ti', 'Liceul Ucecom ???Spiru Haret??? Ploiesti', 'PH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Ucecom ???Spiru Haret??? Timi??oara', 'Lic. Teh. Ucecom ???Spiru Haret??? Timisoara', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Udrea B??leanu??? B??leni', 'Liceul Tehnologic ???Udrea B??leanu??? B??leni', 'DB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Unio-Traian Vuia??? Satu Mare', 'Lteh ???Unio-Traian Vuia??? Sm', 'SM');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic ???Unirea??? ??tei', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Urziceni', 'Liceul Teh. Urziceni', 'IL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Valeriu Brani??te??? Lugoj', 'Lic. Teh. ???V. Braniste??? Lugoj', 'TM');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic ???Vasile Cocea??? Moldovi??a', 'SV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Vasile Deac??? Vatra Dornei', 'Liceul Tehnologic ???Vasile Deac??? Vatra Dornei', 'SV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Vasile Gherasim??? Marginea', 'Liceul Tehnologic ???V. Gherasim??? Marginea', 'SV');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic ???Vasile Juncu??? Mini??', 'AR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Vasile Netea??? Deda', 'Lic. Tehn. ???V. Netea??? Deda', 'MS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Vasile Sav???, Municipiul Roman', 'Ltvs, Roman', 'NT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic V??leni', 'Liceul Teh. Valeni', 'OT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Vedea', 'Lic. Teh. Vedea', 'AG');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Venczel J??zsef??? Miercurea Ciuc', 'Gri ???Venczel Jozsef??? Mierecurea Ciuc', 'HR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Victor Frunz????? Municipiul R??mnicu S??rat', 'Lic. Teh. V. Frunz??', 'BZ');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic ???Victor Jinga??? S??cele', 'BV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Victor Mih??ilescu Craiu???, Belce??ti', 'Lic Teh Belcesti', 'IS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Victor Sl??vescu??? Ruc??r', 'Lic. Teh. Victor Sl??vescu Ruc??r', 'AG');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic Vinga', 'AR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Vintil?? Br??tianu??? Dragomire??ti Vale', 'Liceul Tehnolog ???Vintila Bratianu??? Dragomiresti Val',
        'IF');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic ???Virgil Madgearu??? Cluj-Napoca', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Virgil Madgearu??? Ro??iori de Vede', 'Lth ???Virgil Madgearu??? Ro??iori de Vede', 'TR');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic ???Virgil Madgearu??? Suceava', 'SV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Viseu de Sus', 'Lth Viseu', 'MM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Vitomire??ti', 'Liceul Teh. Vitomiresti', 'OT');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic ???Vl??deasa??? Huedin', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic, Vl??deni', 'Lic Teh Vladeni', 'IS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Voievodul Gelu??? Zal??u', 'Lic. Tehnologic ???V. Gelu??? Zal??u', 'SJ');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic Voine??ti', 'DB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Zeyk Domokos??? Cristuru Secuiesc', 'Gri ???Zeyk Domokos??? Cristur', 'HR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???Zimmethausen??? Borsec', 'Gri ???Zimmethausen??? Borsec', 'HR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic ???1 Mai???, Municipiul Ploie??ti', 'Liceul Tehnologic ???1 Mai???, Municipiul Ploiesti', 'PH');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teologic Adventist Craiova', 'DJ');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teologic Adventist ???Maranatha??? Cluj-Napoca', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teologic Adventist ?????tefan Demetrescu???', 'Lic. Teo. Adv. ?????t. Demetrescu???', 'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teologic Baptist ???Alexa Popovici??? Arad', 'AR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teologic Baptist ???Betania??? Sibiu', 'Liceul Betania Sibiu', 'SB');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teologic Baptist ???Emanuel??? Cluj-Napoca', 'CJ');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teologic Baptist ???Emanuel??? Oradea', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teologic Baptist ???Logos???', 'Lic. Teol. Baptist ???Logos???', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teologic Baptist Re??i??a', 'Lic Teologic Baptist', 'CS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teologic Baptist Timi??oara', 'Lic. Teologic Baptist Timisoara', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teologic ???Elim??? Pite??ti', 'Lic. Teol. Elim Pite??ti', 'AG');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teologic ???Episcop Melchisedec???, Municipiul Roman', 'L Teol ???Episcop Melchisedec???, Roman', 'NT');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teologic ???Fericitul Ieremia??? One??ti', 'BC');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teologic Greco-Catolic ???Sfantul Vasile Cel Mare??? Blaj', 'Lic. Teologic Blaj', 'AB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teologic Ortodox ???Cuvioasa Parascheva???, Comuna Agapia', 'Lic Teol ???Cuvioasa Parascheva???, Agapia', 'NT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teologic Ortodox ???Nicolae Steinhardt??? Satu Mare', 'Licteo ???Nicolae Steinhardt???', 'SM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teologic Ortodox ???Sf. Constantin Br??ncoveanu??? F??g??ra??', 'Liceul Teologic Ortodox F??g??ra??', 'BV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teologic Ortodox ???Sf??ntul Antim Ivireanul??? Timi??oara',
        'Lic. Teolog. Ort. Sf. Antim Ivireanul Timisoara', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teologic Ortodox ???Sfin??ii ??mpara??i Constantin ??i Elena???, Municipiul Piatra-Neam??',
        'Lic Teo ???Sf. ??mp C-Tin ??i Elena???, Piatra Neam??', 'NT');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teologic Penticostal Arad', 'AR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teologic Penticostal Baia Mare', 'Lteol Penticostal Bm', 'MM');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teologic Penticostal ???Betel??? Oradea', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teologic Penticostal ???Emanuel???', 'Lic. Teo. Penti. ???Emanuel???', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teologic Penticostal Logos Timi??oara', 'Lic. Teologic Logos Timisoara', 'TM');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teologic Reformat Cluj-Napoca', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teologic Reformat Sf??ntu Gheorghe', 'Lic. Teol. Ref. Sf??ntu Gheorghe', 'CV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teologic Reformat T??rgu Secuiesc', 'Lic. Teol. Ref. T??rgu Secuiesc', 'CV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teologic Romano-Ii. R??k??czi T??rgu Mure??', 'Lic. Teol. Romano-Catolic T??rgu Mure??', 'MS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teologic Romano-Catolic ???Gerhardinum??? Timi??oara', 'Lic. Teologic Gerhardinum Timisoara', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teologic Romano-Catolic ???Grof Majlath Gusztav Karoly??? Alba Iulia', 'Lic. Teol. Rom. Cat. Alba Iulia',
        'AB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teologic Romano-Catolic ???Ham Janos??? Satu Mare', 'Licteo ???Ham Janos??? Sm', 'SM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teologic Romano-Catolic ???Segit?? M??ria??? Miercurea Ciuc', 'Ste ???Segito Maria??? Miercurea Ciuc', 'HR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teologic Romano-Catolic ???Sf??ntul Francisc de Assisi???, Municipiul Roman',
        'L Teol ???Sf??ntul Francisc de Assisi???, Roman', 'NT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teologic Romano-Catolic ???Szent Erzs??bet??? Lunca de Sus', 'Ste ???Szent Erzsebet??? Lunca de Sus', 'HR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teologic Romano-Catolic ???Szent Laszlo??? Oradea', 'Lic. Teol. Romano-Catolic ???Szent Laszlo??? Oradea',
        'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teologic Tg-Jiu', 'Lic. Teologic Tg-Jiu', 'GJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teologic Unitarian ???Berde M??zes??? Cristuru Secuiesc', 'Ste Unitarian Cristur', 'HR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Adam Muller Guttenbrunn??? Arad', 'Liceul Teoretic ???a.M. Guttenbrunn??? Arad', 'AR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Adrian Paunescu??? Barca', 'Liceul Teoretic Barca', 'DJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Ady Endre???', 'Lic. Teor. ???Ady Endre???', 'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic ???Ady Endre??? Oradea', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Alexandru Ghica??? Alexandria', 'Lte ???Al. D. Ghica??? Alexandria', 'TR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Alexandru Ioan Cuza???', 'Lic. Teor. ???Al. I. Cuza???', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Alexandru Ioan Cuza??? Corabia', 'Liceul Teo ???Al. I. Cuza??? Corabia', 'OT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Alexandru Ioan Cuza???, Ia??i', 'Lic ???Al. I. Cuza??? Iasi', 'IS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Alexandru Marghiloman??? Municipiul Buz??u', 'Lic. Marghiloman', 'BZ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Alexandru Mocioni??? Ciacova', 'Lic. Teor. ???a. Mocioni??? Oras Ciacova', 'TM');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic ???Alexandru Papiu Ilarian??? Dej', 'CJ');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic ???Alexandru Rosetti??? Vidra', 'IF');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Alexandru Vlahu???????', 'Lic. Teo. ???Alexandru Vlahu???????', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic Amarastii de Jos', 'Liceul Amarastii de Jos', 'DJ');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic ???Ana Ip??tescu??? Gherla', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Anastasie Basota??? Pom??rla', 'Lic. Teor. ???a. Basota??? Pom??rla', 'BT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Andrei B??rseanu??? T??rn??veni', 'Lic. Teor. ???a. B??rseanu??? T??rn??veni', 'MS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Anghel Saligny??? Cernavod??', 'Lic Teo ???Anghel Saligny??? Cernavod??', 'CT');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic ???Apaczai Csere Janos??? Cluj-Napoca', 'CJ');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic ???Arany Janos??? Salonta', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Atlas???', 'Lic. Teor. ???Atlas???', 'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic ???Aurel Laz??r??? Oradea', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Aurel Vlaicu???, Ora??ul Breaza', 'Liceul Teoretic ???Aurel Vlaicu??? Breaza', 'PH');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic ???Aurel Vlaicu??? Or????tie', 'HD');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic ???Avram Iancu??? Brad', 'HD');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic ???Avram Iancu??? Cluj-Napoca', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Axente Sever??? Media??', 'Lic Teor ???a. Sever??? Media??', 'SB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Bart??k B??la??? Timi??oara', 'Lic. Teor. ???Bart??k B??la??? Timisoara', 'TM');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic ???Bathory Istvan??? Cluj-Napoca', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic B??neasa', 'Lic Teo B??neasa', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic Bechet', 'Liceul Bechet', 'DJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Benjamin Franklin???', 'Lic. Teor. ???Benjamin Franklin???', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic Bilingv ???Ita Wegman???', 'Lic. Teor. Bilingv ???Ita Wegman???', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic Bilingv ???Miguel de Cervantes???', 'Liceul Teor. Bilingv ???M. de Cervantes???', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic Bilingv Rom??no-Croat Cara??ova', 'Lic Bilingv Romano-Croat Carasova', 'CS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Bocskai Istvan??? Miercurea Nirajului', 'Lic. Teor. ???Bocskai Istvan??? Miercurea Nirajului',
        'MS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Bogdan Voda??? Viseu de Sus', 'Lt B Voda Viseu', 'MM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Bogdan Vod?????, H??l??uce??ti', 'Lic Halaucesti', 'IS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Bolyai Farkas??? T??rgu Mure??', 'Lic. Teor. ???Bolyai Farkas??? Tg. Mure??', 'MS');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic ???Brassai Samuel??? Cluj-Napoca', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Br??ncoveanu Vod?????, Ora??ul Urla??i', 'Liceul Teoretic ???Brancoveanu Voda??? Urlati', 'PH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic Bulgar ???Hristo Botev???', 'Lic. Teo. Bulgar ???Hristo Botev???', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic Buzia??', 'Lic. Teor. Buzias', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???C.a. Rosetti???', 'Lic. Teor. ???C.a. Rosetti???', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Callatis??? Mangalia', 'Lic Teo ???Callatis??? Mangalia', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic Carei', 'Lit Carei', 'SM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Carmen Sylva??? Eforie', 'Lic Teoretic ???Carmen Sylva??? Eforie', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Carol I??? Fete??ti', 'Liceul Teo. ???Carol I??? Fete??ti', 'IL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic Centrul de Stefan Cel Mare Si Botosani', 'Lic T Centr de Studii Stefan Cel Mare Si Sfant Bt',
        'BT');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic Cermei', 'AR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic, Com. Gradistea', 'Lic Teo Gradistea', 'VL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic, Com. Maciuca', 'Lic. Teoretic Maciuca', 'VL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic, Comuna Filipe??tii de P??dure', 'Liceul Teoretic Filipesti Padure', 'PH');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic ???Constantin Angelescu???', 'BR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Constantin Brancoveanu??? Dabuleni', 'Liceul Dabuleni', 'DJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Constantin Br??tescu??? Isaccea', 'Liceul ???C. Br??tescu??? Isaccea', 'TL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Constantin Br??ncoveanu??? Bac??u', 'Lic. Teo. ???C-Tin Br??ncoveanu??? Bac??u', 'BC');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Constantin Noica??? Alexandria', 'Lte ???Constantin Noica??? Alexandria', 'TR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Constantin Noica??? Sibiu', 'Lic Teor ???C. Noica??? Sibiu', 'SB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Constantin Romanu Vivu??? Teaca', 'Lic Teo ???C.R. Vivu??? Teaca', 'BN');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic ???Constantin ??erban??? Ale??d', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Coriolan Brediceanu??? Lugoj', 'Lic. Teo. ???C. Brediceanu??? Mun. Lugoj', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic Coste??ti', 'Lic. Teor. Coste??ti', 'AG');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic Cre??tin ???Pro Deo??? Cluj-Napoca', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???C-Tin Br??ncoveanu???', 'Lic. Teo. ???C-Tin Br??ncoveanu???', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic Cujmir', 'Lic. Teo. Cujmir', 'MH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Dan Barbilian??? C??mpulung', 'Lic. Teor. Dan Barbilian C??mpulung', 'AG');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Dante Alighieri???', 'Lic. Teor. ???Dante Alighieri???', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???David Prodan??? Cugir', 'Lic. Teo. ???D.P.??? Cugir', 'AB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???David Voniga??? Giroc', 'Lic. Teor. ???David Voniga??? Giroc', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic de Informatic?? ???Grigore Moisil???, Ia??i', 'Lic ???Gr. Moisil??? Iasi', 'IS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Decebal???', 'Lic. Teor. ???Decebal???', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Decebal??? Constan??a', 'Lic Teoretic ???Decebal??? C??a', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Dimitrie Bolintineanu???', 'Lic. Teo. ???Dimitrie Bolintineanu???', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Dimitrie Cantemir???, Ia??i', 'Lic ???D. Cantemir??? Iasi', 'IS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Dositei Obradovici??? Timi??oara', 'Lic. Teor. ???D. Obradovici??? Timisoara', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Dr. I.C. Parhon???, Municipiul Piatra-Neam??', 'Lt ???Dr. I.C. Parhon???, Piatra-Neam??', 'NT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Dr. Lind??? C??mpeni??a', 'Lic. Teor. ???Dr. Lind??? C??mpeni??a', 'MS');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic ???Dr. Mihai Ciuca??? Saveni', 'BT');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic ???Dr. Mioara Mincu???', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Dr. P. Boros Fortunat??? Zetea', 'Lit ???Dr. P. Boros Fortunat??? Zetea', 'HR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Dr. Victor Gomoiu???', 'Lic. Teo. ???Dr. V. Gomoiu???', 'MH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Duiliu Zamfirescu??? Odobesti', 'Lic. Teor. ???Duiliu Zamfirescu??? Odobesti', 'VN');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic ???Dumitru T??u??an??? Flore??ti', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Dunarea???, Localitatea Galati', 'Lic. Teo. ???Dunarea??? Gl', 'GL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Educational Center??? Constan??a', 'Lic Teoretic ???Educational Center??? C??a', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Eftimie Murgu??? Bozovici', 'Lic Teoretic ???Eftimie Murgu??? Bozovici', 'CS');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic ???Elf??? Cluj-Napoca', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Emil Racovita??? Baia Mare', 'Lt E Racovita Bm', 'MM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Emil Racovita???, Localitatea Galati', 'Lic. Teo. ???E. Racovita??? Gl', 'GL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Emil Racovi???????, Mun. Vaslui', 'Lit Emil Racovi????', 'VS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Emil Racovi??????? Techirghiol', 'Lic Teoretic Techirghiol', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Eugen Lovinescu???', 'Lic. Teor. ???Eugen Lovinescu???', 'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic ???Eugen Pora??? Cluj-Napoca', 'CJ');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic ???Filadelfia??? Suceava', 'SV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Gabriel ??epelea??? Borod', 'Lit ???Gabriel ??epelea??? Borod', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic G??taia', 'Lic. Teor. Gataia', 'TM');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic ???Gelu Voievod??? Gil??u', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???General Dragalina??? Oravi??a', 'Lic Teoretic General Dragalina Oravita', 'CS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Genesis College???', 'Liceul Genesis', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???George C??linescu???', 'Lic. Teo. ???G. C??linescu???', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???George C??linescu??? Constan??a', 'Lic Teoretic ???George C??linescu??? C??a', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???George Emil Palade??? Constan??a', 'Lic Teoretic ???G E Palade??? C??a', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???George Moroianu??? S??cele', 'Liceul Teoretic ???G. Moroianu??? S??cele', 'BV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???George Pop de Basesti??? Baia Mare', 'Lt G Pop de Basesti Bm', 'MM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???George Pop de Basesti??? Sighetu Marmatiei', 'Lt G Pop de Basesti Sighet', 'MM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???George Pop de Basesti??? Targu Lapus', 'Lt G Pop de Basesti Tg Lapus', 'MM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???George Pop de Basesti??? Ulmeni', 'Lt G Pop de Basesti Ulmeni', 'MM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???George Pop de Basesti??? Viseu de Sus', 'Lt G Pop de Basesti Viseu', 'MM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???George Pop de B??se??ti??? Satu Mare', 'Lic ???George Pop de B??se??ti??? Sm', 'SM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???George St. Marincu??? Poiana Mare', 'Liceul Poiana Mare', 'DJ');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic ???George V??lsan???', 'BR');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic German ???Friedrich Schiller??? Oradea', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic German ???Johann Ettinger??? Satu Mare', 'Ltg ???Johann Ettinger??? Sm', 'SM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Gh. Vasilichi??? Cetate', 'Liceul Gh. Vasilichi Cetate', 'DJ');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic Ghelari', 'HD');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Gheorghe Ionescu ??i??e??ti???', 'Lic. Teor. ???Gh. Ionescu-Sisesti???', 'MH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Gheorghe Laz??r??? Avrig', 'Lic Teor ???Gh. Laz??r??? Avrig', 'SB');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic ???Gheorghe Laz??r??? Pecica', 'AR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Gheorghe Marinescu??? T??rgu Mure??', 'Lic. Teor. ???G. Marinescu??? Tg. Mures', 'MS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Gheorghe Munteanu Murgoci??? M??cin', 'Liceul ???G.M. Murgoci??? M??cin', 'TL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic Gheorghe Surdu, Oras Brezoi', 'Lic Teo Gh. Surdu Brezoi', 'VL');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic ???Grigore Antipa??? Botosani', 'BT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Grigore Gheba??? Dumitresti', 'Lic. Teor. ???Grigore Gheba??? Dumitresti', 'VN');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Grigore Moisil??? Timi??oara', 'Lic. Teor. Gr. Moisil Timisoara', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Grigore Moisil??? Tulcea', 'Liceul ???G. Moisil??? Tulcea', 'TL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Grigore Tocilescu???, Ora??ul Mizil', 'Liceul Teoretic ???G. Tocilescu??? Mizil', 'PH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Gustav Gundisch??? Cisn??die', 'Lic Teor ???G. Gundisch??? Cisn??die', 'SB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Harul??? Lugoj', 'Lic. Teo. ???Harul??? Lugoj', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Henri Coanda??? Craiova', 'Liceul Henri Coanda Craiova', 'DJ');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic ???Henri Coand????? Bac??u', 'BC');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic ???Henri Coand????? Dej', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Henri Coand????? Feldru', 'Lic Teo ???H. Coand????? Feldru', 'BN');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic ???Henri Coand????? Oradea', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Henri Coand????? Timi??oara', 'Lic. Partic. ???H. Coanda??? Timisoara', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Horea Clo??ca ??i Cri??an??? Cluj-Napoca', 'Liceul Teoretic ???Horea Clo??ca ??i Cri??an??? Cluj-N',
        'CJ');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic ???Horia Hulubei??? M??gurele', 'IF');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic ???Horvath Janos??? Marghita', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Hyperion???', 'Liceul Hyperion', 'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic ???I.C. Br??tianu??? Ha??eg', 'HD');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic ???Iancu C Vissarion??? Titu', 'DB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???I.C. Dr??gu??anu??? Victoria', 'Liceul Teoretic Victoria', 'BV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Independenta??? Calafat', 'Liceul Independenta Calafat', 'DJ');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic Interna??ional Bucure??ti', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic Interna??ional de Informatic?? Bucuresti', 'Liceul de Informatic??', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic Interna??ional de Informatic?? Constan??a', 'Lic Teoretic de Informatic?? C??a', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Ioan Buteanu??? Somcuta Mare', 'Lt I Buteanu Somcuta', 'MM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Ioan Cotovu??? H??r??ova', 'Lic Teoretic ???Ioan Cotovu??? H??r??ova', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Ioan Jebelean??? S??nnicolau Mare', 'Lic. Teor. I. Jebelean Sannicolau Mare', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Ioan Pascu??? Codlea', 'Liceul Teoretic Codlea', 'BV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Ioan Petru????? Otopeni', 'Liceul Teoretic ???Ioan Petrus??? Otopeni', 'IF');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Ioan Slavici??? Panciu', 'Lic. Teor. ???Ioan Slavici??? Panciu', 'VN');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Ion Ag??rbiceanu??? Jibou', 'L.T.???I. Ag??rbiceanu???  Jibou', 'SJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Ion Barbu???', 'Lic. Teo. ???Ion Barbu???', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Ion Barbu??? Pite??ti', 'Lic. Teor. Ion Barbu Pite??ti', 'AG');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Ion Borcea??? Buhu??i', 'Liceul Teoretic ???I. Borcea??? Buhusi', 'BC');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Ion Cantacuzino??? Pite??ti', 'Lic. Teor. Ion Cantacuzino Pite??ti', 'AG');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Ion Creang????? Tulcea', 'Liceul ???I. Creang????? Tulcea', 'TL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Ion Gh. Ro??ca??? Osica de Sus', 'Lic. Teor. ???I.Gh.  Ro??ca??? Osica de Sus', 'OT');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic ???Ion Ghica??? R??cari', 'DB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Ion Heliade R??dulescu??? T??rgovi??te', 'Liceul Teoretic ???Ion Heliade R??dulescu??? Tgv', 'DB');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic ???Ion Luca??? Vatra Dornei', 'SV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Ion Mihalache??? Topoloveni', 'Lic. Teor. Ion Mihalache Topoloveni', 'AG');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Ion Neculce???, T??rgu Frumos', 'Lic Teo ???I. Neculce??? Tg. Frumos', 'IS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Ioni???? Asan??? Caracal', 'Liceul Teo ???Ionita Asan??? Caracal', 'OT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Iulia Ha??deu??? Lugoj', 'Lic. Teo. ???I. Hasdeu??? Mun. Lugoj', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Iulia Zamfirescu??? Mioveni', 'Lic. Teor. Iulia Zamfirescu Mioveni', 'AG');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Jean Bart??? Sulina', 'Liceul ???J. Bart??? Sulina', 'TL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Jean Louis Calderon??? Timi??oara', 'Lic. Teor. ???J.L. Calderon??? Timisoara', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Jean Monnet???', 'Lic. Teo ???Jean Monnet???', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Joseph Haltrich??? Sighi??oara', 'Lic. Teor. ???Joseph Haltrich??? Sighi??oara', 'MS');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic ???Josika Miklos??? Turda', 'CJ');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic ???Jozef Gregor Tajovsky??? N??dlac', 'AR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Jozef Kozacek??? Budoi', 'Lit ???Jozef Kozacek??? Budoi', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Kem??ny J??nos??? Topli??a', 'Lit ???Kemeny Janos??? Toplita', 'HR');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic ???Kem??ny Zsigmond??? Gherla', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Lasc??r Rosetti???, R??duc??neni', 'Lic Raducaneni', 'IS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Leowey Klara??? Sighetu Marmatiei', 'Lt L Klara Sighet', 'MM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Little London Pipera??? Voluntari', 'Liceul Teoretic ???Little London Pipera??? Voluntar', 'IF');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic ???Liviu Rebreanu??? Turda', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Lucian Blaga???', 'Lic. Teor. ???Lucian Blaga???', 'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic ???Lucian Blaga??? Cluj-Napoca', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Lucian Blaga??? Constan??a', 'Lic Teoretic ???Lucian Blaga??? C??a', 'CT');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic ???Lucian Blaga??? Oradea', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Marin Coman???, Localitatea Galati', 'Lic. Teo. ???M. Coman??? Gl', 'GL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Marin Preda???', 'Lic. Teor. ???Marin Preda???', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Marin Preda??? Turnu M??gurele', 'Lte ???Marin Preda??? Turnu M??gurele', 'TR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Mark Twain International School??? Voluntari',
        'Liceul Teoretic ???M. Twain International??? Voluntari', 'IF');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Mihai Eminescu??? Calarasi', 'Lic. ???Mihai Eminescu??? Calarasi', 'CL');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic ???Mihai Eminescu??? Cluj-Napoca', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Mihai Eminescu???, Mun. B??rlad', 'Lit Mihai Eminescu', 'VS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic Mihai Ionescu', 'Liceul Mihai Ionescu', 'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic ???Mihai Veliciu??? Chisineu-Cris', 'AR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Mihai Viteazul??? Bailesti', 'Liceul Mihai Viteazul Bailesti', 'DJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Mihai Viteazul??? Caracal', 'Lic. T.???Mihai Viteazul???  Caracal', 'OT');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic ???Mihai Viteazul??? Vi??ina', 'DB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Mihail Kog??lniceanu??? Mihail Kog??lniceanu', 'Lic Teoretic Mihail Kog??lniceanu', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Mihail Kog??lniceanu???, Mun. Vaslui', 'Lit Mihail Kog??lniceanu', 'VS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Mihail Kog??lniceanu??? Snagov', 'Liceul Teoretic ???Mihail Kogalniceanu??? Snagov', 'IF');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Mihail Sadoveanu???', 'Lic. Teor. ???Mihail Sadoveanu???', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Mihail S??ulescu??? Predeal', 'Liceul Teoretic Predeal', 'BV');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic ???Mihail Sebastian???', 'BR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Mikes Kelemen??? Sf??ntu Gheorghe', 'Lic. Teor. ???Mikes Kelemen??? Sf??ntu Gheorghe', 'CV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic Millenium Timi??oara', 'Lic. Teo. Millenium Timisoara', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Mircea Eliade??? ??ntorsura Buz??ului', 'Lic. Teor. ???Mircea Eliade??? Intorsura Buzaului', 'CV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Mircea Eliade???, Localitatea Galati', 'Lic. Teo. ???M. Eliade??? Gl', 'GL');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic ???Mircea Eliade??? Lupeni', 'HD');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Miron Costin???, Ia??i', 'Lic ???M. Costin??? Iasi', 'IS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Miron Costin???, Pa??cani', 'Lic Teo ???M. Costin??? Pascani', 'IS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Mitropolit Ioan Me??ianu??? Z??rne??ti', 'Liceul Teoretic Z??rne??ti', 'BV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic Murfatlar', 'Lic Teoretic Murfatlar', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Nagy M??zes??? T??rgu Secuiesc', 'Lic. Teor. ???Nagy M??zes??? T??rgu Secuiesc', 'CV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic National', 'Liceul National', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic Negre??ti Oa??', 'Ltn Negre??ti Oa??', 'SM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic Negru Vod??', 'Lic Teoretic Negru Vod??', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Nemeth Laszlo??? Baia Mare', 'Lt N Laszlo Bm', 'MM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???New Generation School???', 'Liceul New Generation School', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Nichita St??nescu???', 'Lic. Teor. ???Nichita St??nescu???', 'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic ???Nicolae B??lcescu??? Cluj-Napoca', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Nicolae B??lcescu??? Medgidia', 'Lic Teoretic ???Nicolae B??lcescu??? Medgidia', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Nicolae Cartojan??? Giurgiu', 'Lic. Teoretic ???Nicolae Cartojan???', 'GR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Nicolae Iorga???', 'Lic. Teo. ???Nicolae Iorga???', 'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic ???Nicolae Iorga???', 'BR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Nicolae Iorga???, Mun. B??rlad', 'Lit N. Iorga B??rlad', 'VS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Nicolae Iorga??? Ora?? Nehoiu', 'Lic Teo Nehoiu', 'BZ');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic ???Nicolae Jiga??? Tinca', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Nicolae Titulescu??? Slatina', 'Liceul Teo ???N. Titulescu??? Slatina', 'OT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Nikolaus Lenau??? Timi??oara', 'Lic. Teor. Nikolaus Lenau Timisoara', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic Novaci', 'Lic. Teoretic Novaci', 'GJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic Nr. 1 Peri??', 'Liceul Teoretic Nr. 1 Peris', 'IF');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic Nr. 1 Bratca', 'Lit Nr. 1 Bratca', 'BH');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic ???Octavian Goga??? Huedin', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???O.C. T??sl??uanu??? Topli??a', 'Lit ???O.C. Taslauanu??? Toplita', 'HR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic Olteni', 'Lte Olteni', 'TR');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic ???Onisifor Ghibu??? Cluj-Napoca', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Onisifor Ghibu??? Sibiu', 'Lic Teor ???Onisifor Ghibu??? Sibiu', 'SB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic Ora?? Pogoanele', 'Lic. Pogoanele', 'BZ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic, Ora??ul Azuga', 'Liceul Teoretic Azuga', 'PH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Orb??n Bal??zs??? Cristuru Secuiesc', 'Lit ???Orban Balazs??? Cristur', 'HR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Ovidius??? Constan??a', 'Lic Teoretic ???Ovidius??? C??a', 'CT');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic ???Panait Cerna???', 'BR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Paul Georgescu??? ????nd??rei', 'Liceul Teo. ???Paul Georgescu??? ????nd??rei', 'IL');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic ???Pavel Dan??? C??mpia Turzii', 'CJ');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic P??ncota', 'AR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic Peciu Nou', 'Lic. Teor. Peciu Nou', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic Periam', 'Lic. Teor. Periam', 'TM');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic ???Petofi Sandor??? S??cueni', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Petre Pandrea??? Bal??', 'Liceul Teor. ???P. Pandrea??? Bals', 'OT');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic ???Petru Cercel??? T??rgovi??te', 'DB');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic ???Petru Maior??? Gherla', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Petru Maior??? Ocna Mures', 'Lit ???P. Maior??? Ocna Mures', 'AB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Petru Rares??? Targu Lapus', 'Lt P Rares Tg Lapus', 'MM');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic ???Phoenix???', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic Piatra', 'Lte Piatra', 'TR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Pontus Euxinus??? Lumina', 'Lic Teoretic ???Pontus Euxinus??? Lumina', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Radu Petrescu??? Prundu B??rg??ului', 'Lic Teo ???R. Petrescu??? Prundu B??rg.', 'BN');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Radu Popescu??? Pope??ti Leordeni', 'Liceul Teoretic ???Radu Popescu??? Popesti Leordeni', 'IF');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Radu Vl??descu??? Ora?? P??t??rlagele', 'Lic. ???R. Vl??descu??? P??t??rlagele', 'BZ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic Reca??', 'Lic. Teor. Reca??', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Salamon Ern????? Gheorgheni', 'Lit ???Salamon Erno??? Gheorgheni', 'HR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Samuil Micu??? S??rma??u', 'Lic. Teor. ???S. Micu??? S??rma??u', 'MS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic Sanitar Bistri??a', 'Lic Teo Sanit Bistrita', 'BN');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic Scoala Europeana Bucuresti', 'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic ???Scoala Mea???', 'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic Sebi??', 'AR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Sfanta Maria???, Localitatea Galati', 'Lic. Teo. ???Sf. Maria??? Gl', 'GL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Sfantul Iosif??? Alba Iulia', 'Lic. Teo. ???Sf. Iosif??? Alba Iulia', 'AB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Sf??ntu Nicolae??? Gheorgheni', 'Lit ???Sfantu Nicolae??? Gheorgheni', 'HR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Sfin??ii Kiril ??i Metodii??? Dude??tii Vechi', 'Lic. Teor. Dudestii Vechi', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Sfin??ii Trei Ierarhi???', 'Liceul ???Sfin??ii Trei Ierarhi???', 'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic ???Silviu Dragomir??? Ilia', 'HD');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic Socrates Timi??oara', 'Lic. Teor. Socrates Timisoara', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Solomon Hali??????? S??ngeorz-B??i', 'Lic Teo ???S. Hail??????? S??ngeorz-B??i', 'BN');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic Special Iris Timi??oara', 'Lic. Teor. Spec. Iris Timisoara', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Spiru Haret??? Moine??ti', 'Liceul ???S. Haret??? Moine??ti', 'BC');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Stephan Ludwig Roth??? Media??', 'Lic Teor ???St. L. Roth??? Media??', 'SB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ?????erban Cioculescu???', 'Lic Teo. Serban Cioculescu', 'MH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ?????erban Vod?????, Ora??ul Sl??nic', 'Liceul Teoretic ???Serban Voda??? Slanic', 'PH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ?????tefan Cel Mare??? Municipiul R??mnicu S??rat', 'Lic. ??tefan', 'BZ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ?????tefan Odobleja???', 'Lic. Teo. ?????tefan Odobleja???', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Tam??si ??ron??? Odorheiu Secuiesc', 'Lit ???Tamasi Aron??? Odorhei', 'HR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Tata Oancea??? Boc??a', 'Lic Teoretic ???Tata Oancea??? Boc??a', 'CS');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic ???Teglas Gabor??? Deva', 'HD');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic Teius', 'AB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Traian???', 'Lic. Teor. ???Traian???', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Traian??? Constan??a', 'Lic Teoretic ???Traian??? C??a', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Traian Lalescu???', 'Lic. Teoretic ???Tr. Lalescu???', 'MH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Traian Lalescu??? Br??ne??ti', 'Liceul Teoretic ???Traian Lalescu??? Branesti', 'IF');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Traian Lalescu??? Hunedoara', 'Liceul Teoretic ???T. Lalescu??? Hunedoara', 'HD');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Traian Vuia??? F??get', 'Lic. Teor. ???Traian Vuia??? Faget', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Traian Vuia??? Re??i??a', 'Lic Teoretic ???Traian Vuia??? Re??i??a', 'CS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Tudor Arghezi??? Craiova', 'Liceul Tudor Arghezi Craiova', 'DJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Tudor Vianu??? Giurgiu', 'Lic. Teoretic ???Tudor Vianu???', 'GR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Tudor Vladimirescu???', 'Lic. Teor. ???Tudor Vladimirescu???', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Tudor Vladimirescu??? Dr??g??ne??ti-Olt', 'Lic. T.???T. Vladimirescu???  Draganesti', 'OT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Varlaam Mitropolitul???, Ia??i', 'Lic Varlaam Iasi', 'IS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Vasile Alecsandri???, Comuna S??b??oani', 'L Teoretic ???Vasile Alecsandri???, S??b??oani', 'NT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Vasile Alecsandri???, Ia??i', 'Lic ???V. Alecsandri??? Iasi', 'IS');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic ???Victor Babe????? Cluj-Napoca', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Victoria???', 'Liceul ???Victoria???', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic Videle', 'Lte Videle', 'TR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic Virgil Ierunca, Com. Ladesti', 'Lic Teo Ladesti', 'VL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???Vlad ??epe????? Timi??oara', 'Lic. Teor. V. Tepes Timisoara', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic Waldorf', 'Lic. Teor. Waldorf', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic Waldorf, Ia??i', 'Lic Waldorf Iasi', 'IS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic ???William Shakespeare??? Timi??oara', 'Lic. Teor. ???W. Shakespeare??? Timisoara', 'TM');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic ???Zajzoni Rab Istvan??? S??cele', 'BV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic Zimnicea', 'Lte Zimnicea', 'TR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul ???Timotei Cipariu??? Dumbr??veni', 'Lic ???T. Cipariu??? Dumbr??veni', 'SB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul ???Traian Vuia??? Craiova', 'Liceul Traian Vuia Craiova', 'DJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul ???Udri??te N??sturel??? Hotarele', 'Lic. ???Udri??te N??sturel??? Hotarele', 'GR');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Unitarian ???Janos Zsigmond??? Cluj-Napoca', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul ???Vasile Conta???, Ora?? T??rgu Neam??', 'Ltvc, T??rgu Neam??', 'NT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Voca??ional de Art?? T??rgu Mure??', 'Lic. Voc. de Art?? Tg. Mure??', 'MS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Voca??ional de Arte Plastice ???Hans Mattis-Teutsch??? Bra??ov', 'Liceul de Arte Plastice Bra??ov', 'BV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Voca??ional de Muzic?? ???Tudor Ciortea??? Bra??ov', 'Liceul de Muzic?? Bra??ov', 'BV');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Voca??ional Pedagogic ???Nicolae Bolca????? Beiu??', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Voca??ional Reformat T??rgu Mure??', 'Lic. Voc. Reformat Tg. Mure??', 'MS');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul ???Voievodul Mircea??? T??rgovi??te', 'DB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul ???Voltaire??? Craiova', 'Liceul Voltaire', 'DJ');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Waldorf Cluj-Napoca', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Waldorf Timi??oara', 'Lic. Waldorf Timisoara', 'TM');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul ???Stefan D. Luchian??? Stefanesti', 'BT');
INSERT INTO "authors" ("id", "first_name", "last_name")
VALUES (1, 'Mihai', 'Eminescu');
INSERT INTO "authors" ("id", "first_name", "last_name")
VALUES (2, 'Ion', 'Creang??');
INSERT INTO "authors" ("id", "first_name", "middle_name", "last_name")
VALUES (3, 'Ion', 'Luca', 'Caragiale');
INSERT INTO "authors" ("id", "first_name", "last_name")
VALUES (4, 'Ioan', 'Slavici');
INSERT INTO "authors" ("id", "first_name", "last_name")
VALUES (5, 'George', 'Bacovia');
INSERT INTO "authors" ("id", "first_name", "last_name")
VALUES (6, 'Lucian', 'Blaga');
INSERT INTO "authors" ("id", "first_name", "last_name")
VALUES (7, 'Tudor', 'Arghezi');
INSERT INTO "authors" ("id", "first_name", "last_name")
VALUES (8, 'Ion', 'Barbu');
INSERT INTO "authors" ("id", "first_name", "last_name")
VALUES (9, 'Mihail', 'Sadoveanu');
INSERT INTO "authors" ("id", "first_name", "last_name")
VALUES (10, 'Liviu', 'Rebreanu');
INSERT INTO "authors" ("id", "first_name", "last_name")
VALUES (11, 'Camil', 'Petrescu');
INSERT INTO "authors" ("id", "first_name", "last_name")
VALUES (12, 'George', 'C??linescu');
INSERT INTO "authors" ("id", "first_name", "last_name")
VALUES (13, 'Marin', 'Preda');
INSERT INTO "authors" ("id", "first_name", "last_name")
VALUES (14, 'Nichita', 'St??nescu');
INSERT INTO "authors" ("id", "first_name", "last_name")
VALUES (15, 'Marin', 'Sorescu');
INSERT INTO "authors" ("id", "first_name", "last_name")
VALUES (16, 'Mircea', 'Eliade');
INSERT INTO "authors" ("id", "first_name", "last_name")
VALUES (17, 'Costache', 'Negruzzi');
INSERT INTO "authors" ("id", "first_name", "last_name")
VALUES (18, 'Grigore', 'Alexandrescu');
INSERT INTO "authors" ("id", "first_name", "last_name")
VALUES (19, 'Vasile', 'Alecsandri');
INSERT INTO "authors" ("id", "first_name", "last_name")
VALUES (20, 'George', 'Co??buc');
INSERT INTO "authors" ("id", "first_name", "last_name")
VALUES (21, 'Octavian', 'Goga');
INSERT INTO "authors" ("id", "first_name", "last_name")
VALUES (22, 'Ion', 'Vinea');
INSERT INTO "authors" ("id", "first_name", "last_name")
VALUES (23, 'Ion', 'Pillat');
INSERT INTO "authors" ("id", "first_name", "last_name")
VALUES (24, 'Vasile', 'Voiculescu');
INSERT INTO "authors" ("id", "first_name", "last_name")
VALUES (25, 'Mircea', 'Nedelciu');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (1, 1, 'Luceaf??rul');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (2, 1, 'S??rmanul Dionis');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (3, 1, 'Floare albastr??');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (4, 1, 'Scrisoarea I');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (5, 1, 'Od??');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (6, 1, 'Gloss??');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (7, 2, 'Povestea lui Harap-Alb');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (8, 3, 'O scrisoare pierdut??');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (9, 3, 'La hanul lui M??njoal??');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (10, 4, 'Moara cu noroc');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (11, 4, 'Mara');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (12, 5, 'Plumb');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (13, 5, 'Lacustr??');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (14, 5, 'Sonet');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (15, 6, 'Eu nu strivesc corola de minuni a lumii');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (16, 6, 'Da??i-mi un trup, voi mun??ilor');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (17, 6, 'Izvorul nop??ii');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (18, 6, 'Me??terul Manole');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (19, 7, 'Flori de mucigai');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (20, 7, 'Testament');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (21, 7, 'Psalmul III - Tare sunt singur, Doamne, ??i piezi??!...');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (22, 7, 'Psalmul VI - Te dr??muiesc ??n zgomot ??i-n t??cere...');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (23, 8, 'Riga Crypto ??i lapona Enigel');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (24, 8, 'Joc secund');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (25, 9, 'Baltagul');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (26, 9, 'Hanul Ancu??ei');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (27, 9, 'Creanga de aur');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (28, 10, 'Ion');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (29, 10, 'P??durea sp??nzura??ilor');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (30, 11, 'Ultima noapte de dragoste, ??nt??ia noapte de r??zboi');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (31, 11, 'Patul lui Procust');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (32, 11, 'Jocul ielelor');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (33, 11, 'Suflete tari');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (34, 11, 'Act vene??ian');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (35, 12, 'Enigma Otiliei');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (36, 12, 'Bietul Ioanide');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (37, 13, 'Morome??ii');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (38, 13, 'Cel mai iubit dintre p??m??nteni');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (39, 14, 'Leoaic?? t??n??r??, iubirea');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (40, 14, 'C??ntec');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (41, 14, '??n dulcele stil clasic');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (42, 14, 'C??tre Galateea');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (43, 15, 'Iona');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (44, 16, 'Maitreyi');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (45, 16, 'Nunt?? ??n cer');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (46, 16, 'La ??ig??nci');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (47, 17, 'Alexandru L??pu??neanu');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (48, 18, 'Umbra lui Mircea la Cozia');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (49, 19, 'Malul Siretului');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (50, 20, 'Moartea lui Fulger');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (51, 21, 'Rug??ciune');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (52, 21, 'De demult');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (53, 22, 'Ora f??nt??nilor');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (54, 23, 'Aci sosi de vremuri');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (55, 24, '??n gr??dina Ghetsemani');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (56, 25, 'Zmeura de c??mpie');
INSERT INTO "characters" ("id", "title_id", "name")
VALUES (1, 8, '??tefan Tip??tescu');
INSERT INTO "characters" ("id", "title_id", "name")
VALUES (2, 8, 'Zoe Trahanache');
INSERT INTO "characters" ("id", "title_id", "name")
VALUES (3, 8, 'Farfuridi');
INSERT INTO "characters" ("id", "title_id", "name")
VALUES (4, 8, 'Ghit?? Pristanda');
INSERT INTO "characters" ("id", "title_id", "name")
VALUES (5, 8, 'Nae Ca??avencu');
INSERT INTO "characters" ("id", "title_id", "name")
VALUES (6, 8, 'Agamemnon Dandanache');
INSERT INTO "characters" ("id", "title_id", "name")
VALUES (7, 10, 'Ghi????');
INSERT INTO "characters" ("id", "title_id", "name")
VALUES (8, 10, 'Lic?? S??m??d??ul');
INSERT INTO "characters" ("id", "title_id", "name")
VALUES (9, 25, 'Vitoria Lipan');
INSERT INTO "characters" ("id", "title_id", "name")
VALUES (10, 25, 'Nechifor Lipan');
INSERT INTO "characters" ("id", "title_id", "name")
VALUES (11, 28, 'Ion');
INSERT INTO "characters" ("id", "title_id", "name")
VALUES (12, 28, 'Ana');
INSERT INTO "characters" ("id", "title_id", "name")
VALUES (13, 28, 'Florica');
INSERT INTO "characters" ("id", "title_id", "name")
VALUES (14, 28, 'Vasile Baciu');
INSERT INTO "characters" ("id", "title_id", "name")
VALUES (15, 28, 'George Bulbuc');
INSERT INTO "characters" ("id", "title_id", "name")
VALUES (16, 28, 'Titu Herdelea');
INSERT INTO "characters" ("id", "title_id", "name")
VALUES (17, 30, '??tefan Gheorghidiu');
INSERT INTO "characters" ("id", "title_id", "name")
VALUES (18, 30, 'Ela');
INSERT INTO "characters" ("id", "title_id", "name")
VALUES (19, 33, 'Andrei Pietraru');
INSERT INTO "characters" ("id", "title_id", "name")
VALUES (20, 37, 'Moromete');
INSERT INTO "characters" ("id", "title_id", "name")
VALUES (21, 37, 'Catrina');
INSERT INTO "characters" ("id", "title_id", "name")
VALUES (22, 37, 'Niculae Moromete');
INSERT INTO "characters" ("id", "title_id", "name")
VALUES (23, 44, 'Allan');
INSERT INTO "characters" ("id", "title_id", "name")
VALUES (24, 46, 'Gavrilescu');
