SET search_path TO public;

DROP INDEX idx_characters_title;
DROP INDEX idx_teacher_student_associations_initiator;
DROP INDEX idx_teacher_student_associations_status;
DROP INDEX idx_teacher_student_associations_student;
DROP INDEX idx_teacher_student_associations_teacher;
DROP INDEX idx_titles_author;
DROP INDEX idx_users_school;
DROP INDEX idx_works_status;
DROP INDEX idx_works_teacher;
DROP INDEX idx_works_user;

ALTER TABLE "students" DROP CONSTRAINT "fk_user_student";
ALTER TABLE "teachers" DROP CONSTRAINT "fk_user_teacher";
ALTER TABLE "works" DROP CONSTRAINT "fk_user_works";
ALTER TABLE "bookmarks" DROP CONSTRAINT "fk_user_bookmarks";
ALTER TABLE "teacher_requests" DROP CONSTRAINT "fk_user_teacher_request";
ALTER TABLE "teacher_student_associations" DROP CONSTRAINT "fk_user_teacher_student_associations";
ALTER TABLE "teacher_student_associations" DROP CONSTRAINT "fk_student_teacher_student_associations";
ALTER TABLE "works" DROP CONSTRAINT "fk_teacher_works";
ALTER TABLE "teacher_student_associations" DROP CONSTRAINT "fk_teacher_teacher_student_associations";
ALTER TABLE "essays" DROP CONSTRAINT "fk_work_essay";
ALTER TABLE "characterizations" DROP CONSTRAINT "fk_work_characterization";
ALTER TABLE "bookmarks" DROP CONSTRAINT "fk_work_bookmarks";
ALTER TABLE "characterizations" DROP CONSTRAINT "fk_character_characterizations";
ALTER TABLE "essays" DROP CONSTRAINT "fk_title_essays";
ALTER TABLE "characters" DROP CONSTRAINT "fk_title_character";
ALTER TABLE "titles" DROP CONSTRAINT "fk_author_title";
ALTER TABLE "users_all" DROP CONSTRAINT "school_user";
ALTER TABLE "schools" DROP CONSTRAINT "county_school";

DROP TABLE counties;
DROP TABLE schools;
DROP TABLE authors;
DROP TABLE titles;
DROP TABLE characters;

DROP TRIGGER check_characterization ON characterizations;
DROP FUNCTION trigger_insert_characterization;
DROP TABLE characterizations;

DROP TRIGGER check_essay ON essays;
DROP FUNCTION trigger_insert_essay;
DROP TABLE essays;

DROP TRIGGER update_works_status ON works;
DROP TABLE works;

DROP TABLE teacher_student_associations;

DROP TRIGGER teacher_requests_after_status_update ON teacher_requests;
DROP TABLE teacher_requests;

DROP TRIGGER check_teacher ON teachers;
DROP FUNCTION trigger_insert_teacher;
DROP TABLE teachers;

DROP TRIGGER check_student ON students;
DROP FUNCTION trigger_insert_student;
DROP TABLE students;

DROP TABLE bookmarks;

DROP VIEW users;
DROP TRIGGER delete_users ON users_all;
DROP FUNCTION trigger_delete_user;
DROP TABLE users_all;

DROP FUNCTION trigger_set_updated_at;
