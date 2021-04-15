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
        constraint users_all_email_key check (deleted_at is null or email is not null) unique,
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
        raise exception 'utilizatorul este deja profesor, nu poate fi și elev';
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
        raise exception 'utilizatorul este deja elev, nu poate fi și profesor';
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
        raise exception 'lucrarea este deja o caracterizare, nu poate fi și un eseu';
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
        raise exception 'lucrarea este deja un eseu, nu poate fi și o caracterizare';
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
VALUES ('AG', 'Argeș');
INSERT INTO "counties" ("id", "name")
VALUES ('AR', 'Arad');
INSERT INTO "counties" ("id", "name")
VALUES ('B', 'București');
INSERT INTO "counties" ("id", "name")
VALUES ('BC', 'Bacău');
INSERT INTO "counties" ("id", "name")
VALUES ('BH', 'Bihor');
INSERT INTO "counties" ("id", "name")
VALUES ('BN', 'Bistrița-Năsăud');
INSERT INTO "counties" ("id", "name")
VALUES ('BR', 'Brăila');
INSERT INTO "counties" ("id", "name")
VALUES ('BT', 'Botoșani');
INSERT INTO "counties" ("id", "name")
VALUES ('BV', 'Brașov');
INSERT INTO "counties" ("id", "name")
VALUES ('BZ', 'Buzău');
INSERT INTO "counties" ("id", "name")
VALUES ('CJ', 'Cluj');
INSERT INTO "counties" ("id", "name")
VALUES ('CL', 'Călărași');
INSERT INTO "counties" ("id", "name")
VALUES ('CS', 'Caraș-Severin');
INSERT INTO "counties" ("id", "name")
VALUES ('CT', 'Constanța');
INSERT INTO "counties" ("id", "name")
VALUES ('CV', 'Covasna');
INSERT INTO "counties" ("id", "name")
VALUES ('DB', 'Dâmbovița');
INSERT INTO "counties" ("id", "name")
VALUES ('DJ', 'Dolj');
INSERT INTO "counties" ("id", "name")
VALUES ('GJ', 'Gorj');
INSERT INTO "counties" ("id", "name")
VALUES ('GL', 'Galați');
INSERT INTO "counties" ("id", "name")
VALUES ('GR', 'Giurgiu');
INSERT INTO "counties" ("id", "name")
VALUES ('HD', 'Hunedoara');
INSERT INTO "counties" ("id", "name")
VALUES ('HR', 'Harghita');
INSERT INTO "counties" ("id", "name")
VALUES ('IF', 'Ilfov');
INSERT INTO "counties" ("id", "name")
VALUES ('IL', 'Ialomița');
INSERT INTO "counties" ("id", "name")
VALUES ('IS', 'Iași');
INSERT INTO "counties" ("id", "name")
VALUES ('MH', 'Mehedinți');
INSERT INTO "counties" ("id", "name")
VALUES ('MM', 'Maramureș');
INSERT INTO "counties" ("id", "name")
VALUES ('MS', 'Mureș');
INSERT INTO "counties" ("id", "name")
VALUES ('NT', 'Neamț');
INSERT INTO "counties" ("id", "name")
VALUES ('OT', 'Olt');
INSERT INTO "counties" ("id", "name")
VALUES ('PH', 'Prahova');
INSERT INTO "counties" ("id", "name")
VALUES ('SB', 'Sibiu');
INSERT INTO "counties" ("id", "name")
VALUES ('SJ', 'Sălaj');
INSERT INTO "counties" ("id", "name")
VALUES ('SM', 'Satu Mare');
INSERT INTO "counties" ("id", "name")
VALUES ('SV', 'Suceava');
INSERT INTO "counties" ("id", "name")
VALUES ('TL', 'Tulcea');
INSERT INTO "counties" ("id", "name")
VALUES ('TM', 'Timiș');
INSERT INTO "counties" ("id", "name")
VALUES ('TR', 'Teleorman');
INSERT INTO "counties" ("id", "name")
VALUES ('VL', 'Vâlcea');
INSERT INTO "counties" ("id", "name")
VALUES ('VN', 'Vrancea');
INSERT INTO "counties" ("id", "name")
VALUES ('VS', 'Vaslui');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Agricol „Daniil Popovici Barcianu” Sibiu', 'Col Agricol „D.P. Barcianu” Sibiu', 'SB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Agricol „Dimitrie Cantemir”, Mun. Huși', 'Col Agr Huși', 'VS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Agricol și de Industrie Alimentară „Vasile Adamachi”, Iași', 'Col Agr „V. Adamachi” Iasi', 'IS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Agricol „Traian Săvulescu” Tîrgu Mureș', 'Col. Agr. „T. Săvulescu” Tg. Mureș', 'MS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul „Alexandru Cel Bun” Gura Humorului', 'Colegiul „Al. Cel Bun” Gura Humorului', 'SV');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul „Andronic Motrescu” Rădăuți', 'SV');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul „Aurel Vijoli” Făgăraș', 'BV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Auto „Traian Vuia” Tg-Jiu', 'Col Auto „Traian Vuia” Tg-Jiu', 'GJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Comercial „Carol I” Constanța', 'Col Comercial „Carol I” Cța', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul „Danubius”, Municipiul Galati', 'Col. „Danubius” Gl', 'GL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul de Artă „Carmen Sylva”, Municipiul Ploiești', 'Colegiul de Arta „Carmen Sylva” Ploiesti', 'PH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul de Artă „Ciprian Porumbescu” Suceava', 'Colegiul de Artă „C. Porumbescu” Suceava', 'SV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul de Arte Baia Mare', 'Col Arte Bm', 'MM');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul de Arte „Sabin Dragoi” Arad', 'AR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul de Industrie Alimentara „Elena Doamna”, Localitatea Galati', 'Col. Ind. „Elena Doamna” Gl', 'GL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul de Învățământ Terțiar Nonuniversitar Usamvbt Timișoara', 'Col. Inv. Usamvbt Timisoara', 'TM');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul de Muzică „Sigismund Toduță” Cluj-Napoca', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul de Servicii În Turism „Napoca” Cluj-Napoca', 'Colegiul de Servicii În Turism „Napoca” Cluj-N', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul de Științe ale Naturii „Emil Racoviță” Brașov', 'Colegiul „Emil Racoviță” Brașov', 'BV');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul de Științe „Grigore Antipa” Brașov', 'BV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Dobrogean „Spiru Haret” Tulcea', 'Colegiul „S. Haret” Tulcea', 'TL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Ecologic „Prof. Univ. Dr. Alexandru Ionescu” Pitești', 'Col. Ecologic Al. Ionescu Pitești', 'AG');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Economic Administrativ, Iași', 'Col Ec Adm Iasi', 'IS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Economic „a.D. Xenopol”', 'Col. Ec. „a.D. Xenopol”', 'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Economic Al Banatului Montan Reșița', 'CS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Economic „Anghel Rugină”, Mun. Vaslui', 'Col. Economic', 'VS');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Economic Arad', 'AR');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Economic Calarasi', 'CL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Economic „Costin C. Kirițescu”', 'Col. Ec. „Costin C. Kirițescu”', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Economic „Delta Dunării” Tulcea', 'Colegiul Economic', 'TL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Economic „Dimitrie Cantemir” Suceava', 'Colegiul Economic „Dimitrie Cantemir” Suceava', 'SV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Economic „Dionisie Pop Martian” Alba Iulia', 'Col. Ec. „D.P.M.” Alba Iulia', 'AB');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Economic „Emanuil Gojdu” Hunedoara', 'HD');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Economic „Francesco Saverio Nitti” Timișoara', 'Col. Economic Timisoara', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Economic „George Barițiu” Sibiu', 'Col Ec „G. Barițiu” Sibiu', 'SB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Economic „Gheorghe Chitu” Craiova', 'Colegiul Gheorghe Chitu Craiova', 'DJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Economic „Gheorghe Dragoș” Satu Mare', 'Gheorghe Satu Mare', 'SM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Economic „Hermes”', 'Col. Ec. „Hermes”', 'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Economic „Hermes” Petroșani', 'HD');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Economic „Ion Ghica”', 'BR');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Economic „Ion Ghica” Bacău', 'BC');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Economic „Ion Ghica” Târgoviște', 'DB');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Economic „Iulian Pop” Cluj-Napoca', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Economic Mangalia', 'Col Economic Mangalia', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Economic „Maria Teiuleanu” Pitești', 'Col. Economic Pitești', 'AG');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Economic „Mihail Kogalniceanu” Focsani', 'Col. Ec. „M. Kogalniceanu” Focsani', 'VN');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Economic, Mun. Rm. Valcea', 'Col Economic Rm. Valcea', 'VL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Economic Municipiul Buzău', 'Col Economic Bz', 'BZ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Economic „Nicolae Titulescu” Baia Mare', 'Ce N Titulescu Bm', 'MM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Economic „Octav Onicescu” Botosani', 'Colegiul Economic „O. Onicescu”', 'BT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Economic „Partenie Cosma” Oradea', 'Ce „P. Cosma” Oradea', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Economic „Pintea Viteazul” Cavnic', 'Ce P Viteazul Cavnic', 'MM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Economic „Transilvania” Tîrgu Mureș', 'Col. Ec. „Transilvania” Tg. Mures', 'MS');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Economic „V. Madgearu”', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Economic „Viilor”', 'Col. Ec. „Viilor”', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Economic „Virgil Madgearu”, Localitatea Galati', 'Col. Ec. „V. Madgearu” Gl', 'GL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Economic „Virgil Madgearu”, Municipiul Ploiești', 'Colegiul „V. Madgearu” Ploiesti', 'PH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Economic „Virgil Madgearu” Tg-Jiu', 'Col. Eco. „Virgil Madgearu” Tg-Jiu', 'GJ');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul „Emil Negruțiu” Turda', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Energetic, Mun. Rm. Valcea', 'Col Energetic Rm. Valcea', 'VL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul „Ferdinand I”, Comuna Măneciu', 'Colegiul Maneciu', 'PH');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul German „Goethe”', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul „Gheorghe Tatarescu” Rovinari', 'Col „Gheorghe Tatarescu” Rovinari', 'GJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul „Ion Kalinderu”, Orașul Bușteni', 'Colegiul „Ion Kalinderu” Busteni', 'PH');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul „Mihai Eminescu” Bacău', 'BC');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul „Mihai Viteazul” Bumbesti-Jiu', 'Col. „M. Viteazul” Bumbesti-Jiu', 'GJ');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul „Mihai Viteazul” Ineu', 'AR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul „Mihail Cantacuzino”, Orașul Sinaia', 'Colegiul „M. Cantacuzino” Sinaia', 'PH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul National „Al. I. Cuza” Focsani', 'Col. National „Al. I. Cuza” Focsani', 'VN');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul National „Alexandru Ioan Cuza”, Localitatea Galati', 'Col. Nat. „Al. I. Cuza” Gl', 'GL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul National Alexandru Lahovari, Mun. Rm. Valcea', 'Cn Al. Lahovari Rm. Valcea', 'VL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul National „a.T. Laurian” Botosani', 'Colegiul Nat. „a.T. Laurian” Bt', 'BT');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul National „Barbu Stirbei” Calarasi', 'CL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul National „Bethlen Gabor” Aiud', 'Colegiul „B.G.” Aiud', 'AB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul National „Calistrat Hogas”, Localitatea Tecuci', 'Col. Nat. „C. Hogas” Tc', 'GL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul National „Carol I” Craiova', 'Colegiul Carol I Craiova', 'DJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul National „Costache Negri”, Localitatea Galati', 'Col. Nat. „C. Negri” Gl', 'GL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul National de Agricultura Si Economie, Localitatea Tecuci', 'C.N.a.E. Tecuci', 'GL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul National de Informatica Matei Basarab, Mun. Rm. Valcea', 'Cni M. Basarab Rm. Valcea', 'VL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul National „Dragos Voda” Sighetu Marmatiei', 'Cn D Voda Sighet', 'MM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul National „Ecaterina Teodoroiu” Tg-Jiu', 'Col. Nat. „Ec. Teodoroiu” Tg-Jiu', 'GJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul National „Elena Cuza” Craiova', 'Colegiul Elena Cuza Craiova', 'DJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul National „Emil Botta” Adjud', 'Col. National „Emil Botta” Adjud', 'VN');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul National „Fratii Buzesti” Craiova', 'Colegiul Fratii Buzesti Craiova', 'DJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul National „George Cosbuc” Motru', 'Col. Nat. „George Cosbuc” Motru', 'GJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul National „Gheorghe Sincai” Baia Mare', 'Cn G Sincai Bm', 'MM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul National „Gib Mihaescu” Dragasani', 'Col Gib Mihaescu Dragasani', 'VL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul National „Grigore Ghica” Dorohoi', 'Colegiul Nat. „Gr. Ghica”', 'BT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul National „Horea Closca Si Crisan” Alba Iulia', 'Colegiul „Hcc” Alba Iulia', 'AB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul National „Inochentie Micu Clain” Blaj', 'Colegiul „I.M. Clain” Blaj', 'AB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul National „Kolcsey Ferenc” Satu Mare', 'Cn „Kolcsey Ferenc” Satu Mare', 'SM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul National „Lucian Blaga” Sebes', 'Colegiul „L. Blaga” Sebes', 'AB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul National „Mihai Eminescu” Baia Mare', 'Cn M Eminescu Bm', 'MM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul National „Mihai Eminescu” Botosani', 'Colegiul Nat. „M. Eminescu” Bt', 'BT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul National „Mihail Kogalniceanu”, Localitatea Galati', 'Col. Nat. „M. Kogalniceanu” Gl', 'GL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul National Militar „Mihai Viteazul” Alba Iulia', 'Colmil Alba Iulia', 'AB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul National Militar „Tudor Vladimirescu” Craiova', 'Colegiul Tudor Vladimirescu Craiova', 'DJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul National Mircea Cel Batran, Mun. Rm. Valcea', 'Cn Mircea Cel Batrin Rm. Valcea', 'VL');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul National „Neagoe Basarab” Oltenita', 'CL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul National „Nicolae Titulescu” Craiova', 'Colegiul Nicolae Titulescu Craiova', 'DJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul National Pedagogic „Regele Ferdinand” Sighetu Marmatiei', 'Cnped R Ferdinand Sighet', 'MM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul National Pedagogic „Regina Maria”, Municipiul Ploiești', 'Colegiul „Regina Maria” Ploiesti', 'PH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul National Pedagogic „Spiru Haret” Focsani', 'Col. Nat. Pedag. „Spiru Haret” Focsani', 'VN');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul National Pedagogic „Stefan Velovan” Craiova', 'Colegiul Stefan Velovan Craiova', 'DJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul National „Spiru Haret”, Localitatea Tecuci', 'Col. Nat. „S. Haret” Tc', 'GL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul National „Spiru Haret” Tg-Jiu', 'Col. Nat. „Spiru Haret” Tg-Jiu', 'GJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul National „Titu Maiorescu” Aiud', 'Colegiul „T. M” Aiud', 'AB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul National „Tudor Arghezi” Tg-Carbunesti', 'Col. Nat. „T. Arghezi” Tg-Carbunesti', 'GJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul National „Tudor Vladimirescu” Tg-Jiu', 'Col. Nat. „T. Vladimirescu” Tg-Jiu', 'GJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul National „Unirea” Focsani', 'Col. National „Unirea” Focsani', 'VN');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul National „Vasile Alecsandri”, Localitatea Galati', 'Col. Nat. „V. Alecsandri” Gl', 'GL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul National „Vasile Lucaciu” Baia Mare', 'Cn V Lucaciu Bm', 'MM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Alexandru Ioan Cuza” Alexandria', 'Cn „Alexandru Ioan Cuza” Alexandria', 'TR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Alexandru Ioan Cuza”, Municipiul Ploiești', 'Colegiul Nat „Al. I. Cuza” Ploiesti', 'PH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Alexandru Odobescu” Pitești', 'Cn Al. Odobescu Pitești', 'AG');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Alexandru Papiu Ilarian” Tîrgu Mureș', 'Col. Naț. „Al. Papiu Ilarian” Tg. Mureș', 'MS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Alexandru Vlahuță” Municipiul Rîmnicu Sărat', 'Colegiul „Al. Vlahuță”', 'BZ');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Național „Ana Aslan”', 'BR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Ana Aslan” Timișoara', 'Col. Nat. a. Aslan Timisoara', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Anastasescu” Roșiori de Vede', 'Cn „Anastasescu” Roșiori de Vede', 'TR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Andrei Mureșanu” Bistrița', 'Col Naț „a. Mureșanu” Bistrița', 'BN');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Andrei Mureșanu” Dej', 'Colegiul National „Andrei Mureșanu” Dej', 'CJ');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Național „Andrei Șaguna” Brașov', 'BV');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Național „Aprily Lajos” Brașov', 'BV');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Național „Aurel Vlaicu”', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Avram Iancu” Câmpeni', 'Col. „Ai” Câmpeni', 'AB');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Național „Avram Iancu” Ștei', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „B.P. Hasdeu” Municipiul Buzău', 'Col. Nat. „B.P. Hasdeu”', 'BZ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național Bănățean Timișoara', 'Col. Nat. Banatean Timisoara', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național Bilingv „George Coșbuc”', 'Col. Naț. Bilingv „George Coșbuc”', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Calistrat Hogaș”, Municipiul Piatra-Neamț', 'Cnch, Piatra Neamț', 'NT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Cantemir Vodă”', 'Col. Naț. „Cantemir Vodă”', 'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Național Catolic „Sf. Iosif” Bacău', 'BC');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Național „C.D. Loga” Caransebeș', 'CS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Constantin Cantacuzino” Târgoviște', 'Colegiul Național „Constantin Cantacuzino” Tgv',
        'DB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Constantin Carabella” Târgoviște', 'Colegiul Național „Constantin Carabella” Tgv', 'DB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Constantin Diaconovici Loga” Timișoara', 'Col. Nat. C.D. Loga Timisoara', 'TM');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Național „Costache Negri” Târgu Ocna', 'BC');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Costache Negruzzi”, Iași', 'Col „C. Negruzzi” Iasi', 'IS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Cuza Vodă”, Mun. Huși', 'Col. Naț Cuza Vodă', 'VS');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Național de Artă „George Apostu” Bacău', 'BC');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național de Artă „Octav Băncilă”, Iași', 'Col Nat de Arta „O. Bancila” Iasi', 'IS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național de Arte „Dinu Lipatti”', 'Col. Naț. de Arte „D. Lipatti”', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național de Arte „Regina Maria” Constanța', 'Col Nat de Artă Cța', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național de Informatică „Carmen Sylva” Petroșani',
        'Colegiul Național de Inf. „Carmen Sylva” Petroșani', 'HD');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național de Informatică „Gr. Moisil” Brașov', 'Colegiul Național de Informatică Brașov', 'BV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național de Informatică, Municipiul Piatra-Neamț', 'Cni, Piatra Neamț', 'NT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național de Informatică „Spiru Haret” Suceava', 'Cn de Informatică „Spiru Haret” Suceava', 'SV');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Național de Informatică „Tudor Vianu”', 'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Național de Muzică „George Enescu”', 'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Național „Decebal” Deva', 'HD');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Diaconovici Tietz” Reșița', 'Lic Diaconovici-Tietz Resita', 'CS');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Național „Dimitrie Cantemir” Onești', 'BC');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Dinicu Golescu” Câmpulung', 'Cn Dinicu Golescu Câmpulung', 'AG');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Național „Doamna Stanca” Făgăraș', 'BV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Doamna Stanca” Satu Mare', 'Cn „Doamna Stanca” Sm', 'SM');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Național „Dr. Ioan Meșotă” Brașov', 'BV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Dragoș Vodă” Câmpulung Moldovenesc', 'Cn „Dragoș Vodă” Câmpulung Moldovenesc', 'SV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național Economic „Andrei Bârseanu” Brașov', 'Colegiul Național Economic Brașov', 'BV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național Economic „Theodor Costescu”', 'Col. Economic „Th. Costescu”', 'MH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Elena Cuza”', 'Col. Naț. „Elena Cuza”', 'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Național „Elena Ghiba Birta” Arad', 'AR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Emanuil Gojdu” Oradea', 'Cn E. Gojdu Oradea', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Emil Racoviță”', 'Col. Naț. „Emil Racoviță”', 'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Național „Emil Racoviță” Cluj-Napoca', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Emil Racoviță”, Iași', 'Col Nat „E. Racovita” Iasi', 'IS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Eudoxiu Hurmuzachi” Rădăuți', 'Cn „Eudoxiu Hurmuzachi” Rădăuți', 'SV');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Național „Ferdinand I” Bacău', 'BC');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Garabet Ibrăileanu”, Iași', 'Col Nat „G. Ibraileanu” Iasi', 'IS');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Național „George Barițiu” Cluj-Napoca', 'CJ');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Național „George Coșbuc” Cluj-Napoca', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „George Coșbuc” Năsăud', 'Col Naț „G. Coșbuc” Năsăud', 'BN');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Gh. Roșca Codreanu”, Mun. Bârlad', 'Col. Naț Gh. R. Codreanu', 'VS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Gheorghe Asachi”, Municipiul Piatra-Neamț', 'Cnga, Piatra Neamț', 'NT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Gheorghe Lazăr”', 'Col. Naț. „Gheorghe Lazăr”', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Gheorghe Lazăr” Sibiu', 'Col Naț „Gh. Lazăr” Sibiu', 'SB');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Național „Gheorghe Munteanu Murgoci”', 'BR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Gheorghe Șincai”', 'Col. Naț. „Gheorghe Șincai”', 'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Național „Gheorghe Șincai” Cluj-Napoca', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Gheorghe Țițeica”', 'Col. Nat. „G. Titeica”', 'MH');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Național „Gheorghe Vrănceanu” Bacău', 'BC');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Grigore Moisil”', 'Col. Naț. „Grigore Moisil”', 'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Național „Grigore Moisil” Onești', 'BC');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Național „Iancu de Hunedoara” Hunedoara', 'HD');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național, Iași', 'Col National Iasi', 'IS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Ienăchiță Văcărescu” Târgoviște', 'Colegiul Național „Ienăchiță Văcărescu” Târgovișt',
        'DB');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Național „I.L. Caragiale”', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Ioan Slavici” Satu Mare', 'Cn I. Slavici', 'SM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Ion C. Brătianu” Pitești', 'Cn I.C. Brătianu Pitești', 'AG');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Ion Creangă”', 'Col. Naț. „Ion Creangă”', 'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Național „Ion Luca Caragiale” Moreni', 'DB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Ion Luca Caragiale”, Municipiul Ploiești', 'Colegiul „Il. Caragiale” Ploiesti', 'PH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Ion Maiorescu” Giurgiu', 'Col. Nat. „Ion Maiorescu”', 'GR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Ion Minulescu” Slatina', 'Colegiu Nat „I. Minulescu” Slatina', 'OT');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Național „Ion Neculce”', 'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Național „Iosif Vulcan” Oradea', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Iulia Hașdeu”', 'Col. Naț. „Iulia Hașdeu”', 'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Național „Johannes Honterus” Brașov', 'BV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Kemal Ataturk” Medgidia', 'Col Național „Kemal Ataturk” Medgidia', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Liviu Rebreanu” Bistrița', 'Col Naț „L. Rebreanu” Bistrița', 'BN');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Márton Áron” Miercurea Ciuc', 'Cn „Marton Aron” Miercurea Ciuc', 'HR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Matei Basarab”', 'Col. Naț. „Matei Basarab”', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Mihai Eminescu”', 'Col. Naț. „Mihai Eminescu”', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Mihai Eminescu” Constanța', 'Col Național „Mihai Eminescu” Cța', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Mihai Eminescu”, Iași', 'Col Nat „M. Eminescu” Iasi', 'IS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Mihai Eminescu” Municipiul Buzău', 'Colegiul „M. Eminescu”', 'BZ');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Național „Mihai Eminescu” Oradea', 'BH');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Național „Mihai Eminescu” Petroșani', 'HD');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Mihai Eminescu” Satu Mare', 'Cn Mihai Eminescu Sm', 'SM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Mihai Eminescu” Suceava', 'Cn „Mihai Eminescu” Suceava', 'SV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Mihai Eminescu” Toplița', 'Cn „Mihai Eminescu” Toplita', 'HR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Mihai Viteazul”', 'Col. Naț. „Mihai Viteazul”', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Mihai Viteazul”, Municipiul Ploiești', 'Colegiul „M. Viteazul” Ploiesti', 'PH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Mihai Viteazul” Sfântu Gheorghe', 'Col. Naț. „Mihai Viteazul” Sfântu Gheorghe', 'CV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Mihai Viteazul” Slobozia', 'Colegiul Naț. „Mihai Viteazul” Slobozia', 'IL');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Național „Mihai Viteazul” Turda', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Mihail Sadoveanu”, Pașcani', 'Col Nat „M. Sadoveanu” Pascani', 'IS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național Militar „Alexandru Ioan Cuza” Constanța', 'Cnmil a I Cuza', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național Militar „Dimitrie Cantemir” Breaza', 'Colegiul Mil. „D. Cantemir” Breaza', 'PH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național Militar „Ștefan Cel Mare” Câmpulung Moldovenesc',
        'Cn Militar „Șt. Cel Mare” Câmpulung Moldovenesc', 'SV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Mircea Cel Bătrân” Constanța', 'Col Național „Mircea Cel Batran” Cța', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Mircea Eliade” Reșița', 'Colegiul Mircea Eliade Resita', 'CS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Mircea Eliade” Sighișoara', 'Col. Naț. „M. Eliade” Sighisoara', 'MS');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Național „Moise Nicoară” Arad', 'AR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Nichita Stănescu”, Municipiul Ploiești', 'Colegiul „Nichita Stanescu” Ploiesti', 'PH');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Național „Nicolae Bălcescu”', 'BR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Nicolae Grigorescu”, Municipiul Câmpina', 'Colegiul „N. Grigorescu” Cimpina', 'PH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Nicolae Iorga”, Orașul Vălenii de Munte', 'Colegiul „N. Iorga” Valenii de M.', 'PH');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Național „Nicolae Titulescu” Pucioasa', 'DB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Nicu Gane” Fălticeni', 'Cn „Nicu Gane” Fălticeni', 'SV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Octav Onicescu”', 'Col. Naț. „Octav Onicescu”', 'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Național „Octavian Goga” Marghita', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Octavian Goga” Miercurea Ciuc', 'Cn „Octavian Goga” Miercurea Ciuc', 'HR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Octavian Goga” Sibiu', 'Col Naț „O. Goga” Sibiu', 'SB');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Național „Onisifor Ghibu” Oradea', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național Pedagogic „Andrei Șaguna” Sibiu', 'Col Naț Pedagogic „a. Șaguna” Sibiu', 'SB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național Pedagogic „Carmen Sylva” Timișoara', 'Col. Ped „Carmen Sylva” Timisoara', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național Pedagogic „Carol I” Câmpulung', 'Cn Ped. Carol I Câmpulung', 'AG');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național Pedagogic „Constantin Brătescu” Constanța',
        'Col Național Pedagogic „Constantin Brătescu” Cța', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național Pedagogic „Dumitru Panaitescu Perpessicius”',
        'Colegiul Național Pedagogic „D.P. Perpessicius”', 'BR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național Pedagogic „Gheorghe Lazăr” Cluj-Napoca', 'Colegiul Național Pedagogic „Gheorghe Lazăr” Cluj',
        'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național Pedagogic „Mihai Eminescu” Tîrgu Mureș', 'Col. Naț. Ped. „M. Eminescu” Tg. Mureș', 'MS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național Pedagogic „Mircea Scarlat” Alexandria', 'Cnp „Mircea Scarlat” Alexandria', 'TR');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Național Pedagogic „Regina Maria” Deva', 'HD');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național Pedagogic „Spiru Haret” Municipiul Buzău', 'Col. Pedagogic „S. Haret”', 'BZ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național Pedagogic „Ștefan Cel Mare” Bacău', 'Col. Pedag. Ștefan Cel Mare Bacău', 'BC');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național Pedagogic „Ștefan Odobleja”', 'Col. Nat. Peda. „St. Odobleja”', 'MH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Petru Rareș” Beclean', 'Col Naț „P. Rareș” Beclean', 'BN');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Petru Rareș”, Municipiul Piatra-Neamț', 'Cnpr, Piatra Neamț', 'NT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Petru Rareș” Suceava', 'Cn „Petru Rareș” Suceava', 'SV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Preparandia-Dimitrie Țichindeal” Arad',
        'Colegiul Național „Preparandia-D. Țichindeal” Arad', 'AR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Radu Greceanu” Slatina', 'Colegiul Nat. „R. Greceanu” Slatina', 'OT');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Național „Radu Negru” Făgăraș', 'BV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Roman Vodă”, Municipiul Roman', 'Cnrv, Roman', 'NT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Samuel Von Brukenthal” Sibiu', 'Col Naț „Samuel Von Brukenthal” Sibiu', 'SB');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Național „Samuil Vulcan” Beiuș', 'BH');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Național „Sfântul Sava”', 'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Național „Silvania” Zalău', 'SJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Simion Bărnuțiu” Șimleu Silvaniei', 'Colegiul Național „S. Bărnuțiu” Șimleu Silvaniei',
        'SJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Spiru Haret”', 'Col. Naț. „Spiru Haret”', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Székely Mikó” Sfântu Gheorghe', 'Col. Naț. „Székely Mikó” Sfântu Gheorghe', 'CV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Școala Centrală”', 'Școala Centrală', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Ștefan Cel Mare”, Hârlău', 'Col Nat „Stefan Cel Mare” Harlau', 'IS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Ștefan Cel Mare”, Oraș Târgu Neamț', 'Cn „Ștefan Cel Mare”, Târgu Neamț', 'NT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Ștefan Cel Mare” Suceava', 'Cn „Stefan Cel Mare” Suceava', 'SV');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Național „Teodor Neș” Salonta', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Traian”', 'Col. „Traian”', 'MH');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Național „Traian Doda” Caransebeș', 'CS');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Național „Traian Lalescu” Reșița', 'CS');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Național „Unirea” Brașov', 'BV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Unirea” Tîrgu Mureș', 'Col. Naț. „Unirea” Tg. Mureș', 'MS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Unirea” Turnu Măgurele', 'Cn „Unirea” Turnu Măgurele', 'TR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Vasile Alecsandri” Bacău', 'Colegiul Național „V. Alecsandri” Bacau', 'BC');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Național „Vasile Goldiș” Arad', 'AR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Victor Babeș”', 'Col. Naț. „Victor Babeș”', 'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Național „Vladimir Streinu” Găești', 'DB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Vlaicu Vodă” Curtea de Argeș', 'Cn Vlaicu Vodă Curtea de Argeș', 'AG');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Zinca Golescu” Pitești', 'Cn Zinca Golescu Pitești', 'AG');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Național „Grigore Moisil” Urziceni', 'Colegiul Naț. „Grigore Moisil” Urziceni', 'IL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul „Nicolae Paulescu” Municipiul Rm. Sărat', 'Col N Paulescu Rms', 'BZ');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul „Nicolae Titulescu” Brașov', 'BV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul N.V. Bacău', 'Col. N.V. Bacău', 'BC');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Particular „Vasile Goldiș” Arad', 'AR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Pedagogic „Vasile Lupu”, Iași', 'Col Pedagogic Iasi', 'IS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Pentru Agricultură și Industrie Alimentară „Țara Bârsei” Prejmer', 'Colegiul Prejmer', 'BV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Reformat „Baczkamadarasi Kis Gergely” Odorheiu Secuiesc', 'Ste Reformat Odorhei', 'HR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul „Richard Wurmbrand”, Iasi', 'Crw', 'IS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Romano-Catolic „Sfântul Iosif”', 'Col. Rom. Cat. „Sf. Iosif”', 'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Silvic „Bucovina” Câmpulung Moldovenesc', 'SV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Silvic „Theodor Pietraru” Brănești', 'Colegiul Silvic „Theodor Pietraru” Branesti', 'IF');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul „Spiru Haret”, Municipiul Ploiești', 'Colegiul „Spiru Haret” Ploiesti', 'PH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul „Școala Națională de Gaz” Mediaș', 'Col Sng Mediaș', 'SB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic „Alesandru Papiu Ilarian” Zalău', 'Colegiul Tehnic „a.P. Ilarian” Zalău', 'SJ');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Tehnic „Alexandru Ioan Cuza” Suceava', 'SV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic „Alexandru Roman” Aleșd', 'Ct „Alexandru Roman” Aleșd', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic „Ana Aslan” Cluj-Napoca', 'Col. Tehn. Ana Ex.', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic „Anghel Saligny”', 'Col. Tehn. „Anghel Saligny”', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic „Anghel Saligny” Baia Mare', 'Ct a Saligny Bm', 'MM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic „Anghel Saligny” Cluj-Napoca', 'Colegiul Tehnic de Constructii „Anghel Saligny”', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic „Apulum” Alba Iulia', 'Ct „Apulum” Alba Iulia', 'AB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic „Armand Călinescu” Pitești', 'Col. Teh. Armand Călinescu Pitești', 'AG');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic „August Treboniu Laurian” Agnita', 'Col Tehn „a.T. Laurian” Agnita', 'SB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic „Aurel Vlaicu” Baia Mare', 'Ct a Vlaicu Bm', 'MM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic Auto „Traian Vuia” Focsani', 'Col. Tehn. Auto „Traian Vuia” Focsani', 'VN');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic „Batthyány Ignác” Gheorgheni', 'Col „Batthyany Ignac” Gheorgheni', 'HR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic „Carol I”', 'Col. Teh. „Carol I”', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic Câmpulung', 'Col. Teh. Câmpulung', 'AG');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic „Cd Nenitescu” Baia Mare', 'Ct Cd Nenitescu Bm', 'MM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic „Cibinium” Sibiu', 'Col Tehn „Cibinium” Sibiu', 'SB');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Tehnic „Constantin Brâncuși” Petrila', 'HD');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic „Costin D. Nenițescu”', 'Col. Tehn. „C.D. Nenițescu”', 'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Tehnic „Costin D. Nenițescu”', 'BR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic „Costin D. Nenițescu” Pitești', 'Col. Teh. C.D. Nenițescu Pitești', 'AG');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic „Danubiana”, Municipiul Roman', 'Ctd, Roman', 'NT');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Tehnic de Aeronautică „Henri Coandă”', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic de Arhitectură și Lucrări Publice „Ioan N. Socolescu”', 'Colegiul Tehnic „Ioan N. Socolescu”',
        'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic de Căi Ferate „Unirea”, Pașcani', 'Col Teh „Unirea” Pascani', 'IS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic de Comunicații „Augustin Maior” Cluj-Napoca', 'Colegiul Tehnic „Augustin Maior” Cluj', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic de Industrie Alimentară „Dumitru Moțoc”', 'Col. Teh. de Ind. Alim. „Dumitru Moțoc”', 'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Tehnic de Industrie Alimentară Suceava', 'SV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic de Poștă și Telecomunicații „Gheorghe Airinei”', 'Col. Teh. de Poștă și Tc. „Gh. Airinei”',
        'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Tehnic de Transporturi Brașov', 'BV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic de Transporturi, Municipiul Piatra-Neamț', 'Ctt, Piatra Neamț', 'NT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic de Transporturi „Transilvania” Cluj-Napoca', 'Colegiul Tehnic de Transporturi „Transilvania”',
        'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic „Dimitrie Ghika” Comănești', 'Colegiul Tehnic „D. Ghika” Comănești', 'BC');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic „Dimitrie Leonida”', 'Col. Tehn. „Dimitrie Leonida”', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic „Dinicu Golescu”', 'Col. Teh. „Dinicu Golescu”', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic „Dr. Alexandru Bărbat” Victoria', 'Colegiul Tehnic Victoria', 'BV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic „Edmond Nicolau”', 'Col. Tehn. „Edmond Nicolau”', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic „Edmond Nicolau” Focsani', 'Col. Tehn. „Edmond Nicolau” Focsani', 'VN');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic „Emanuil Ungureanu” Timișoara', 'Col. Teh. „E. Ungureanu” Timisoara', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic Energetic', 'Col. Teh. Energetic', 'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Tehnic Energetic Cluj-Napoca', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic Energetic „Remus Răduleț” Brașov', 'Colegiul Tehnic „Remus Răduleț” Brașov', 'BV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic Energetic Sibiu', 'Col Teh Energetic Sibiu', 'SB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic Feroviar „Mihai I”', 'Col. Tehn. Feroviar „Mihai I”', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic Forestier, Municipiul Câmpina', 'Colegiul Tehnic Forestier Campina', 'PH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic Forestier, Municipiul Piatra-Neamț', 'Ctf, Piatra Neamț', 'NT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic „George Baritiu” Baia Mare', 'Ct G Baritiu Bm', 'MM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic „Gheorghe Asachi”', 'Col. Teh. „Gh. Asachi”', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic „Gheorghe Asachi” Botosani', 'Col. Teh. „Gheorghe Asachi”', 'BT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic „Gheorghe Asachi” Focsani', 'Col. Tehn. „Gh. Asachi” Focsani', 'VN');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic „Gheorghe Asachi”, Iași', 'Col Teh „Gh. Asachi” Iasi', 'IS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic „Gheorghe Asachi” Onești', 'Colegiul Tehnic „Gh. Asachi” Onești', 'BC');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic „Gheorghe Bals” Adjud', 'Col. Tehn. „Gheorghe Bals” Adjud', 'VN');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic „Gheorghe Cartianu”, Municipiul Piatra-Neamț', 'Ctgc, Piatra Neamț', 'NT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic „G-Ral Gheorghe Magheru” Tg-Jiu', 'Col Tehnic „G-Ral Gh. Magheru” Tg-Jiu', 'GJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic „Grigore Cobălcescu” Moinești', 'Col. Teh. Gr. Moinești', 'BC');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic „Henri Coanda” Tg-Jiu', 'Col. Tehnic „H. Coanda” Tg-Jiu', 'GJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic „Henri Coandă” Timișoara', 'Col. Teh. „H. Coanda” Timisoara', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic „Infoel” Bistrița', 'Col Teh „Infoel” Bistrița', 'BN');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic „Ioan C. Ștefănescu”, Iași', 'Col Teh „I.C. Stefanescu” Iasi', 'IS');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Tehnic „Ioan Ciordaș” Beiuș', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic „Ion Creangă”, Oraș Târgu Neamț', 'Ctic, Târgu Neamț', 'NT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic „Ion D. Lazarescu” Cugir', 'Colegiul „I.D.L.” Cugir', 'AB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic „Ion Holban”, Iași', 'Col Teh „Ion Holban” Iasi', 'IS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic „Ion Mincu” Focsani', 'Col. Tehn. „Ion Mincu” Focsani', 'VN');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Tehnic „Ion Mincu” Tg-Jiu', 'GJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic „Iuliu Maniu”', 'Col. Teh. „Iuliu Maniu”', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic „Iuliu Maniu” Șimleu Silvaniei', 'Colegiul Tehnic „I. Maniu” Șimleu Silvaniei', 'SJ');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Tehnic „Lațcu Vodă” Siret', 'SV');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Tehnic „Maria Baiulescu” Brașov', 'BV');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Tehnic Matasari', 'GJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic Mecanic „Grivița”', 'Col. Tehn. Mec. „Grivița”', 'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Tehnic „Media”', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic „Mediensis” Mediaș', 'Col Teh „Mediensis” Mediaș', 'SB');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Tehnic „Mihai Băcescu” Fălticeni', 'SV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic „Mihai Bravu”', 'Col. Tehn. „Mihai Bravu”', 'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Tehnic „Mihai Viteazul” Oradea', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic „Mihail Sturdza”, Iași', 'Col Teh „M. Sturdza” Iasi', 'IS');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Tehnic „Mircea Cel Bătrân”', 'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Tehnic „Mircea Cristea” Brașov', 'BV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic „Miron Costin”, Municipiul Roman', 'Ctmc, Roman', 'NT');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Tehnic Motru', 'GJ');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Tehnic Nr 2 Tg-Jiu', 'GJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic Nr. 1 Vadu Crișului', 'Ct Nr. 1 Vadu Crișului', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic „Petru Maior”', 'Col. Teh. „Petru Maior”', 'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Tehnic „Petru Mușat” Suceava', 'SV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic „Petru Poni”, Municipiul Roman', 'Ctpp, Roman', 'NT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic „Raluca Ripan” Cluj-Napoca', 'Colegiul Tehnic „Raluca Ripan” Cluj', 'CJ');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Tehnic Rădăuți', 'SV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic Reșița', 'Colegiul Tehnic Resita', 'CS');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Tehnic „Samuil Isopescu” Suceava', 'SV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic „Simion Mehedinți” Codlea', 'Colegiul Tehnic Codlea', 'BV');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Tehnic „Traian Vuia” Oradea', 'BH');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Tehnic „Transilvania” Brașov', 'BV');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Tehnic Turda', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic „Valeriu D. Cotea” Focsani', 'Col. Tehn. „Valeriu D. Cotea” Focsani', 'VN');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnic „Viceamiral Ioan Bălănescu” Giurgiu', 'Col. Teh. „Viceamiral Ioan Bălănescu”', 'GR');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Tehnic „Victor Ungureanu” Câmpia Turzii', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnologic „Constantin Brâncoveanu”', 'C.Teh. „C. Brincoveanu”', 'MH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnologic „Grigore Cerchez”', 'Col. Tehn. „Grigore Cerchez”', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnologic „Spiru Haret”, Municipiul Piatra-Neamț', 'Ctsh, Piatra Neamț', 'NT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Tehnologic „Viaceslav Harnaj”', 'Col. Tehn. „V. Harnaj”', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Terțiar Nonuniversitar', 'Upet', 'HD');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Terțiar Usamvb', 'Colegiul Usamvb', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Terțiar Nonuniversitar „Eftimie Murgu” Reșița', 'Colegiul Terțiar Nonuniversitar', 'CS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Terțiar Nonuniversitar Pitești', 'Col. Terțiar Pitești', 'AG');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Terțiar Nonuniversitar-Usamvb', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Ucecom „Spiru Haret”', 'Col. Ucecom „Spiru Haret”', 'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul Universitar Spiru Haret', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Universitar „Spiru Haret” Craiova', 'Colegiul Universitar Craiova', 'DJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Colegiul Universității „Hyperion”', 'Colegiul „Hyperion”', 'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul „Vasile Lovinescu” Fălticeni', 'SV');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Colegiul „Csiky Gergely” Arad', 'AR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Agricol „Dr. C. Angelescu” Municipiul Buzău', 'Lic Agr Angelescu', 'BZ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Agricol Poarta Albă', 'Lic Agricol Poarta Albă', 'CT');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul „Alexandru Cel Bun” Botosani', 'BT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul „Alexandru Odobescu” Lehliu Gara', 'Lic. „Al. Odobescu” Lehliu Gara', 'CL');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul „Andrei Mureșanu” Brașov', 'BV');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul „Atanasie Marienescu” Lipova', 'AR');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul „Aurel Rainu” Fieni', 'DB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Bănățean Oțelu Roșu', 'Lic Bănățean Oțelu Roșu', 'CS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Borsa', 'L Borsa', 'MM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul „Carol I”, Orașul Plopeni', 'Liceul „Carol I” Plopeni', 'PH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul „Carol I”, Oraș Bicaz', 'Lic Teoretic, Bicaz', 'NT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul „Charles Laugier” Craiova', 'Liceul Charles Laugier Craiova', 'DJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Cobadin', 'Lic Cobadin', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Constantin Brancoveanu, Oras Horezu', 'Lic C. Brancoveanu Horezu', 'VL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul „Corneliu Medrea” Zlatna', 'Lic. „C. Medrea” Zlatna', 'AB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Creștin „Logos” Bistrița', 'Lic „Logos” B-Ța', 'BN');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Cu Program Sportiv', 'BR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Cu Program Florin Sebes', 'Lps Sebes', 'AB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Cu Program Sportiv Alba Iulia', 'Lic. Sportiv Alba Iulia', 'AB');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Cu Program Sportiv Arad', 'AR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Cu Program Sportiv „Avram Iancu” Zalău', 'Lic. Pr. Sp. „a. Iancu” Zalău', 'SJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Cu Program Sportiv Bacău', 'Liceul Cu Program Sportiv Bacau', 'BC');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Cu Program Sportiv Baia Mare', 'Lps Bm', 'MM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Cu Program Sportiv „Banatul” Timișoara', 'Lic. Sportiv Banatul Timisoara', 'TM');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Cu Program Sportiv „Bihorul” Oradea', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Cu Program Sportiv Bistrița', 'Lic Progr Sport Bistrița', 'BN');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Cu Program Sportiv Botosani', 'BT');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Cu Program Sportiv Brașov', 'BV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Cu Program Sportiv Câmpulung', 'Lps Câmpulung', 'AG');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Cu Program Sportiv „Cetate” Deva', 'HD');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Cu Program Sportiv Cluj-Napoca', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Cu Program Sportiv Focsani', 'Lic. Cu Prg. Sportiv Focsani', 'VN');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Cu Program Sportiv „Helmut Duckadam” Clinceni', 'Liceul Cu Program Sportiv „Helmut Duckadam”', 'IF');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Cu Program Sportiv, Iași', 'Lps Iasi', 'IS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Cu Program Sportiv „Iolanda Balaș Șoter” Municipiul Buzău', 'Lps', 'BZ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Cu Program Sportiv, Localitatea Galati', 'Lic. Sportiv Gl', 'GL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Cu Program Sportiv „Mircea Eliade”', 'Lic. Cu Prog. Sp. „Mircea Eliade”', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Cu Program Sportiv, Mun. Vaslui', 'Lef Vaslui', 'VS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Cu Program Sportiv, Municipiul Piatra-Neamț', 'Lps, Piatra-Neamț', 'NT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Cu Program Sportiv, Municipiul Roman', 'Lps, Roman', 'NT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Cu Program Sportiv „Nadia Comăneci” Onești', 'Lps „N. Comăneci” Onești', 'BC');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Cu Program Sportiv „Nicolae Rotaru” Constanța', 'Lic Sp „Nicolae Rotaru” Cța', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Cu Program Sportiv „Petrache Triscu” Craiova', 'Liceul Petrache Triscu Craiova', 'DJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Cu Program Sportiv Satu Mare', 'Lps Satu Mare', 'SM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Cu Program Sportiv Slatina', 'Liceul Sportiv Slatina', 'OT');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Cu Program Sportiv Suceava', 'SV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Cu Program Sportiv „Szasz Adalbert” Tîrgu Mureș', 'Lps „S. Adalbert” Tg. Mureș', 'MS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Cu Program Sportiv Tg-Jiu', 'Lic Cu Program Sportiv Tg-Jiu', 'GJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Cu Program Sportiv „Viitorul” Pitești', 'Lps Pitești', 'AG');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul „Danubius” Calarasi', 'Lic. „Danubius” Calarasi', 'CL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul de Agricultura Si Industrie Alimentara Odobesti', 'Lic. de Agricultura Si Ind. Alimentara Odobesti',
        'VN');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul de Arta „Gheorghe Tattarescu” Focsani', 'Lic. de Arta „Gheorghe Tattarescu” Focsani', 'VN');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul de Arta „Stefan Luchian” Botosani', 'Lic. Arta „St. Luchian” Botosani', 'BT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul de Artă „Ioan Sima” Zalău', 'Lic. Artă „I. Sima” Zalău', 'SJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul de Artă „Ion Vidu” Timișoara', 'Lic. Arta „Ion Vidu” Timisoara', 'TM');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul de Artă Sibiu', 'SB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul de Arte „Aurel Popp” Satu Mare', 'Lar „Aurel Popp” Satu Mare', 'SM');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul de Arte „Bălașa Doamna” Târgoviște', 'DB');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul de Arte „Constantin Brailoiu” Tg-Jiu', 'GJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul de Arte „Corneliu Baba” Bistrița', 'Lic „C. Baba” Bistrita', 'BN');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul de Arte „Dimitrie Cuclin”, Localitatea Galati', 'Lic. Arte „D. Cuclin” Gl', 'GL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul de Arte „Dinu Lipatti” Pitești', 'Lic. Arte Dinu Lipatti Pitești', 'AG');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul de Arte „Dr. Palló Imre” Odorheiu Secuiesc', 'Lar „Dr. Pallo Imre” Odorhei', 'HR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul de Arte „George Georgescu” Tulcea', 'Liceul „G. Georgescu” Tulcea', 'TL');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul de Arte „Hariclea Darclee”', 'BR');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul de Arte „Ionel Perlea” Slobozia', 'IL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul de Arte „I.Șt.  Paulian”', 'Lic. Art. „I.St.  Paulian”', 'MH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul de Arte „Margareta Sterian” Municipiul Buzău', 'Lic. Arte Bz', 'BZ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul de Arte „Marin Sorescu” Craiova', 'Liceul Marin Sorescu Craiova', 'DJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul de Arte „Nagy István” Miercurea Ciuc', 'Lar „Nagy Istvan” Miercurea Ciuc', 'HR');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul de Arte Oradea', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul de Arte Plastice „Nicolae Tonitza”', 'Lic. „Nicolae Tonitza”', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul de Arte Plastice Timișoara', 'Lic. Arte Plastice Timisoara', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul de Arte „Plugor Sándor” Sfântu Gheorghe', 'Lic. de Arte „Plugor Sándor” Sfântu Gheorghe', 'CV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul de Arte „Regina Maria” Alba Iulia', 'Lic. Arte Alba Iulia', 'AB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul de Arte „Sabin Păuța” Reșița', 'Lic de Arte „Sabin Păuța” Reșița', 'CS');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul de Arte „Sigismund Toduță” Deva', 'HD');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul de Arte „Victor Brauner”, Municipiul Piatra-Neamț', 'Lavb, Piatra Neamț', 'NT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul de Arte Victor Giuleanu, Mun. Rm. Valcea', 'Lic V. Giuleanu Ramnicu Valcea', 'VL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul de Arte Vizuale „Romulus Ladea” Cluj-Napoca', 'Liceul de Arte Vizuale „Romulus Ladea” Cluj-Napoc',
        'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul de Coregrafie „Floria Capsali”', 'Lic. de Coregrafie „F. Capsali”', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul de Coregrafie și Artă Dramatică „Octavian Stroia” Cluj-Napoca',
        'Liceul de Coregrafie „Octavian Stroia” Cluj', 'CJ');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul de Industrie Alimentara Craiova', 'DJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul de Informatică „Tiberiu Popoviciu” Cluj-Napoca', 'Liceul de Informatică „Tiberiu Popoviciu” Cluj',
        'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul de Marină Constanța', 'Lic de Marină Cța', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul de Muzică „Tudor Jarda” Bistrița', 'Lic Muzică „T. Jarda” Bistrita', 'BN');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul de Transporturi Auto', 'Lic. Auto', 'MH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul de Transporturi Auto „Traian Vuia”, Municipiul Galati', 'Lic. „T. Vuia” Gl', 'GL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul de Turism Si Alimentatie „Dumitru Motoc”, Municipiul Galati', 'Lic. „D. Motoc” Gl', 'GL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul „Demostene Botez” Trușești', 'Liceul „Demostene Botez” Trusesti', 'BT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul „Dimitrie Cantemir” Babadag', 'Liceul Babadag', 'TL');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul „Dimitrie Cantemir” Darabani', 'BT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul „Dimitrie Negreanu” Botosani', 'Liceul „Dimitrie Negreanu”', 'BT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul „Dimitrie Paciurea”', 'Lic. „Dimitrie Paciurea”', 'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul „Don Orione” Oradea', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul „Dr. Lazar Chirila” Baia de Aries', 'Lic. Baia de Aries', 'AB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Economic „Alexandru Ioan Cuza”, Municipiul Piatra-Neamț', 'Le „Alexandru Ioan Cuza”, Piatra Neamț',
        'NT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Economic „Berde Áron” Sfântu Gheorghe', 'Lic. Ec. „Berde Áron” Sfântu Gheorghe', 'CV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Economic Năsăud', 'Lic Ec Năsăud', 'BN');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Economic „Virgil Madgearu” Constanța', 'Lic Ec „Virgil Madgearu” Cța', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul „Educația Viitorului” Constanța', 'Lic Educ Viitorului', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Energetic Constanța', 'Lic Energetic Cța', 'CT');
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
VALUES ('Liceul German „Hermann Oberth” Voluntari', 'IF');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul German Sebes', 'Lic. German Sebes', 'AB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul „Gh. Ruset Roznovanu”, Oraș Roznov', 'L „Gh. Ruset Roznovanu”, Roznov', 'NT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Greco-Catolic „Inochentie Micu” Cluj-Napoca', 'Liceul Greco-Catolic „Inochentie Micu” Cluj-Napoc',
        'CJ');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Greco-Catolic „Iuliu Maniu” Oradea', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Greco-Catolic „Timotei Cipariu”', 'Lic. Greco-Catolic „Timotei Cipariu”', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul „Hercules” Baile Herculane', 'Lic „Hercules” Baile Herculane', 'CS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul „Horea, Closca Si Crisan” Abrud', 'Lic „Hcc” Abrud', 'AB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Internațional Ioanid', 'Liceul Ioanid', 'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul „Ioan Buteanu” Gurahonț', 'AR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul „Kőrösi Csoma Sándor” Covasna', 'Lic. „Kőrösi Csoma Sándor” Covasna', 'CV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul „Marin Preda” Odorheiu Secuiesc', 'Lit „Marin Preda” Odorhei', 'HR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul „Matei Basarab” Craiova', 'Liceul Matei Basarab Craiova', 'DJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul „Mathias Hammer” Anina', 'Lic „Mathias Hammer” Anina', 'CS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul „Mihail Sadoveanu”, Comuna Borca', 'L „Mihail Sadoveanu”, Borca', 'NT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul „Miron Cristea” Subcetate', 'Lit „Miron Cristea” Subcetate', 'HR');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul „Natanael” Suceava', 'SV');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Național de Informatică Arad', 'AR');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Ortodox „Episcop Roman Ciorogariu” Oradea', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Ortodox „Sf. Nicolae” Zalău', 'Lic. Ortodox „Sf. Nicolae” Zalău', 'SJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Particular „Henri Coanda” Baia Mare', 'Lic Part H Coanda Bm', 'MM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Particular Nr. 1, Sat Bistrița, Comuna Alexandru Cel Bun', 'L Part Nr. 1, Sat Bistrița', 'NT');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Particular „Onicescu-Mihoc”', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Pedagogic „Anastasia Popescu”', 'Liceul „Anastasia Popescu”', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Pedagogic „Benedek Elek” Odorheiu Secuiesc', 'Lit „Benedek Elek” Odorhei', 'HR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Pedagogic „Bod Péter” Târgu Secuiesc', 'Lic. Ped. „Bod Péter” Târgu Secuiesc', 'CV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Pedagogic „Gheorghe Șincai” Zalău', 'Lic. Pedagogic „Gh. Șincai” Zalău', 'SJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Pedagogic „Ioan Popescu”, Mun. Bârlad', 'Lic Ped Bârlad', 'VS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Pedagogic „Matei Basarab” Slobozia', 'Liceul Ped. „Matei Basarab” Slobozia', 'IL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Pedagogic „Nicolae Iorga” Botosani', 'Liceul Pedagogic „N. Iorga” Botosani', 'BT');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Pedagogic „Stefan Banulescu” Calarasi', 'CL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Pedagogic „Taras Sevcenko” Sighetu Marmatiei', 'Lped T Sevcenko Sighet', 'MM');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Penitenciar Jilava', 'IF');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul „Petru Rareș” Feldioara', 'BV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Preda Buzescu, Oras Berbesti', 'Lic Preda Buzescu Berbesti', 'VL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul „Prima School” Municipiul Buzău', 'Lic Prima School', 'BZ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul „Profesia”', 'Liceul Profesia', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul „Radu Miron”, Mun. Vaslui', 'Lic Rmiron Vs', 'VS');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Reformat „Lorantffy Zsuzsanna” Oradea', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Reformat Satu Mare', 'Licteo Reformat Sm', 'SM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Reformat „Wesselenyi” Zalău', 'Lic. Reformat „Wesselenyi” Zalău', 'SJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul „Regele Carol I” Ostrov', 'Lic Ostrov', 'CT');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul „Regina Maria” Dorohoi', 'BT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Romano-Catolic „Josephus Calasantius” Carei', 'Lic Rom-Cat Carei', 'SM');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul „Româno-Finlandez”', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Sanitar „Antim Ivireanu”, Mun. Rm. Valcea', 'Lic Sanitar a. Ivireanu Rm. Valcea', 'VL');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul „Sever Bocu” Lipova', 'AR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul „Sextil Pușcariu” Bran', 'Liceul Bran', 'BV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Silvic Gurghiu', 'Lic. Silvic Gurghiu', 'MS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Silvic „Transilvania” Năsăud', 'Lic Silvic „Transilvania” Năsăud', 'BN');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul „Simion Mehedinti” Vidra', 'Lic. „Simion Mehedinti” Vidra', 'VN');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul „Simion Stolnicu”, Orașul Comarnic', 'Liceul „S. Stolnicu” Comarnic', 'PH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Special „Moldova”, Târgu Frumos', 'Lic Spec „Moldova” Tg. Frumos', 'IS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Special Pentru Deficienți de Vedere Cluj-Napoca', 'Liceul Special Pentru Deficienți de Vedere Cluj',
        'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Special Pentru Deficienți de Vedere Municipiul Buzău', 'Lsdv Bz', 'BZ');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Special „Sfânta Maria” Arad', 'AR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul „Ștefan Cel Mare”, Sat Codăești', 'Lic Codăești', 'VS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul „Ștefan Diaconescu” Potcoava', 'Liceul „St. Diaconescu” Potcoava', 'OT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul „Ștefan Procopiu”, Mun. Vaslui', 'Lic Ștefan Procopiu', 'VS');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul „Șt. O. Iosif” Rupea', 'BV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnic Municipiul Buzău', 'Liceul Tehnic Buzău', 'BZ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Administrativ și de Servicii „Victor Slăvescu”, Municipiul Ploiești',
        'Liceul Tehnologic „Victor Slavescu” Pl', 'PH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Agricol „Alexandru Borza” Ciumbrud', 'Lic. Teh. „a. Borza” Ciumbrud', 'AB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Agricol „Alexandru Borza” Geoagiu', 'Liceul Agricol „Alexandru Borza” Geoagiu', 'HD');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Agricol „Alexiu Berinde” Seini', 'Lth a Berinde Seini', 'MM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Agricol Beclean', 'Lic Teh Agricol Beclean', 'BN');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Agricol Bistrița', 'Lic Teh Agricol Bistrița', 'BN');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Agricol, Comuna Bărcănești', 'Liceul Tehnologic Agricol Barcanesti', 'PH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Agricol Comuna Smeeni', 'Lic Teh Smeeni', 'BZ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Agricol „Mihail Kogalniceanu”, Miroslava', 'Lic Teh Agr Miroslava', 'IS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Agricol „Nicolae Cornățeanu” Tulcea', 'Liceul Agricol Tulcea', 'TL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Agroindustrial „Tamasi Aron” Borș', 'Liceul Tehnologic Agroindustrial „T. Aron” Borș', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Agromontan „Romeo Constantinescu”, Orașul Vălenii de Munte',
        'Liceul Tehn. „R. Constantinescu” Valeni de Munte', 'PH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Aiud', 'Lic. Teh. Aiud', 'AB');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic „Alexandru Borza” Cluj-Napoca', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Alexandru Domsa” Alba Iulia', 'Lic. Tehn. „Al. Domsa” Alba Iulia', 'AB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Alexandru Filipascu” Petrova', 'Lth a Filipascu Petrova', 'MM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Alexandru Ioan Cuza”, Mun. Bârlad', 'Lic. Tehn Al. I. Cuza', 'VS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Alexandru Ioan Cuza” Panciu', 'Lic. Tehn. „Alexandru Ioan Cuza” Panciu', 'VN');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Alexandru Macedonski” Melinesti', 'Liceul Melinesti', 'DJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Alexandru Vlahuță” Podu Turcului', 'Liceul Teh „Al. Vlahuta” P. Turcului', 'BC');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Alexe Marin” Slatina', 'Liceul Tehn „Alexe Marin” Slatina', 'OT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Al. Ioan Cuza” Slobozia', 'Liceul Teh. „Al. Ioan Cuza” Slobozia', 'IL');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic „Al. Vlahuta” Sendriceni', 'BT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Andrei Șaguna” Botoroaga', 'Lth „Andrei Șaguna” Botoroaga', 'TR');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic „Anghel Saligny”', 'BR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Anghel Saligny” Bacău', 'Liceul Tehnologic a. Saligny Bacău', 'BC');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Anghel Saligny” Fetești', 'Liceul Teh „Anghel Saligny” Fetești', 'IL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Anghel Saligny”, Localitatea Galati', 'Lic. Teh. „a. Saligny” Gl', 'GL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Anghel Saligny”, Municipiul Ploiești', 'Liceul Tehnologic „Anghel Saligny” Ploiesti', 'PH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Anghel Saligny” Roșiori de Vede', 'Lth „Anghel Saligny” Roșiori de Vede', 'TR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Anghel Saligny” Tulcea', 'Liceul „a. Saligny” Tulcea', 'TL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Anghel Saligny” Turț', 'Lteh „Anghel Saligny” Turț', 'SM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Apor Péter” Târgu Secuiesc', 'Lic. Tehn. „Apor Péter” Târgu Secuiesc', 'CV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Ardud', 'Lteh Ardud', 'SM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Arhimandrit Chiriac Nicolau”, Comuna Vânători-Neamț',
        'L Teh „Arhim. Chiriac Nicolau”, Vânători-Neamț', 'NT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Astra” Pitești', 'Lic. Teh. Astra Pitești', 'AG');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Aurel Persu” Tîrgu Mureș', 'Lic. Tehn. „a. Persu” Tg. Mureș', 'MS');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic „Aurel Vlaicu” Arad', 'AR');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic „Aurel Vlaicu” Cluj-Napoca', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Aurel Vlaicu” Lugoj', 'Lic. Teh. „a. Vlaicu” Mun. Lugoj', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Aurel Vlaicu”, Municipiul Galati', 'Lic. Teh. „a. Vlaicu” Gl', 'GL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Auto Câmpulung', 'Lic. Teh. Auto Câmpulung', 'AG');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Auto Craiova', 'Liceul Auto Craiova', 'DJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Auto Curtea de Argeș', 'Lic. Teh. Auto Curtea de Ag', 'AG');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Automecanica” Mediaș', 'Lic Tehn Automecanica Mediaș', 'SB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Avram Iancu” Sibiu', 'Lic Tehn „Avram Iancu” Sibiu', 'SB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Avram Iancu” Tîrgu Mureș', 'Lic. Tehn. „a. Iancu” Tg. Mureș', 'MS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Axiopolis” Cernavodă', 'Lic Teh „Axiopolis” Cernavodă', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Azur” Timișoara', 'Lic. Teh. „Azur” Timisoara', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Baia de Fier', 'Lic Teh Baia de Fier', 'GJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Balteni', 'Lic Teh Balteni', 'GJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Bányai János” Odorheiu Secuiesc', 'Gri „Banyai Janos” Odorhei', 'HR');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic „Barbu a. Știrbey” Buftea', 'IF');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Baróti Szabó Dávid” Baraolt', 'Lic. Tehn. „Baróti Szabó Dávid” Baraolt', 'CV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Barsesti', 'Lic Teh Barsesti', 'GJ');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic Beliu', 'AR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Berzovia', 'So8 Berzovia', 'CS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Bistrița', 'Lic Teh Bistrița', 'BN');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Brad Segal” Tulcea', 'Liceul „Brad Segal” Tulcea', 'TL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Bratianu, Mun. Dragasani', 'Lic Teh Bratianu Dragasani', 'VL');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic Bucecea', 'BT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Bustuchin', 'Lic Teh Bustuchin', 'GJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Capitan Nicolae Plesoianu, Mun. Rm. Valcea', 'Lic Teh Plesoianu Rm. Valcea', 'VL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Carol I”, Comuna Valea Doftanei', 'Liceul Tehnologic „Carol I”, Comuna Valea Doftane',
        'PH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Carol I”, Municipiul Galati', 'Lic. Teh. „Carol I” Gl', 'GL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Carol I” Slatina', 'Liceul Tehn „Carol I” Slatina', 'OT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „C.a. Rosetti” Constanța', 'Lic Teh „C a Rosetti” Cța', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Carsium” Hârșova', 'Lic Tehnologic „Carsium” Hârșova', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Cezar Nicolau” Brănești', 'Liceul Tehnologic „Cezar Nicolau” Branesti', 'IF');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic Chișineu Criș', 'AR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Ciobanu', 'Lic Teh Ciobanu', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Cisnădie', 'Lic Tehn Cisnădie', 'SB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Clisura Dunării” Moldova Nouă', 'Lth Moldova Noua', 'CS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Cogealac', 'Lic Teh Cogealac', 'CT');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic Cojasca', 'DB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic, Comuna Filipeștii de Pădure', 'Liceul Tehnologic Filipestii de Padure', 'PH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Comuna Lopătari', 'Lic Teh Lopătari', 'BZ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Comuna Rușețu', 'Lic Teh Rușețu', 'BZ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Comuna Vernești', 'Lic Teh Vernești', 'BZ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Concord” Constanța', 'Lic Teh „Concord” Cța', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Constantin Brancusi” Craiova', 'Liceul Constantin Brancusi Craiova', 'DJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Constantin Brâncoveanu” Târgoviște', 'Liceul Tehnologic „Constantin Brâncoveanu” Tgv',
        'DB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Constantin Brâncuși”', 'Lic. Tehn. „Constantin Brâncuși”', 'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic „Constantin Brâncuși” Dej', 'CJ');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic „Constantin Brâncuși” Oradea', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Constantin Brâncuși” Pitești', 'Lic. Teh. C. Brâncuși Pitești', 'AG');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Constantin Brâncuși” Satu Mare', 'Ltehn „Constantin Brâncuși” Sm', 'SM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Constantin Brâncuși” Sfântu Gheorghe', 'Lic. Tehn. „Constantin Brâncuși” Sfântu Gheorghe',
        'CV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Constantin Brâncuși” Târnăveni', 'Lic. Tehn. „C. Brâncuși” Târnăveni', 'MS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Constantin Brâncuși” Tîrgu Mureș', 'Lic. Tehn. „C. Brâncuși” Tg. Mureș', 'MS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Constantin Brîncoveanu” Scornicești', 'Liceul Teh. „C. Brincoveanu” Scornicesti', 'OT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Constantin Bursan” Hunedoara', 'Lic. Tehn. „C. Bursan” Hunedoara', 'HD');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Constantin Cantacuzino”, Orașul Băicoi', 'Liceul Tehnologic „C. Cantacuzino” Baicoi', 'PH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Constantin Dobrescu” Curtea de Argeș', 'Lic. Teh. Constantin Dobrescu Curtea de Argeș',
        'AG');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Constantin Filipescu” Caracal', 'Liceul Tehnologic „C. Filipescu” Caracal', 'OT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Constantin George Calinescu” Gradistea', 'Lic. Tehnologic „George Calinescu” Gradistea',
        'CL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Constantin Ianculescu” Carcea', 'Liceul Carcea', 'DJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Constantin Istrati”, Municipiul Câmpina', 'Liceul „C. Istrati” Campina', 'PH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Constantin Lucaci” Bocșa', 'Lth „Constantin Lucaci” Bocșa', 'CS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Constantin Nicolaescu-Plopsor” Plenita', 'Liceul Plenita', 'DJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Construcții de Mașini Mioveni', 'Lic. Teh. Construcții Mașini Mioveni', 'AG');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Construcții și Arhitectură „Carol I” Sibiu', 'Lic Tehn C-Ții și Arh „Carol I” Sibiu', 'SB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Corbu', 'Gri Corbu', 'HR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Corund', 'Gri Corund', 'HR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Costache Conachi”, Comuna Pechea', 'Lic. Teh. „C. Conachi” Pechea', 'GL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Costești', 'Lic. Teh. Costești', 'AG');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Costin D. Nenitescu” Craiova', 'Liceul Costin D. Nenitescu Craiova', 'DJ');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic Coțușca', 'BT');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic Crâmpoia', 'OT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Cristofor Nako” Sânnicolau Mare', 'Lic. Tehn. C. Nako Sannicolau Mare', 'TM');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic „Crișan” Crișcior', 'HD');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Crucea', 'Lic Tehnologic Crucea', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Cserey-Goga” Crasna', 'Lic. Tehnologic „Cserey-Goga” Crasna', 'SJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „C-Tin Brancusi”- Pestisani', 'Lic Teh „C. Brancusi” Pestisani', 'GJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Dacia”', 'Lic. Tehnol. „Dacia”', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Dacia” Caransebeș', 'Lth Dacia Caransebes', 'CS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Dacia” Pitești', 'Lic. Teh. Dacia Pitești', 'AG');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Dan Mateescu” Calarasi', 'Lic. Tehnologic „Dan Mateescu” Calarasi', 'CL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Danubius” Corabia', 'Liceul Tehn „Danubius” Corabia', 'OT');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic Dărmănești', 'BC');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic de Construcții și Protecția Mediului Arad',
        'Liceul Tehnolo. Construcții Protecția Mediului Arad', 'AR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic de Electronică și Automatizări „Caius Iacob” Arad', 'Liceul Tehnologic „Caius Iacob” Arad',
        'AR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic de Electronică și Telecomunicații „Gheorghe Mârzescu”, Iași', 'Lic Teh Etc Iasi', 'IS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic de Electrotehnică și Telecomunicații Constanța',
        'Lic Tehnologic de Electrotehnică Telecomunicații', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic de Industrie Alimentară Arad', 'Liceul Tehnologic Industrie Alimentară Arad', 'AR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic de Industrie Alimentară Fetești', 'Liceul Teh. de Ind. Alim. Fetești', 'IL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic de Industrie Alimentară „George Emil Palade” Satu Mare', 'Ltehn „George Emil Palade” Sm',
        'SM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic de Industrie Alimentară „Terezianum” Sibiu', 'Lic Tehn Ind Alim „Terezianum” Sibiu', 'SB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic de Industrie Alimentară Timișoara', 'Lic. Teh. de Ind. Alimentara Timisoara', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic de Mecatronică și Automatizări, Iași', 'Ltma Iasi', 'IS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic de Meserii și Servicii Municipiul Buzău', 'Lic. Teh. Meserii', 'BZ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic de Metrologie „Traian Vuia”', 'Lic. Tehnol. de Metrologie „Traian Vuia”', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic de Servicii Bistrița', 'Lic Teh de Serv Bistrița', 'BN');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic de Servicii „Sfântul Apostol Andrei”, Municipiul Ploiești',
        'Liceul Tehnologic „Sf. Apostol Andrei” Ploiesti', 'PH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic de Silvicultură și Agricultură „Casa Verde” Timișoara',
        'Lic. Teh. Silvic „Casa Verde” Timisoara', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic de Transport Feroviar „Anghel Saligny” Simeria',
        'Liceul Tehnologic Tf. „Anghel Saligny” Simeria', 'HD');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic de Transporturi Auto Baia Sprie', 'Ltehn Transp Auto Bs', 'MM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic de Transporturi Auto Craiova', 'Liceul de Transporturi Auto Craiova', 'DJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic de Transporturi Auto „Henri Coandă” Arad', 'Liceul Tehnologic Transp. Auto „H. Coandă” Arad',
        'AR');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic de Transporturi Auto Târgoviște', 'DB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic de Transporturi, Municipiul Ploiești', 'Liceul Tehnologic de Transporturi Ploiesti', 'PH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic de Transporturi și de Construcții, Iași', 'Lic Teh Transp Si Constr Iasi', 'IS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic de Turism, Oras Calimanesti', 'Lic Teh Turism Calimanesti', 'VL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic de Turism Si Alimentatie Arieseni', 'Lic. Teh. Arieseni', 'AB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic de Vest Timișoara', 'Lic. Teh. Vest Timisoara', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Decebal”', 'Lic. Teh. Decebal', 'MH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Decebal” Caransebeș', 'Lth „Decebal” Caransebeș', 'CS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Dierna”', 'Lic. Teh. Dierna', 'MH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Dimitrie Bolintineanu” Bolintin Vale', 'Lic. Tehn. „Dimitrie Bolintineanu”', 'GR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Dimitrie Cantemir”, Sat Fălciu', 'Lic. Tehn Fălciu', 'VS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Dimitrie Dima” Pitești', 'Lic. Teh. Dimitrie Dima Pitești', 'AG');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Dimitrie Filipescu” Municipiul Buzău', 'Lic. Teh. Filipescu', 'BZ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Dimitrie Filisanu” Filiasi', 'Liceul Filiasi', 'DJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Dimitrie Gusti”', 'Lic. Tehn. „Dimitrie Gusti”', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Dimitrie Leonida” Constanța', 'Lic Tehnologic „Dimitrie Leonida” Cța', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Dimitrie Leonida”, Iași', 'Lic Teh „D. Leonida” Iasi', 'IS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Dimitrie Leonida”, Municipiul Piatra-Neamț', 'Ltdl, Piatra Neamț', 'NT');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic „Dimitrie Leonida” Petroșani', 'HD');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Dimitrie Petrescu” Caracal', 'Liceul Tehn „D. Petrescu” Caracal', 'OT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Dinu Brătianu” Ștefănești', 'Lic. Teh. Dinu Brătianu Ștefănești', 'AG');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Doamna Chiajna” Chiajna', 'Liceul Tehnologic „Doamna Chiajna” Rosu', 'IF');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Dobrogea” Castelu', 'Lic Teh „Dobrogea” Castelu', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Domnul Tudor”', 'Lic. Teh. Domnul Tudor', 'MH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Domokos Kazmer” Sovata', 'Lic. Tehn. „D. Kazmer” Sovata', 'MS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Dorin Pavel” Alba Iulia', 'Lic. Tehn. „Dorin Pavel” Alba Iulia', 'AB');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic Dorna Candrenilor', 'SV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Dr. Florian Ulmeanu” Ulmeni', 'Lth Dr F Ulmeanu Ulmeni', 'MM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Dr. Ioan Șenchea” Făgăraș', 'Liceul Tehnologic „I. Șenchea” Făgăraș', 'BV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Dragomir Hurmuzescu”', 'Lic. Tehn. „Dragomir Hurmuzescu”', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Dragomir Hurmuzescu” Medgidia', 'Lic Tehnologic „Dragomir Hurmuzescu” Medgidia', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Drăgănești-Olt', 'Liceul Teh. Draganesti-Olt', 'OT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Drăgănești-Vlașca', 'Lth Drăgănești-Vlașca', 'TR');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic „Dr. C. Angelescu” Găești', 'DB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Duiliu Zamfirescu” Dragalina', 'Lic. Tehnologic „Duiliu Zamfirescu” Dragalina', 'CL');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic „Dumitru Dumitrescu” Buftea', 'IF');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic „Dumitru Mangeron” Bacău', 'BC');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Economic de Turism, Iași', 'Lic Ec de Turism Iasi', 'IS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Economic „Elina Matei Basarab” Municipiul Rîmnicu Sărat', 'Lic. Teh. Economic Rs', 'BZ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Economic „Nicolae Iorga”, Pașcani', 'Lic „Nicolae Iorga” Pascani', 'IS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Economic „Virgil Madgearu”, Iași', 'Lic Ec „V. Madgearu” Iasi', 'IS');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic „Edmond Nicolau” Brăila', 'BR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Electromureș” Tîrgu Mureș', 'Lic. Tehn. „Electromureș” Tg. Mureș', 'MS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Electrotimiș” Timișoara', 'Lic. Teh. „Electrotimiș” Timisoara', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Elena Caragiani”, Localitatea Tecuci', 'Lic. Teh. „E. Caragiani” Tc', 'GL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Elie Radu”', 'Lic. Tehn. „Elie Radu”', 'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic „Elie Radu” Botosani', 'BT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Elisa Zamfirescu” Satu Mare', 'Lteh „Elisa Zamfirescu” Sm', 'SM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Emil Racoviță” Roșiori de Vede', 'Lth „Emil Racoviță” Roșiori de Vede', 'TR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Energetic „Dragomir Hurmuzescu” Deva', 'Liceul Tehnologic Energetic „D. Hurmuzescu” Deva',
        'HD');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Energetic „Elie Radu”, Municipiul Ploiești', 'Liceul Tehnic „Elie Radu” Ploiesti', 'PH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Energetic, Municipiul Câmpina', 'Liceul Tehnologic Energetic Campina', 'PH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Energetic „Regele Ferdinand I” Timișoara', 'Lic. Teh. „Regele Ferdinand I” Timisoara', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Eötvös József” Odorheiu Secuiesc', 'Gri „Eotvos Jozsef” Odorhei', 'HR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Eremia Grigorescu” Marasesti', 'Lic. Tehn. „Eremia Grigorescu” Marasesti', 'VN');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Eremia Grigorescu”, Oras Tg. Bujor', 'Lic. Teh. „E. Grigorescu” Tg. Bujor', 'GL');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic Făget', 'BC');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Feldru', 'Lic Teh Feldru', 'BN');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic „Felix” Sânmartin', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Ferdinand I” Curtea de Argeș', 'Lic. Teh. Ferdinand I Curtea de Argeș', 'AG');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Ferdinand I, Mun. Rm. Valcea', 'Lic Teh Ferdinand I Rm. Valcea', 'VL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Fierbinți-Târg', 'Liceul Teh. Fierbinți-Târg', 'IL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Florian Porcius” Rodna', 'Lic Teh „F. Porcius” Rodna', 'BN');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Fogarasy Mihály” Gheorgheni', 'Gri „Fogarasy” Gheorgheni', 'HR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Forestier, Mun. Rm. Valcea', 'Lic Tehn Forestier, Mun. Rm. Valcea', 'VL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Forestier Sighetu Marmatiei', 'Lth Forestier Sighet', 'MM');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic „Francisc Neuman” Arad', 'AR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Gábor Áron” Târgu Secuiesc', 'Lic. Tehn. „Gábor Áron” Târgu Secuiesc', 'CV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Gábor Áron” Vlăhița', 'Gri „Gabor Aron” Vlahita', 'HR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „General David Praporgescu” Turnu Măgurele', 'Lth „G-Ral David Praporgescu” Turnu Măgurele',
        'TR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „General de Marina Nicolae Dumitrescu Maican”, Localitatea Galati', 'Lic. Teh. Marina Gl',
        'GL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic General Magheru, Mun. Rm. Valcea', 'Lic Teh G. Magheru Rm. Valcea', 'VL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „George Barițiu” Livada', 'Lteh „George Barițiu” Livada', 'SM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „George Bibescu” Craiova', 'Liceul George Bibescu Craiova', 'DJ');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic „Georgeta J. Cancicov” Parincea', 'BC');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic „Georgiana” Oradea', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „G.G. Longinescu” Focsani', 'Lic. Tehn. „G.G. Longinescu” Focsani', 'VN');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Ghenuță Coman”, Oraș Murgeni', 'Lic. Tehn Murgeni', 'VS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Gheorghe Duca” Constanța', 'Lic Tehnologic „Ghe Duca” Cța', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Gheorghe Ionescu-Sisești”, Comuna Valea Călugărească',
        'Liceul „Ghe. Ionescu-Sisesti” Valea Calugareasca', 'PH');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic „Gheorghe K. Constantinescu”', 'BR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Gheorghe Lazăr”, Orașul Plopeni', 'Liceul Tehnologic Plopeni', 'PH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Gheorghe Miron Costin” Constanța', 'Lic Teh Gheorghe Miron C-Ța', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Gheorghe Pop de Băsești” Cehu Silvaniei',
        'Lic. Tehnologic „G.P. de Băsești” Cehu Silvaniei', 'SJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Gheorghe Șincai” Tîrgu Mureș', 'Lic. Tehn. „G. Șincai” Tg. Mureș', 'MS');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic Gherla', 'CJ');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic „Goga Ionescu” Titu', 'DB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „G-Ral C-Tin Sandru” Balta, Runcu', 'Lic Teh „G-Ral C-Tin Sandru” Balta, Runcu', 'GJ');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic „Grigore Antipa” Bacău', 'BC');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Grigore C. Moisil” Municipiul Buzău', 'Lic. Teh. Moisil', 'BZ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Grigore C Moisil” Targu Lapus', 'Lth Gc Moisil Tg Lapus', 'MM');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic „Grigore Moisil”', 'BR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Grigore Moisil” Bistrița', 'Lic Teh „Gr. Moisil” Bistrița', 'BN');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Grigore Moisil” Deva', 'Lic. Tehn. „Grigore Moisil” Deva', 'HD');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Halânga', 'Lic. Teh. Halanga', 'MH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Haralamb Vasiliu”, Podu Iloaiei', 'Lic Teh Podu Iloaiei', 'IS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic, Hârlău', 'Lic Teh Harlau', 'IS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Henri Coandă” Beclean', 'Lic Teh „H. Coanda” Beclean', 'BN');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Henri Municipiul Buzău', 'Lic. Coandă Bz', 'BZ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Henri Coandă” Sibiu', 'Lic Tehn „H. Coandă” Sibiu', 'SB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Henri Coandă” Tulcea', 'Liceul „H. Coandă” Tulcea', 'TL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Horea Cloșca și Crișan” Cluj-Napoca', 'Liceul Tehnologic „Horea Cloșca și Crișan” Cluj',
        'CJ');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic „Horea” Marghita', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Horia Vintila” Segarcea', 'Liceul Horia Vintila Segarcea', 'DJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „I.a. Rădulescu Pogoneanu” Oraș Pogoanele', 'Lic Teh Pogoanele', 'BZ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Iacobeni', 'Lic Tehn Iacobeni', 'SB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Iancu Jianu', 'Liceul Teh. Iancu Jianu', 'OT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „I.C. Petrescu” Stîlpeni', 'Lic. Teh. I.C. Petrescu Stîlpeni', 'AG');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „I.C. Brătianu” Nicolae Bălcescu', 'Lic Tehnologic Nicolae Bălcescu', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Iernut', 'Lic. Tehn. Iernut', 'MS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Ilie Măcelariu” Miercurea Sibiului', 'Lic Tehn „I. Măcelariu” Miercurea Sibiului', 'SB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Independența', 'Lic Tehnologic Independența', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Independența” Sibiu', 'Lic Tehn „Independența” Sibiu', 'SB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Ioachim Pop” Ileanda', 'Lic. Tehnologic „I. Pop” Ileanda', 'SJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Ioan Bojor” Reghin', 'Lic. Tehn. I. Reghin', 'MS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Ioan Corivan”, Mun. Huși', 'Lic. Tehn Huși', 'VS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Ioan Lupaș” Săliște', 'Lic Tehn „Ioan Lupaș” Săliște', 'SB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Ioan N. Roman” Constanța', 'Lic Tehnologic „Ioan N Roman” Cța', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Ioan Ossian” Șimleu Silvaniei', 'Lic. Tehnologic „I. Ossian” Șimleu Silvaniei', 'SJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Ioan Slavici” Timișoara', 'Lic Teh. I. Slavici Timisoara', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Ion Barbu” Giurgiu', 'Lic. Teh. „Ion Barbu”', 'GR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Ion Bănescu” Mangalia', 'Lic Teh „Ion Bănescu” Mangalia', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Ion Căian Românul” Căianu Mic', 'Lic Teh „I.C.R.” Căianu Mic', 'BN');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Ion Creangă”, Comuna Pipirig', 'Ltic, Pipirig', 'NT');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic „Ion Creangă” Curtici', 'AR');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic „Ion Ghica” Oltenita', 'CL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Ion I.C. Brătianu” Satu Mare', 'Lteh „Ion I.C. Brătianu” Sm', 'SM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Ion I.C. Brătianu”', 'Lic. Tehn. „Ion I.C. Brătianu”', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Ion Ionescu de La Brad”, Comuna Horia', 'Lt „Ion Ionescu de La Brad”, Horia', 'NT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Ion Mincu”, Mun. Vaslui', 'Lic. Tehn Ion Mincu', 'VS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Ion Mincu” Tulcea', 'Liceul „I. Mincu” Tulcea', 'TL');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic „Ion Nistor” Vicovu de Sus', 'SV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Ion Podaru” Ovidiu', 'Lic Tehnologic „Ion Podaru” Ovidiu', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Ion Popescu-Cilieni” Cilieni', 'Liceul Teh. „I.Popescu- Cilieni” Cilieni', 'OT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Ion Vlasiu” Tîrgu Mureș', 'Lic. Tehn. „I. Vlasiu” Tg. Mureș', 'MS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Ion. I.C. Brătianu” Timișoara', 'Lic. Teh. I.I.C. Bratianu Timisoara', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Ioniță G. Andron” Negrești-Oaș', 'Lteh „Ioniță G. Andron” Negrești-Oaș', 'SM');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic „Iordache Golescu” Găești', 'DB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Iordache Zossima” Armășești', 'Liceul Teh. „Iordache Zossima” Armășești', 'IL');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic „Iorgu Vîrnav Liteanu” Liteni', 'SV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Iosif Coriolan Buracu” Prigor', 'Lth Prigor', 'CS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Iuliu Maniu” Carei', 'Lteh „Iuliu Maniu” Carei', 'SM');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic „Iuliu Moldovan” Arad', 'AR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Izvoarele', 'Liceul Teh. Izvoarele', 'OT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Înălțarea Domnului” Slobozia', 'Liceul Teh. „Înălțarea Domnului” Slobozia', 'IL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Jacques M. Elias” Sascut', 'Liceul Tehnologic „J.M. Elias” Sascut', 'BC');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Jean Dinu” Adamclisi', 'Lic Teh Adamclisi', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Jidvei', 'Lic. Teh. Jidvei', 'AB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Jimbolia', 'Lic. Teh. Jimbolia', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Joannes Kajoni” Miercurea Ciuc', 'Gri „Joannes Kajoni” Miercurea Ciuc', 'HR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Johannes Lebel” Tălmaciu', 'Lic Tehn „J. Lebel” Tălmaciu', 'SB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Justinian Marina, Oras Baile Olanesti', 'Lic Teh Justinian Marina Baile Olanesti', 'VL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Kós Károly” Miercurea Ciuc', 'Gri „Kos Karoly” Miercurea Ciuc', 'HR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Kós Károly” Odorheiu Secuiesc', 'Gri „Kos Karoly” Odorhei', 'HR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Kós Károly” Sfântu Gheorghe', 'Lic. Tehn. „Kós Károly” Sfântu Gheorghe', 'CV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Lazăr Edeleanu”, Municipiul Ploiești', 'Liceul „Lazar Edeleanu” Ploiesti', 'PH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Lazăr Edeleanu” Năvodari', 'Lic Tehnologic „Lazăr Edeleanu” Năvodari', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Lechința', 'Lic Teh Lechința', 'BN');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Liviu Rebreanu” Bălan', 'Gri „Liviu Rebreanu” Balan', 'HR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Liviu Rebreanu” Hida', 'Lic. Tehnologic „L. Rebreanu” Hida', 'SJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Liviu Rebreanu” Maieru', 'Lic Teh „L.R.” Maieru', 'BN');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Liviu Rebreanu” Mozăceni', 'Lic. Teh. Liviu Rebreanu Mozăceni', 'AG');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Lorin Sălăgean”', 'Lic. Teh. L. Salagean', 'MH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Lucian Blaga” Reghin', 'Lic. Tehn. „L. Blaga” Reghin', 'MS');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic Lupeni', 'HD');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Malaxa” Zărnești', 'Liceul Tehnologic Zărnești', 'BV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Marcel Guguianu”, Sat Zorleni', 'Lic. Tehn Marcel Guguianu', 'VS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Marin Grigore Năstase” Tărtășești', 'Liceul Tehnologic Tărtășești', 'DB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Marmatia” Sighetu Marmatiei', 'Lth Marmatia Sighet', 'MM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Matei Basarab”', 'Lic. Teh. „Matei Basarab”', 'MH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Matei Basarab” Caracal', 'Liceul Tehn „Matei Basarab” Caracal', 'OT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Matei Basarab” Manastirea', 'Lic. Tehnologic „Matei Basarab” Manastirea', 'CL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Matei Basarab” Măxineni', 'Liceul Tehnologic „Matei Basarab”', 'BR');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic „Matei Corvin” Hunedoara', 'HD');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Max Ausnit” Caransebeș', 'Lth Max Ausnit Caransebes', 'CS');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic Măcin', 'TL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Mârșa', 'Lic Tehn Mârșa', 'SB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Mecanic, Municipiul Câmpina', 'Liceul Tehnologic Mecanic, Municipiul Campina', 'PH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Metalurgic Slatina', 'Liceul Tehn Metalurgic Slatina', 'OT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Mihai Busuioc”, Pașcani', 'Lic Teh „M. Busuioc” Pascani', 'IS');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic „Mihai Eminescu” Dumbrăveni', 'SV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Mihai Eminescu” Slobozia', 'Liceul Teh. „Mihai Eminescu” Slobozia', 'IL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Mihai Novac” Oravița', 'Lth „Mihai Novac” Oravița', 'CS');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic „Mihai Viteazu” Vulcan', 'HD');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Mihai Viteazul” Călugăreni', 'Lic. Teh. „Mihai Viteazul” Calugareni', 'GR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Mihai Viteazul” Mihai Viteazu', 'Lic Tehnologic Mihai Viteazu', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Mihai Viteazul” Zalău', 'Lic. Tehnologic „M. Viteazul” Zalău', 'SJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Mircea Vulcănescu”', 'Lic. Tehnol. „M. Vulcănescu”', 'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic „Moga Voievod” Hălmagiu', 'AR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Nicanor Moroșan” Pârtestii de Jos', 'Liceul Tehnologic „N. Moroșan” Pârteștii de Jos',
        'SV');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic „Nicolae Balcescu” Flamânzi', 'BT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Nicolae Balcescu” Oltenita', 'Lic. Tehnologic „N. Balcescu” Oltenita', 'CL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Nicolae Bălcescu” Alexandria', 'Lth „Nicolae Bălcescu” Alexandria', 'TR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Nicolae Bălcescu” Balș', 'Liceul Tehn „N. Balcescu” Bals', 'OT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Nicolae Bălcescu” Întorsura Buzăului', 'Lic. Tehn. „Nicolae Bălcescu” Întorsura Buzăului',
        'CV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Nicolae Bălcescu” Voluntari', 'Liceul Tehnologic „Nicolae Balcescu” Voluntari', 'IF');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic „Nicolae Ciorănescu” Târgoviște', 'DB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Nicolae Dumitrescu” Cumpăna', 'Lic Tehnologic Cumpăna', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Nicolae Iorga”, Oraș Negrești', 'Lic. Tehn Negrești', 'VS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Nicolae Istrățoiu” Deleni', 'Lic Tehnologic Deleni', 'CT');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic „Nicolae Oncescu”', 'BR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Nicolae Stoica de Hațeg” Mehadia', 'Lth „Nicolae Stoica de Hateg” Mehadia', 'CS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Nicolae Teclu” Copșa Mică', 'Lic Tehn „N. Teclu” Copșa Mică', 'SB');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic „Nicolae Titulescu” Însurăței', 'BR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Nicolae Titulescu” Medgidia', 'Lic Tehn „Nicolae Titulescu” Medgidia', 'CT');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic „Nicolai Nanu” Broșteni', 'SV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Nicolaus Olahus” Orăștie', 'Lic. Tehn. „Nicolaus Olahus” Orăștie', 'HD');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Nikola Tesla”', 'Lic. Tehn. „Nikola Tesla”', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Nisiporești, Comuna Botești', 'Lt, Nisiporești', 'NT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Nr. 1 Alexandria', 'Lth Nr. 1 Alexandria', 'TR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Nr. 1 Balș', 'Liceul Tehn Nr. 1 Bals', 'OT');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic Nr. 1 Câmpulung Moldovenesc', 'SV');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic Nr. 1 Cluj-Napoca', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Nr. 1 Mărăcineni', 'Lic. Teh. Nr. 1 Mărăcineni', 'AG');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Nr. 2 Roșiori de Vede', 'Lth Nr. 2 Roșiori de Vede', 'TR');
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
VALUES ('Liceul Tehnologic Nr. 1 Dobrești', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Nr. 1 Fundulea', 'Lic. Tehnologic Nr. 1 Fundulea', 'CL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Nr. 1 Gâlgău', 'Lic. Tehnologic Nr. 1 Gâlgău', 'SJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Nr. 1 Luduș', 'Lic. Tehn. Nr. 1 Luduș', 'MS');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic Nr. 1 Popești', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Nr. 1 Prundu', 'Lic. Teh. Nr. 1 Prundu', 'GR');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic Nr. 1 Salonta', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Nr. 1 Sărmășag', 'Lic. Tehnologic Nr. 1 Sărmășag', 'SJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Nr. 1 Sighișoara', 'Lic. Tehn. Nr. 1 Sighișoara', 'MS');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic Nr. 1 Suplacu de Barcău', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Nr. 1 Surduc', 'Lic. Tehnologic Nr. 1 Surduc', 'SJ');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic Nr. 1 Șuncuiuș', 'BH');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic Nr. 1 Valea Lui Mihai', 'BH');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic Nucet', 'DB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Ocna Mures', 'Lic. Teh. Ocna Mures', 'AB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Ocna Sugatag', 'Lth Ocna Sugatag', 'MM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Octavian Goga” Jibou', 'Lic. Tehnologic „O. Goga” Jibou', 'SJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Octavian Goga” Rozavlea', 'Lth O Goga Rozavlea', 'MM');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic „Oltea Doamna” Dolhasca', 'SV');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic Onești', 'BC');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic, Oras Baile Govora', 'Lic Teh Baile-Govora', 'VL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Oraș Pătârlagele', 'Lic Tehn Pătârlagele', 'BZ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Ovid Caledoniu”, Localitatea Tecuci', 'Lic. Teh. „O. Caledoniu” Tc', 'GL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Ovid Densusianu” Călan', 'Lic Tehn. „O. Densusianu” Călan', 'HD');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Pamfil Șeicaru” Ciorogârla', 'Liceul Tehnologic „Pamfil Seicaru” Ciorogarla', 'IF');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic „Panait Istrati” Brăila', 'BR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Paul Bujor”, Oras Beresti', 'Lic. Teh. „P. Bujor” Beresti', 'GL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Paul Dimo”, Municipiul Galati', 'Lic. Teh. „P. Dimo” Gl', 'GL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Petőfi Sándor” Dănești', 'Lit „Petofi Sandor” Danesti', 'HR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Petrache Poenaru, Oras Balcesti', 'Lic Teh P. Poenaru Balcesti', 'VL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Petre Banita” Calarasi', 'Liceul Calarasi', 'DJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Petre Ionescu Muscel” Domnești', 'Lic. Teh. Petre Ionescu Muscel Domnești', 'AG');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Petre Mitroi” Biled', 'Lic. Teh. P. Mitroi Biled', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Petre P. Carp”, Țibănești', 'Lic Teh Tibanesti', 'IS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Petri Mor” Nușfalău', 'Lic. Tehnologic „Petri Mor” Nușfalău', 'SJ');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic Petrol Moreni', 'DB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Petru Cupcea” Supuru de Jos', 'Lteh „Petru Cupcea” Supuru de Jos', 'SM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Petru Maior” Reghin', 'Lic. Tehn. „P. Maior” Reghin', 'MS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Petru Poni”', 'Lic. Tehnol. „Petru Poni”', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Petru Poni”, Iași', 'Lic Teh „P. Poni” Iasi', 'IS');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic „Petru Poni” Onești', 'BC');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic „Petru Rareș” Bacău', 'BC');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic „Petru Rareș” Botosani', 'BT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Petru Rareș”, Mun. Bârlad', 'Lic. Tehn Bârlad', 'VS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Petru Rareș”, Sat Vetrișoaia', 'Lic. Tehn Vetrișoaia', 'VS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Petru Rareș”, Târgu Frumos', 'Lic Teh Tg. Frumos', 'IS');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic Piatra-Olt', 'OT');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic Plopenii Mari', 'BT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Poienile de Sub Munte', 'L Tehn Pdsm', 'MM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Pontica” Constanța', 'Lic Teh „Pontica” Cța', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „P.S. Aurelian” Slatina', 'Liceul Tehn „P.S. Aurelian” Slatina', 'OT');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic Pucioasa', 'DB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Puskás Tivadar” Ditrău', 'Gri „Puskas Tivadar” Ditrau', 'HR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Puskás Tivadar” Sfântu Gheorghe', 'Lic. Tehn. „Puskás Tivadar” Sfântu Gheorghe', 'CV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Radu Negru”, Localitatea Galati', 'Lic. Teh. „R. Negru” Gl', 'GL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Radu Prișcu” Dobromir', 'Lic Tehnologic Dobromir', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Răchitoasa', 'Liceul Tehnologic Rachitoasa', 'BC');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic Râșnov', 'BV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Regele Mihai I Curtea de Argeș', 'Lic. Teh. Forestier Curtea de Argeș', 'AG');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic „Regele Mihai I” Săvârșin', 'AR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Repedea', 'Lth Repedea', 'MM');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic „Retezat” Uricani', 'HD');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Romulus Paraschivoiu” Lovrin', 'Lic. Teh. R. Paraschivoiu Lovrin', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Rosia de Amaradia', 'Lic Teh Rosia de Amaradia', 'GJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Rosia Jiu, Farcasesti', 'Lic. Teh. Rosia Jiu Farcasesti', 'GJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Ruscova', 'Lth Ruscova', 'MM');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic „Sandu Aldea” Calarasi', 'CL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Sanitar „Vasile Voiculescu” Oradea', 'Liceul Tehnologic Sanitar „V. Voiculescu” Oradea',
        'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic, Sat Cioranii de Jos, Comuna Ciorani', 'Liceul Tehnologic Cioranii de Jos', 'PH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic, Sat Mărgăriți Comuna Beceni', 'Liceul Beceni', 'BZ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic, Sat Puiești', 'Lic. Tehn Puiești', 'VS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic, Sat Vladia', 'Lic. Tehn Vladia', 'VS');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic „Sava Brancovici” Ineu', 'AR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Sebes', 'Lic. Teh. Sebes', 'AB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Sf. Antim Ivireanu”', 'Lic. Tehnol. „Sf. Antim Ivireanu”', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Sf. Haralambie” Turnu Măgurele', 'Lth „Sf. Haralambie” Turnu Măgurele', 'TR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Sf. Mucenic Sava” Comuna Berca', 'Lic Teh Berca', 'BZ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Sfantul Ioan”, Localitatea Galati', 'Lic. Teh. „Sf. Ioan” Gl', 'GL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Sfântu Nicolae” Deta', 'Lic. Tehn. „Sf. Nicolae” Deta', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Sfântul Gheorghe” Sângeorgiu de Pădure', 'Lic. Tehn. „Sf. Gheorghe” Sângeorgiu de Pădure',
        'MS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Sfântul Ioan de La Salle”, Sat Pildești, Comuna Cordun',
        'Lt „Sfântul Ioan de La Salle”, Pildești', 'NT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Sfântul Pantelimon”', 'Lic. Tehn. „Sfântul Pantelimon”', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Sf. Dimitrie” Teregova', 'Lth Teregova', 'CS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Sf. Ecaterina” Urziceni', 'Liceul Teh. „Sf. Ecaterina” Urziceni', 'IL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Silvic Cimpeni', 'Lic. Teh. Silvic Cimpeni', 'AB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Silvic „Dr. Nicolae Rucăreanu” Brașov', 'Liceul Silvic Brașov', 'BV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Simion Bărnuțiu” Carei', 'Lteh „Simion Bărnuțiu” Carei', 'SM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Simion Leonescu” Luncavița', 'Liceul „S. Leonescu” Luncavița', 'TL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Simion Mehedinti”, Localitatea Galati', 'Lic. Teh. „S. Mehedinti” Gl', 'GL');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic „Someș” Dej', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Sövér Elek” Joseni', 'Gri „Sover Elek” Joseni', 'HR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Special „Beethoven” Craiova', 'Liceul Special Beethoven Craiova', 'DJ');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic Special Bivolarie', 'SV');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic Special Dej', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Special Drobeta', 'Lic. Teh. Drobeta', 'MH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Special „Gheorghe Atanasiu” Timișoara', 'Lic. Teh. Spec. Gheorghe Atanasiu Timisoara', 'TM');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic Special Gherla', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Special Nr. 3', 'Lic. Tehn. Spec. Nr. 3', 'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic Special Nr. 1 Oradea', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Special Pentru Copii Cu Deficiențe Auditive Municpiul Buzău', 'Lic Def Aud Buzău', 'BZ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Special Pentru Deficienți de Auz Cluj-Napoca',
        'Liceul Tehnologic Special Pentru Def. de Auz Cluj', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Special „Regina Elisabeta”', 'Lic. Tehn. Spec. „Regina Elisabeta”', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Special „Vasile Pavelcu”, Iași', 'Lic Spec „V. Pavelcu” Iasi', 'IS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Special „Pelendava” Craiova', 'Lic. Special „Pelendava” Craiova', 'DJ');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic „Spiru Haret” Târgoviște', 'DB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Stănescu Valerian” Târnava', 'Lic Tehn „Stănescu Valerian” Tirnava', 'SB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Stefan Anghel” Bailesti', 'Liceul Stefan Anghel Bailesti', 'DJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Stefan Cel Mare Si Sfant” Vorona', 'Lic. Tehnologic „Stefan Cel Mare Si Sfant” Vorona',
        'BT');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic „Stefan Hell” Sântana', 'AR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Stefan Manciulea” Blaj', 'Lic. Teh. „St. Manciulea” Blaj', 'AB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Stefan Milcu” Calafat', 'Liceul Stefan Milcu Calafat', 'DJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Stefan Odobleja” Craiova', 'Liceul Stefan Odobleja Craiova', 'DJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Stoina', 'Lic Teh Stoina', 'GJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Székely Károly” Miercurea Ciuc', 'Gri „Szekely Karoly” Miercurea Ciuc', 'HR');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic „Ștefan Cel Mare” Cajvana', 'SV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Tara Motilor” Albac', 'Lic. Teh. Albac', 'AB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Tarna Mare', 'Lteh Tarna Mare', 'SM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Tase Dumitrescu”, Orașul Mizil', 'Liceul Tehnologic „Tase Dumitrescu” Mizil', 'PH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Tășnad', 'Lteh Tășnad', 'SM');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic Târgu Ocna', 'BC');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Târnăveni', 'Lic. Tehn. Târnăveni', 'MS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Telciu', 'Lic Teh Telciu', 'BN');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Teodor Diamant”, Orașul Boldești-Scăeni',
        'Liceul Tehnologic „Teodor Diamant” Boldesti-Scaen', 'PH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Theodor Pallady', 'Lic. Teh. Theodor Pallady', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Ticleni', 'Lic Teh Ticleni', 'GJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Timotei Cipariu” Blaj', 'Lic. Teh. „T. Cipariu” Blaj', 'AB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Tismana', 'Lic Teh Tismana', 'GJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Tiu Dumitrescu” Mihăilești', 'Lic. Tehnologic „Tiu Dumitrescu” Mihailesti', 'GR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Tivai Nagy Imre” Sânmartin', 'Gri „Tivai Nagy Imre” Sânmartin', 'HR');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic Todireni', 'BT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Toma Socolescu”, Municipiul Ploiești', 'Liceul Tehnic „Toma Socolescu” Ploiesti', 'PH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Tomis” Constanța', 'Lic Teh „Tomis” Cța', 'CT');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic „Tomșa Vodă” Solca', 'SV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Topolog', 'Liceul Topolog', 'TL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Topoloveni', 'Lic. Teh. Topoloveni', 'AG');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Topraisar', 'Lic Tehnologic Topraisar', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Traian Grozăvescu” Nădrag', 'Lic. Teh. Tr. Grozavescu Nadrag', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Traian Săvulescu” Municipiul Rîmnicu Sărat', 'Lic. Teh. Săvulescu', 'BZ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Traian Vuia” Tautii-Magheraus', 'Lth T Vuia Tautii-Magheraus', 'MM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Traian Vuia” Tîrgu Mureș', 'Lic. Tehn. „T. Vuia” Tg. Mureș', 'MS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Trandafir Cocârlă” Caransebeș', 'Lth „Trandafir Cocârlă” Caransebeș', 'CS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Transilvania” Baia Mare', 'Lth Transilvania Bm', 'MM');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic „Transilvania” Deva', 'HD');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Transporturi Auto Calarasi', 'Lic. Tehnologic de Transporturi Auto Calarasi', 'CL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Transporturi Auto Timișoara', 'Lic. Teh. Transp. Auto Timisoara', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Transporturi Cai Ferate Craiova', 'Liceul Transporturi Cfr Craiova', 'DJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Tudor Vladimirescu”', 'Lic. Teh. T. Vladimirescu', 'MH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Tudor Vladimirescu”, Comuna Tudor Vladimirescu', 'Lic. Teh. „T. Vladimirescu” T.Vladim.',
        'GL');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic Tufeni', 'OT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Turburea', 'Lic Teh Turburea', 'GJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Turceni', 'Lic Teh Turceni', 'GJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Țăndărei', 'Liceul Teh. Țăndărei', 'IL');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic Ucecom „Spiru Haret” Arad', 'AR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Ucecom „Spiru Haret” Baia Mare', 'Lth Ucecom Spiru Haret Bm', 'MM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Ucecom „Spiru Haret” Breaza', 'Liceul Ucecom „Spiru Haret” Breaza', 'PH');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic Ucecom „Spiru Haret” Cluj-Napoca', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Ucecom „Spiru Haret” Constanța', 'Lic Tehnologic „Spiru Haret” Cța', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Ucecom „Spiru Haret” Craiova', 'Liceul Ucecom', 'DJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Ucecom „Spiru Haret”, Iasi', 'Lic Teh Ucecom Iasi', 'IS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Ucecom „Spiru Haret” Ploiești', 'Liceul Ucecom „Spiru Haret” Ploiesti', 'PH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Ucecom „Spiru Haret” Timișoara', 'Lic. Teh. Ucecom „Spiru Haret” Timisoara', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Udrea Băleanu” Băleni', 'Liceul Tehnologic „Udrea Băleanu” Băleni', 'DB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Unio-Traian Vuia” Satu Mare', 'Lteh „Unio-Traian Vuia” Sm', 'SM');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic „Unirea” Ștei', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Urziceni', 'Liceul Teh. Urziceni', 'IL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Valeriu Braniște” Lugoj', 'Lic. Teh. „V. Braniste” Lugoj', 'TM');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic „Vasile Cocea” Moldovița', 'SV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Vasile Deac” Vatra Dornei', 'Liceul Tehnologic „Vasile Deac” Vatra Dornei', 'SV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Vasile Gherasim” Marginea', 'Liceul Tehnologic „V. Gherasim” Marginea', 'SV');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic „Vasile Juncu” Miniș', 'AR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Vasile Netea” Deda', 'Lic. Tehn. „V. Netea” Deda', 'MS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Vasile Sav”, Municipiul Roman', 'Ltvs, Roman', 'NT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Văleni', 'Liceul Teh. Valeni', 'OT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Vedea', 'Lic. Teh. Vedea', 'AG');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Venczel József” Miercurea Ciuc', 'Gri „Venczel Jozsef” Mierecurea Ciuc', 'HR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Victor Frunză” Municipiul Rîmnicu Sărat', 'Lic. Teh. V. Frunză', 'BZ');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic „Victor Jinga” Săcele', 'BV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Victor Mihăilescu Craiu”, Belcești', 'Lic Teh Belcesti', 'IS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Victor Slăvescu” Rucăr', 'Lic. Teh. Victor Slăvescu Rucăr', 'AG');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic Vinga', 'AR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Vintilă Brătianu” Dragomirești Vale', 'Liceul Tehnolog „Vintila Bratianu” Dragomiresti Val',
        'IF');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic „Virgil Madgearu” Cluj-Napoca', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Virgil Madgearu” Roșiori de Vede', 'Lth „Virgil Madgearu” Roșiori de Vede', 'TR');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic „Virgil Madgearu” Suceava', 'SV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Viseu de Sus', 'Lth Viseu', 'MM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic Vitomirești', 'Liceul Teh. Vitomiresti', 'OT');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic „Vlădeasa” Huedin', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic, Vlădeni', 'Lic Teh Vladeni', 'IS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Voievodul Gelu” Zalău', 'Lic. Tehnologic „V. Gelu” Zalău', 'SJ');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Tehnologic Voinești', 'DB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Zeyk Domokos” Cristuru Secuiesc', 'Gri „Zeyk Domokos” Cristur', 'HR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „Zimmethausen” Borsec', 'Gri „Zimmethausen” Borsec', 'HR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Tehnologic „1 Mai”, Municipiul Ploiești', 'Liceul Tehnologic „1 Mai”, Municipiul Ploiesti', 'PH');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teologic Adventist Craiova', 'DJ');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teologic Adventist „Maranatha” Cluj-Napoca', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teologic Adventist „Ștefan Demetrescu”', 'Lic. Teo. Adv. „Șt. Demetrescu”', 'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teologic Baptist „Alexa Popovici” Arad', 'AR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teologic Baptist „Betania” Sibiu', 'Liceul Betania Sibiu', 'SB');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teologic Baptist „Emanuel” Cluj-Napoca', 'CJ');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teologic Baptist „Emanuel” Oradea', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teologic Baptist „Logos”', 'Lic. Teol. Baptist „Logos”', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teologic Baptist Reșița', 'Lic Teologic Baptist', 'CS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teologic Baptist Timișoara', 'Lic. Teologic Baptist Timisoara', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teologic „Elim” Pitești', 'Lic. Teol. Elim Pitești', 'AG');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teologic „Episcop Melchisedec”, Municipiul Roman', 'L Teol „Episcop Melchisedec”, Roman', 'NT');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teologic „Fericitul Ieremia” Onești', 'BC');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teologic Greco-Catolic „Sfantul Vasile Cel Mare” Blaj', 'Lic. Teologic Blaj', 'AB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teologic Ortodox „Cuvioasa Parascheva”, Comuna Agapia', 'Lic Teol „Cuvioasa Parascheva”, Agapia', 'NT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teologic Ortodox „Nicolae Steinhardt” Satu Mare', 'Licteo „Nicolae Steinhardt”', 'SM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teologic Ortodox „Sf. Constantin Brâncoveanu” Făgăraș', 'Liceul Teologic Ortodox Făgăraș', 'BV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teologic Ortodox „Sfântul Antim Ivireanul” Timișoara',
        'Lic. Teolog. Ort. Sf. Antim Ivireanul Timisoara', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teologic Ortodox „Sfinții Împarați Constantin și Elena”, Municipiul Piatra-Neamț',
        'Lic Teo „Sf. Împ C-Tin și Elena”, Piatra Neamț', 'NT');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teologic Penticostal Arad', 'AR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teologic Penticostal Baia Mare', 'Lteol Penticostal Bm', 'MM');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teologic Penticostal „Betel” Oradea', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teologic Penticostal „Emanuel”', 'Lic. Teo. Penti. „Emanuel”', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teologic Penticostal Logos Timișoara', 'Lic. Teologic Logos Timisoara', 'TM');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teologic Reformat Cluj-Napoca', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teologic Reformat Sfântu Gheorghe', 'Lic. Teol. Ref. Sfântu Gheorghe', 'CV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teologic Reformat Târgu Secuiesc', 'Lic. Teol. Ref. Târgu Secuiesc', 'CV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teologic Romano-Ii. Rákóczi Tîrgu Mureș', 'Lic. Teol. Romano-Catolic Tîrgu Mureș', 'MS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teologic Romano-Catolic „Gerhardinum” Timișoara', 'Lic. Teologic Gerhardinum Timisoara', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teologic Romano-Catolic „Grof Majlath Gusztav Karoly” Alba Iulia', 'Lic. Teol. Rom. Cat. Alba Iulia',
        'AB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teologic Romano-Catolic „Ham Janos” Satu Mare', 'Licteo „Ham Janos” Sm', 'SM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teologic Romano-Catolic „Segitő Mária” Miercurea Ciuc', 'Ste „Segito Maria” Miercurea Ciuc', 'HR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teologic Romano-Catolic „Sfântul Francisc de Assisi”, Municipiul Roman',
        'L Teol „Sfântul Francisc de Assisi”, Roman', 'NT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teologic Romano-Catolic „Szent Erzsébet” Lunca de Sus', 'Ste „Szent Erzsebet” Lunca de Sus', 'HR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teologic Romano-Catolic „Szent Laszlo” Oradea', 'Lic. Teol. Romano-Catolic „Szent Laszlo” Oradea',
        'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teologic Tg-Jiu', 'Lic. Teologic Tg-Jiu', 'GJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teologic Unitarian „Berde Mózes” Cristuru Secuiesc', 'Ste Unitarian Cristur', 'HR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Adam Muller Guttenbrunn” Arad', 'Liceul Teoretic „a.M. Guttenbrunn” Arad', 'AR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Adrian Paunescu” Barca', 'Liceul Teoretic Barca', 'DJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Ady Endre”', 'Lic. Teor. „Ady Endre”', 'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic „Ady Endre” Oradea', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Alexandru Ghica” Alexandria', 'Lte „Al. D. Ghica” Alexandria', 'TR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Alexandru Ioan Cuza”', 'Lic. Teor. „Al. I. Cuza”', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Alexandru Ioan Cuza” Corabia', 'Liceul Teo „Al. I. Cuza” Corabia', 'OT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Alexandru Ioan Cuza”, Iași', 'Lic „Al. I. Cuza” Iasi', 'IS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Alexandru Marghiloman” Municipiul Buzău', 'Lic. Marghiloman', 'BZ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Alexandru Mocioni” Ciacova', 'Lic. Teor. „a. Mocioni” Oras Ciacova', 'TM');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic „Alexandru Papiu Ilarian” Dej', 'CJ');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic „Alexandru Rosetti” Vidra', 'IF');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Alexandru Vlahuță”', 'Lic. Teo. „Alexandru Vlahuță”', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic Amarastii de Jos', 'Liceul Amarastii de Jos', 'DJ');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic „Ana Ipătescu” Gherla', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Anastasie Basota” Pomârla', 'Lic. Teor. „a. Basota” Pomârla', 'BT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Andrei Bârseanu” Târnăveni', 'Lic. Teor. „a. Bârseanu” Târnăveni', 'MS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Anghel Saligny” Cernavodă', 'Lic Teo „Anghel Saligny” Cernavodă', 'CT');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic „Apaczai Csere Janos” Cluj-Napoca', 'CJ');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic „Arany Janos” Salonta', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Atlas”', 'Lic. Teor. „Atlas”', 'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic „Aurel Lazăr” Oradea', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Aurel Vlaicu”, Orașul Breaza', 'Liceul Teoretic „Aurel Vlaicu” Breaza', 'PH');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic „Aurel Vlaicu” Orăștie', 'HD');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic „Avram Iancu” Brad', 'HD');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic „Avram Iancu” Cluj-Napoca', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Axente Sever” Mediaș', 'Lic Teor „a. Sever” Mediaș', 'SB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Bartók Béla” Timișoara', 'Lic. Teor. „Bartók Béla” Timisoara', 'TM');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic „Bathory Istvan” Cluj-Napoca', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic Băneasa', 'Lic Teo Băneasa', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic Bechet', 'Liceul Bechet', 'DJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Benjamin Franklin”', 'Lic. Teor. „Benjamin Franklin”', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic Bilingv „Ita Wegman”', 'Lic. Teor. Bilingv „Ita Wegman”', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic Bilingv „Miguel de Cervantes”', 'Liceul Teor. Bilingv „M. de Cervantes”', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic Bilingv Româno-Croat Carașova', 'Lic Bilingv Romano-Croat Carasova', 'CS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Bocskai Istvan” Miercurea Nirajului', 'Lic. Teor. „Bocskai Istvan” Miercurea Nirajului',
        'MS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Bogdan Voda” Viseu de Sus', 'Lt B Voda Viseu', 'MM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Bogdan Vodă”, Hălăucești', 'Lic Halaucesti', 'IS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Bolyai Farkas” Tîrgu Mureș', 'Lic. Teor. „Bolyai Farkas” Tg. Mureș', 'MS');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic „Brassai Samuel” Cluj-Napoca', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Brâncoveanu Vodă”, Orașul Urlați', 'Liceul Teoretic „Brancoveanu Voda” Urlati', 'PH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic Bulgar „Hristo Botev”', 'Lic. Teo. Bulgar „Hristo Botev”', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic Buziaș', 'Lic. Teor. Buzias', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „C.a. Rosetti”', 'Lic. Teor. „C.a. Rosetti”', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Callatis” Mangalia', 'Lic Teo „Callatis” Mangalia', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic Carei', 'Lit Carei', 'SM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Carmen Sylva” Eforie', 'Lic Teoretic „Carmen Sylva” Eforie', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Carol I” Fetești', 'Liceul Teo. „Carol I” Fetești', 'IL');
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
VALUES ('Liceul Teoretic, Comuna Filipeștii de Pădure', 'Liceul Teoretic Filipesti Padure', 'PH');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic „Constantin Angelescu”', 'BR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Constantin Brancoveanu” Dabuleni', 'Liceul Dabuleni', 'DJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Constantin Brătescu” Isaccea', 'Liceul „C. Brătescu” Isaccea', 'TL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Constantin Brâncoveanu” Bacău', 'Lic. Teo. „C-Tin Brâncoveanu” Bacău', 'BC');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Constantin Noica” Alexandria', 'Lte „Constantin Noica” Alexandria', 'TR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Constantin Noica” Sibiu', 'Lic Teor „C. Noica” Sibiu', 'SB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Constantin Romanu Vivu” Teaca', 'Lic Teo „C.R. Vivu” Teaca', 'BN');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic „Constantin Șerban” Aleșd', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Coriolan Brediceanu” Lugoj', 'Lic. Teo. „C. Brediceanu” Mun. Lugoj', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic Costești', 'Lic. Teor. Costești', 'AG');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic Creștin „Pro Deo” Cluj-Napoca', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „C-Tin Brâncoveanu”', 'Lic. Teo. „C-Tin Brâncoveanu”', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic Cujmir', 'Lic. Teo. Cujmir', 'MH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Dan Barbilian” Câmpulung', 'Lic. Teor. Dan Barbilian Câmpulung', 'AG');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Dante Alighieri”', 'Lic. Teor. „Dante Alighieri”', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „David Prodan” Cugir', 'Lic. Teo. „D.P.” Cugir', 'AB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „David Voniga” Giroc', 'Lic. Teor. „David Voniga” Giroc', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic de Informatică „Grigore Moisil”, Iași', 'Lic „Gr. Moisil” Iasi', 'IS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Decebal”', 'Lic. Teor. „Decebal”', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Decebal” Constanța', 'Lic Teoretic „Decebal” Cța', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Dimitrie Bolintineanu”', 'Lic. Teo. „Dimitrie Bolintineanu”', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Dimitrie Cantemir”, Iași', 'Lic „D. Cantemir” Iasi', 'IS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Dositei Obradovici” Timișoara', 'Lic. Teor. „D. Obradovici” Timisoara', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Dr. I.C. Parhon”, Municipiul Piatra-Neamț', 'Lt „Dr. I.C. Parhon”, Piatra-Neamț', 'NT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Dr. Lind” Câmpenița', 'Lic. Teor. „Dr. Lind” Câmpenița', 'MS');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic „Dr. Mihai Ciuca” Saveni', 'BT');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic „Dr. Mioara Mincu”', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Dr. P. Boros Fortunat” Zetea', 'Lit „Dr. P. Boros Fortunat” Zetea', 'HR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Dr. Victor Gomoiu”', 'Lic. Teo. „Dr. V. Gomoiu”', 'MH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Duiliu Zamfirescu” Odobesti', 'Lic. Teor. „Duiliu Zamfirescu” Odobesti', 'VN');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic „Dumitru Tăuțan” Florești', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Dunarea”, Localitatea Galati', 'Lic. Teo. „Dunarea” Gl', 'GL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Educational Center” Constanța', 'Lic Teoretic „Educational Center” Cța', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Eftimie Murgu” Bozovici', 'Lic Teoretic „Eftimie Murgu” Bozovici', 'CS');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic „Elf” Cluj-Napoca', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Emil Racovita” Baia Mare', 'Lt E Racovita Bm', 'MM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Emil Racovita”, Localitatea Galati', 'Lic. Teo. „E. Racovita” Gl', 'GL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Emil Racoviță”, Mun. Vaslui', 'Lit Emil Racoviță', 'VS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Emil Racoviță” Techirghiol', 'Lic Teoretic Techirghiol', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Eugen Lovinescu”', 'Lic. Teor. „Eugen Lovinescu”', 'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic „Eugen Pora” Cluj-Napoca', 'CJ');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic „Filadelfia” Suceava', 'SV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Gabriel Țepelea” Borod', 'Lit „Gabriel Țepelea” Borod', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic Gătaia', 'Lic. Teor. Gataia', 'TM');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic „Gelu Voievod” Gilău', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „General Dragalina” Oravița', 'Lic Teoretic General Dragalina Oravita', 'CS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Genesis College”', 'Liceul Genesis', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „George Călinescu”', 'Lic. Teo. „G. Călinescu”', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „George Călinescu” Constanța', 'Lic Teoretic „George Călinescu” Cța', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „George Emil Palade” Constanța', 'Lic Teoretic „G E Palade” Cța', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „George Moroianu” Săcele', 'Liceul Teoretic „G. Moroianu” Săcele', 'BV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „George Pop de Basesti” Baia Mare', 'Lt G Pop de Basesti Bm', 'MM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „George Pop de Basesti” Sighetu Marmatiei', 'Lt G Pop de Basesti Sighet', 'MM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „George Pop de Basesti” Targu Lapus', 'Lt G Pop de Basesti Tg Lapus', 'MM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „George Pop de Basesti” Ulmeni', 'Lt G Pop de Basesti Ulmeni', 'MM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „George Pop de Basesti” Viseu de Sus', 'Lt G Pop de Basesti Viseu', 'MM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „George Pop de Băsești” Satu Mare', 'Lic „George Pop de Băsești” Sm', 'SM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „George St. Marincu” Poiana Mare', 'Liceul Poiana Mare', 'DJ');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic „George Vâlsan”', 'BR');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic German „Friedrich Schiller” Oradea', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic German „Johann Ettinger” Satu Mare', 'Ltg „Johann Ettinger” Sm', 'SM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Gh. Vasilichi” Cetate', 'Liceul Gh. Vasilichi Cetate', 'DJ');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic Ghelari', 'HD');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Gheorghe Ionescu Șișești”', 'Lic. Teor. „Gh. Ionescu-Sisesti”', 'MH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Gheorghe Lazăr” Avrig', 'Lic Teor „Gh. Lazăr” Avrig', 'SB');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic „Gheorghe Lazăr” Pecica', 'AR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Gheorghe Marinescu” Tîrgu Mureș', 'Lic. Teor. „G. Marinescu” Tg. Mures', 'MS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Gheorghe Munteanu Murgoci” Măcin', 'Liceul „G.M. Murgoci” Măcin', 'TL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic Gheorghe Surdu, Oras Brezoi', 'Lic Teo Gh. Surdu Brezoi', 'VL');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic „Grigore Antipa” Botosani', 'BT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Grigore Gheba” Dumitresti', 'Lic. Teor. „Grigore Gheba” Dumitresti', 'VN');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Grigore Moisil” Timișoara', 'Lic. Teor. Gr. Moisil Timisoara', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Grigore Moisil” Tulcea', 'Liceul „G. Moisil” Tulcea', 'TL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Grigore Tocilescu”, Orașul Mizil', 'Liceul Teoretic „G. Tocilescu” Mizil', 'PH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Gustav Gundisch” Cisnădie', 'Lic Teor „G. Gundisch” Cisnădie', 'SB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Harul” Lugoj', 'Lic. Teo. „Harul” Lugoj', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Henri Coanda” Craiova', 'Liceul Henri Coanda Craiova', 'DJ');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic „Henri Coandă” Bacău', 'BC');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic „Henri Coandă” Dej', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Henri Coandă” Feldru', 'Lic Teo „H. Coandă” Feldru', 'BN');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic „Henri Coandă” Oradea', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Henri Coandă” Timișoara', 'Lic. Partic. „H. Coanda” Timisoara', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Horea Cloșca și Crișan” Cluj-Napoca', 'Liceul Teoretic „Horea Cloșca și Crișan” Cluj-N',
        'CJ');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic „Horia Hulubei” Măgurele', 'IF');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic „Horvath Janos” Marghita', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Hyperion”', 'Liceul Hyperion', 'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic „I.C. Brătianu” Hațeg', 'HD');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic „Iancu C Vissarion” Titu', 'DB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „I.C. Drăgușanu” Victoria', 'Liceul Teoretic Victoria', 'BV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Independenta” Calafat', 'Liceul Independenta Calafat', 'DJ');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic Internațional București', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic Internațional de Informatică Bucuresti', 'Liceul de Informatică', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic Internațional de Informatică Constanța', 'Lic Teoretic de Informatică Cța', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Ioan Buteanu” Somcuta Mare', 'Lt I Buteanu Somcuta', 'MM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Ioan Cotovu” Hârșova', 'Lic Teoretic „Ioan Cotovu” Hârșova', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Ioan Jebelean” Sânnicolau Mare', 'Lic. Teor. I. Jebelean Sannicolau Mare', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Ioan Pascu” Codlea', 'Liceul Teoretic Codlea', 'BV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Ioan Petruș” Otopeni', 'Liceul Teoretic „Ioan Petrus” Otopeni', 'IF');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Ioan Slavici” Panciu', 'Lic. Teor. „Ioan Slavici” Panciu', 'VN');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Ion Agârbiceanu” Jibou', 'L.T.„I. Agârbiceanu”  Jibou', 'SJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Ion Barbu”', 'Lic. Teo. „Ion Barbu”', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Ion Barbu” Pitești', 'Lic. Teor. Ion Barbu Pitești', 'AG');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Ion Borcea” Buhuși', 'Liceul Teoretic „I. Borcea” Buhusi', 'BC');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Ion Cantacuzino” Pitești', 'Lic. Teor. Ion Cantacuzino Pitești', 'AG');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Ion Creangă” Tulcea', 'Liceul „I. Creangă” Tulcea', 'TL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Ion Gh. Roșca” Osica de Sus', 'Lic. Teor. „I.Gh.  Roșca” Osica de Sus', 'OT');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic „Ion Ghica” Răcari', 'DB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Ion Heliade Rădulescu” Târgoviște', 'Liceul Teoretic „Ion Heliade Rădulescu” Tgv', 'DB');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic „Ion Luca” Vatra Dornei', 'SV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Ion Mihalache” Topoloveni', 'Lic. Teor. Ion Mihalache Topoloveni', 'AG');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Ion Neculce”, Târgu Frumos', 'Lic Teo „I. Neculce” Tg. Frumos', 'IS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Ioniță Asan” Caracal', 'Liceul Teo „Ionita Asan” Caracal', 'OT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Iulia Hașdeu” Lugoj', 'Lic. Teo. „I. Hasdeu” Mun. Lugoj', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Iulia Zamfirescu” Mioveni', 'Lic. Teor. Iulia Zamfirescu Mioveni', 'AG');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Jean Bart” Sulina', 'Liceul „J. Bart” Sulina', 'TL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Jean Louis Calderon” Timișoara', 'Lic. Teor. „J.L. Calderon” Timisoara', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Jean Monnet”', 'Lic. Teo „Jean Monnet”', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Joseph Haltrich” Sighișoara', 'Lic. Teor. „Joseph Haltrich” Sighișoara', 'MS');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic „Josika Miklos” Turda', 'CJ');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic „Jozef Gregor Tajovsky” Nădlac', 'AR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Jozef Kozacek” Budoi', 'Lit „Jozef Kozacek” Budoi', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Kemény János” Toplița', 'Lit „Kemeny Janos” Toplita', 'HR');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic „Kemény Zsigmond” Gherla', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Lascăr Rosetti”, Răducăneni', 'Lic Raducaneni', 'IS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Leowey Klara” Sighetu Marmatiei', 'Lt L Klara Sighet', 'MM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Little London Pipera” Voluntari', 'Liceul Teoretic „Little London Pipera” Voluntar', 'IF');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic „Liviu Rebreanu” Turda', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Lucian Blaga”', 'Lic. Teor. „Lucian Blaga”', 'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic „Lucian Blaga” Cluj-Napoca', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Lucian Blaga” Constanța', 'Lic Teoretic „Lucian Blaga” Cța', 'CT');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic „Lucian Blaga” Oradea', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Marin Coman”, Localitatea Galati', 'Lic. Teo. „M. Coman” Gl', 'GL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Marin Preda”', 'Lic. Teor. „Marin Preda”', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Marin Preda” Turnu Măgurele', 'Lte „Marin Preda” Turnu Măgurele', 'TR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Mark Twain International School” Voluntari',
        'Liceul Teoretic „M. Twain International” Voluntari', 'IF');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Mihai Eminescu” Calarasi', 'Lic. „Mihai Eminescu” Calarasi', 'CL');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic „Mihai Eminescu” Cluj-Napoca', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Mihai Eminescu”, Mun. Bârlad', 'Lit Mihai Eminescu', 'VS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic Mihai Ionescu', 'Liceul Mihai Ionescu', 'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic „Mihai Veliciu” Chisineu-Cris', 'AR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Mihai Viteazul” Bailesti', 'Liceul Mihai Viteazul Bailesti', 'DJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Mihai Viteazul” Caracal', 'Lic. T.„Mihai Viteazul”  Caracal', 'OT');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic „Mihai Viteazul” Vișina', 'DB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Mihail Kogălniceanu” Mihail Kogălniceanu', 'Lic Teoretic Mihail Kogălniceanu', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Mihail Kogălniceanu”, Mun. Vaslui', 'Lit Mihail Kogălniceanu', 'VS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Mihail Kogălniceanu” Snagov', 'Liceul Teoretic „Mihail Kogalniceanu” Snagov', 'IF');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Mihail Sadoveanu”', 'Lic. Teor. „Mihail Sadoveanu”', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Mihail Săulescu” Predeal', 'Liceul Teoretic Predeal', 'BV');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic „Mihail Sebastian”', 'BR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Mikes Kelemen” Sfântu Gheorghe', 'Lic. Teor. „Mikes Kelemen” Sfântu Gheorghe', 'CV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic Millenium Timișoara', 'Lic. Teo. Millenium Timisoara', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Mircea Eliade” Întorsura Buzăului', 'Lic. Teor. „Mircea Eliade” Intorsura Buzaului', 'CV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Mircea Eliade”, Localitatea Galati', 'Lic. Teo. „M. Eliade” Gl', 'GL');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic „Mircea Eliade” Lupeni', 'HD');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Miron Costin”, Iași', 'Lic „M. Costin” Iasi', 'IS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Miron Costin”, Pașcani', 'Lic Teo „M. Costin” Pascani', 'IS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Mitropolit Ioan Mețianu” Zărnești', 'Liceul Teoretic Zărnești', 'BV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic Murfatlar', 'Lic Teoretic Murfatlar', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Nagy Mózes” Târgu Secuiesc', 'Lic. Teor. „Nagy Mózes” Târgu Secuiesc', 'CV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic National', 'Liceul National', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic Negrești Oaș', 'Ltn Negrești Oaș', 'SM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic Negru Vodă', 'Lic Teoretic Negru Vodă', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Nemeth Laszlo” Baia Mare', 'Lt N Laszlo Bm', 'MM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „New Generation School”', 'Liceul New Generation School', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Nichita Stănescu”', 'Lic. Teor. „Nichita Stănescu”', 'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic „Nicolae Bălcescu” Cluj-Napoca', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Nicolae Bălcescu” Medgidia', 'Lic Teoretic „Nicolae Bălcescu” Medgidia', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Nicolae Cartojan” Giurgiu', 'Lic. Teoretic „Nicolae Cartojan”', 'GR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Nicolae Iorga”', 'Lic. Teo. „Nicolae Iorga”', 'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic „Nicolae Iorga”', 'BR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Nicolae Iorga”, Mun. Bârlad', 'Lit N. Iorga Bârlad', 'VS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Nicolae Iorga” Oraș Nehoiu', 'Lic Teo Nehoiu', 'BZ');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic „Nicolae Jiga” Tinca', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Nicolae Titulescu” Slatina', 'Liceul Teo „N. Titulescu” Slatina', 'OT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Nikolaus Lenau” Timișoara', 'Lic. Teor. Nikolaus Lenau Timisoara', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic Novaci', 'Lic. Teoretic Novaci', 'GJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic Nr. 1 Periș', 'Liceul Teoretic Nr. 1 Peris', 'IF');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic Nr. 1 Bratca', 'Lit Nr. 1 Bratca', 'BH');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic „Octavian Goga” Huedin', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „O.C. Tăslăuanu” Toplița', 'Lit „O.C. Taslauanu” Toplita', 'HR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic Olteni', 'Lte Olteni', 'TR');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic „Onisifor Ghibu” Cluj-Napoca', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Onisifor Ghibu” Sibiu', 'Lic Teor „Onisifor Ghibu” Sibiu', 'SB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic Oraș Pogoanele', 'Lic. Pogoanele', 'BZ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic, Orașul Azuga', 'Liceul Teoretic Azuga', 'PH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Orbán Balázs” Cristuru Secuiesc', 'Lit „Orban Balazs” Cristur', 'HR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Ovidius” Constanța', 'Lic Teoretic „Ovidius” Cța', 'CT');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic „Panait Cerna”', 'BR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Paul Georgescu” Țăndărei', 'Liceul Teo. „Paul Georgescu” Țăndărei', 'IL');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic „Pavel Dan” Câmpia Turzii', 'CJ');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic Pâncota', 'AR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic Peciu Nou', 'Lic. Teor. Peciu Nou', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic Periam', 'Lic. Teor. Periam', 'TM');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic „Petofi Sandor” Săcueni', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Petre Pandrea” Balș', 'Liceul Teor. „P. Pandrea” Bals', 'OT');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic „Petru Cercel” Târgoviște', 'DB');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic „Petru Maior” Gherla', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Petru Maior” Ocna Mures', 'Lit „P. Maior” Ocna Mures', 'AB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Petru Rares” Targu Lapus', 'Lt P Rares Tg Lapus', 'MM');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic „Phoenix”', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic Piatra', 'Lte Piatra', 'TR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Pontus Euxinus” Lumina', 'Lic Teoretic „Pontus Euxinus” Lumina', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Radu Petrescu” Prundu Bârgăului', 'Lic Teo „R. Petrescu” Prundu Bârg.', 'BN');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Radu Popescu” Popești Leordeni', 'Liceul Teoretic „Radu Popescu” Popesti Leordeni', 'IF');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Radu Vlădescu” Oraș Pătârlagele', 'Lic. „R. Vlădescu” Pătârlagele', 'BZ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic Recaș', 'Lic. Teor. Recaș', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Salamon Ernő” Gheorgheni', 'Lit „Salamon Erno” Gheorgheni', 'HR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Samuil Micu” Sărmașu', 'Lic. Teor. „S. Micu” Sărmașu', 'MS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic Sanitar Bistrița', 'Lic Teo Sanit Bistrita', 'BN');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic Scoala Europeana Bucuresti', 'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic „Scoala Mea”', 'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic Sebiș', 'AR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Sfanta Maria”, Localitatea Galati', 'Lic. Teo. „Sf. Maria” Gl', 'GL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Sfantul Iosif” Alba Iulia', 'Lic. Teo. „Sf. Iosif” Alba Iulia', 'AB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Sfântu Nicolae” Gheorgheni', 'Lit „Sfantu Nicolae” Gheorgheni', 'HR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Sfinții Kiril și Metodii” Dudeștii Vechi', 'Lic. Teor. Dudestii Vechi', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Sfinții Trei Ierarhi”', 'Liceul „Sfinții Trei Ierarhi”', 'B');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic „Silviu Dragomir” Ilia', 'HD');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic Socrates Timișoara', 'Lic. Teor. Socrates Timisoara', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Solomon Haliță” Sângeorz-Băi', 'Lic Teo „S. Hailță” Sângeorz-Băi', 'BN');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic Special Iris Timișoara', 'Lic. Teor. Spec. Iris Timisoara', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Spiru Haret” Moinești', 'Liceul „S. Haret” Moinești', 'BC');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Stephan Ludwig Roth” Mediaș', 'Lic Teor „St. L. Roth” Mediaș', 'SB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Șerban Cioculescu”', 'Lic Teo. Serban Cioculescu', 'MH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Șerban Vodă”, Orașul Slănic', 'Liceul Teoretic „Serban Voda” Slanic', 'PH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Ștefan Cel Mare” Municipiul Râmnicu Sărat', 'Lic. Ștefan', 'BZ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Ștefan Odobleja”', 'Lic. Teo. „Ștefan Odobleja”', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Tamási Áron” Odorheiu Secuiesc', 'Lit „Tamasi Aron” Odorhei', 'HR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Tata Oancea” Bocșa', 'Lic Teoretic „Tata Oancea” Bocșa', 'CS');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic „Teglas Gabor” Deva', 'HD');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic Teius', 'AB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Traian”', 'Lic. Teor. „Traian”', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Traian” Constanța', 'Lic Teoretic „Traian” Cța', 'CT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Traian Lalescu”', 'Lic. Teoretic „Tr. Lalescu”', 'MH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Traian Lalescu” Brănești', 'Liceul Teoretic „Traian Lalescu” Branesti', 'IF');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Traian Lalescu” Hunedoara', 'Liceul Teoretic „T. Lalescu” Hunedoara', 'HD');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Traian Vuia” Făget', 'Lic. Teor. „Traian Vuia” Faget', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Traian Vuia” Reșița', 'Lic Teoretic „Traian Vuia” Reșița', 'CS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Tudor Arghezi” Craiova', 'Liceul Tudor Arghezi Craiova', 'DJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Tudor Vianu” Giurgiu', 'Lic. Teoretic „Tudor Vianu”', 'GR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Tudor Vladimirescu”', 'Lic. Teor. „Tudor Vladimirescu”', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Tudor Vladimirescu” Drăgănești-Olt', 'Lic. T.„T. Vladimirescu”  Draganesti', 'OT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Varlaam Mitropolitul”, Iași', 'Lic Varlaam Iasi', 'IS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Vasile Alecsandri”, Comuna Săbăoani', 'L Teoretic „Vasile Alecsandri”, Săbăoani', 'NT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Vasile Alecsandri”, Iași', 'Lic „V. Alecsandri” Iasi', 'IS');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic „Victor Babeș” Cluj-Napoca', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Victoria”', 'Liceul „Victoria”', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic Videle', 'Lte Videle', 'TR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic Virgil Ierunca, Com. Ladesti', 'Lic Teo Ladesti', 'VL');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „Vlad Țepeș” Timișoara', 'Lic. Teor. V. Tepes Timisoara', 'TM');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic Waldorf', 'Lic. Teor. Waldorf', 'B');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic Waldorf, Iași', 'Lic Waldorf Iasi', 'IS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic „William Shakespeare” Timișoara', 'Lic. Teor. „W. Shakespeare” Timisoara', 'TM');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Teoretic „Zajzoni Rab Istvan” Săcele', 'BV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Teoretic Zimnicea', 'Lte Zimnicea', 'TR');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul „Timotei Cipariu” Dumbrăveni', 'Lic „T. Cipariu” Dumbrăveni', 'SB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul „Traian Vuia” Craiova', 'Liceul Traian Vuia Craiova', 'DJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul „Udriște Năsturel” Hotarele', 'Lic. „Udriște Năsturel” Hotarele', 'GR');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Unitarian „Janos Zsigmond” Cluj-Napoca', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul „Vasile Conta”, Oraș Târgu Neamț', 'Ltvc, Târgu Neamț', 'NT');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Vocațional de Artă Tîrgu Mureș', 'Lic. Voc. de Artă Tg. Mureș', 'MS');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Vocațional de Arte Plastice „Hans Mattis-Teutsch” Brașov', 'Liceul de Arte Plastice Brașov', 'BV');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Vocațional de Muzică „Tudor Ciortea” Brașov', 'Liceul de Muzică Brașov', 'BV');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Vocațional Pedagogic „Nicolae Bolcaș” Beiuș', 'BH');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Vocațional Reformat Tîrgu Mureș', 'Lic. Voc. Reformat Tg. Mureș', 'MS');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul „Voievodul Mircea” Târgoviște', 'DB');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul „Voltaire” Craiova', 'Liceul Voltaire', 'DJ');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul Waldorf Cluj-Napoca', 'CJ');
INSERT INTO "schools" ("name", "short_name", "county_id")
VALUES ('Liceul Waldorf Timișoara', 'Lic. Waldorf Timisoara', 'TM');
INSERT INTO "schools" ("name", "county_id")
VALUES ('Liceul „Stefan D. Luchian” Stefanesti', 'BT');
INSERT INTO "authors" ("id", "first_name", "last_name")
VALUES (1, 'Mihai', 'Eminescu');
INSERT INTO "authors" ("id", "first_name", "last_name")
VALUES (2, 'Ion', 'Creangă');
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
VALUES (12, 'George', 'Călinescu');
INSERT INTO "authors" ("id", "first_name", "last_name")
VALUES (13, 'Marin', 'Preda');
INSERT INTO "authors" ("id", "first_name", "last_name")
VALUES (14, 'Nichita', 'Stănescu');
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
VALUES (20, 'George', 'Coșbuc');
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
VALUES (1, 1, 'Luceafărul');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (2, 1, 'Sărmanul Dionis');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (3, 1, 'Floare albastră');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (4, 1, 'Scrisoarea I');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (5, 1, 'Odă');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (6, 1, 'Glossă');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (7, 2, 'Povestea lui Harap-Alb');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (8, 3, 'O scrisoare pierdută');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (9, 3, 'La hanul lui Mânjoală');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (10, 4, 'Moara cu noroc');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (11, 4, 'Mara');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (12, 5, 'Plumb');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (13, 5, 'Lacustră');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (14, 5, 'Sonet');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (15, 6, 'Eu nu strivesc corola de minuni a lumii');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (16, 6, 'Dați-mi un trup, voi munților');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (17, 6, 'Izvorul nopții');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (18, 6, 'Meșterul Manole');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (19, 7, 'Flori de mucigai');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (20, 7, 'Testament');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (21, 7, 'Psalmul III - Tare sunt singur, Doamne, și pieziș!...');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (22, 7, 'Psalmul VI - Te drămuiesc în zgomot și-n tăcere...');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (23, 8, 'Riga Crypto și lapona Enigel');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (24, 8, 'Joc secund');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (25, 9, 'Baltagul');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (26, 9, 'Hanul Ancuței');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (27, 9, 'Creanga de aur');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (28, 10, 'Ion');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (29, 10, 'Pădurea spânzuraților');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (30, 11, 'Ultima noapte de dragoste, întâia noapte de război');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (31, 11, 'Patul lui Procust');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (32, 11, 'Jocul ielelor');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (33, 11, 'Suflete tari');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (34, 11, 'Act venețian');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (35, 12, 'Enigma Otiliei');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (36, 12, 'Beitul Ioanide');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (37, 13, 'Moromeții');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (38, 13, 'Cel mai iubit dintre pământeni');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (39, 14, 'Leoaică tânără, iubirea');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (40, 14, 'Cântec');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (41, 14, 'În dulcele stil clasic');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (42, 14, 'Către Galateea');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (43, 15, 'Iona');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (44, 16, 'Maitreyi');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (45, 16, 'Nuntă în cer');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (46, 16, 'La țigănci');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (47, 17, 'Alexandru Lăpușneanu');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (48, 18, 'Umbra lui Mircea la Cozia');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (49, 19, 'Malul Siretului');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (50, 20, 'Moartea lui Fulger');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (51, 21, 'Rugăciune');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (52, 21, 'De demult');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (53, 22, 'Ora fântânilor');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (54, 23, 'Aci sosi de vremuri');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (55, 24, 'În grădina Ghetsemani');
INSERT INTO "titles" ("id", "author_id", "name")
VALUES (56, 25, 'Zmeura de câmpie');
INSERT INTO "characters" ("id", "title_id", "name")
VALUES (1, 8, 'Ștefan Tipătescu');
INSERT INTO "characters" ("id", "title_id", "name")
VALUES (2, 8, 'Zoe Trahanache');
INSERT INTO "characters" ("id", "title_id", "name")
VALUES (3, 8, 'Farfuridi');
INSERT INTO "characters" ("id", "title_id", "name")
VALUES (4, 8, 'Ghită Pristanda');
INSERT INTO "characters" ("id", "title_id", "name")
VALUES (5, 8, 'Nae Cațavencu');
INSERT INTO "characters" ("id", "title_id", "name")
VALUES (6, 8, 'Agamemnon Dandanache');
INSERT INTO "characters" ("id", "title_id", "name")
VALUES (7, 10, 'Ghiță');
INSERT INTO "characters" ("id", "title_id", "name")
VALUES (8, 10, 'Lică Sămădăul');
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
VALUES (17, 30, 'Ștefan Gheorghidiu');
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
