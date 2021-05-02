SET check_function_bodies = false;
INSERT INTO public.works (id, user_id, teacher_id, status, content, created_at, updated_at) VALUES (1, 1, NULL, 'approved', 'Lorem ipsum dolor sit, amet consectetur adipisicing elit. Ab, molestias exercitationem. Qui molestias maiores consequuntur itaque rem, ipsum quaerat neque ut placeat. Ea recusandae mollitia distinctio ab necessitatibus, quisquam corporis.', '2021-05-02 16:54:30.894476', NULL);
INSERT INTO public.works (id, user_id, teacher_id, status, content, created_at, updated_at) VALUES (2, 2, NULL, 'approved', 'Fugiat illum quo quasi magni eveniet praesentium sit aliquid ad dolor velit tempore exercitationem autem dolore ducimus quis, fuga, eos ratione nam pariatur sunt? Iusto pariatur illo harum fugit dolorum?', '2021-05-02 16:54:30.894476', NULL);
INSERT INTO public.essays (work_id, title_id) VALUES (1, 1);
INSERT INTO public.essays (work_id, title_id) VALUES (2, 1);
SELECT pg_catalog.setval('public.works_id_seq', 2, true);
