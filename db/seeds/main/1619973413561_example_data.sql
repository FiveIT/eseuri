set search_path to public;

insert into users_all (id, first_name, middle_name, last_name, email, school_id, created_at, updated_at, deleted_at, auth0_id) values (1, 'Teodor', null, 'Maxim', 'tmaxmax@outlook.com', 237, '2021-05-02 07:48:42.029262', '2021-05-02 07:49:09.010976', null, 'auth0|60773e729177c7006a44790a');
insert into students (user_id) values (1);

insert into users_all (id, first_name, middle_name, last_name, email, school_id, created_at, updated_at, deleted_at, auth0_id) values (2, 'Laurean', null, 'Chilințan', 'lau@outlook.com', 537, '2021-05-02 07:48:42.029262', '2021-05-02 07:49:09.010976', null, 'auth0|60773f729177c7006a44790a');
insert into teachers (user_id) values (2);

select pg_catalog.setval('public.users_all_id_seq', 2, true);
