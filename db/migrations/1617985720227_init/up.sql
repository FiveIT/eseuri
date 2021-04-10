SET search_path TO public;

CREATE FUNCTION trigger_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = localtimestamp;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TABLE users_all (
  "id" SERIAL PRIMARY KEY,
  "first_name" text,
  "middle_name" text,
  "last_name" text,
  "school_id" int,
  "created_at" timestamp DEFAULT (localtimestamp),
  "deleted_at" timestamp,
  "auth0_id" text NOT NULL UNIQUE
);

CREATE FUNCTION trigger_delete_user()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE users_all
    SET first_name = null,
        middle_name = null,
        last_name = null,
        school_id = null,
        created_at = null,
        deleted_at = localtimestamp
    WHERE id = old.id;
    RETURN null;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER delete_users
    BEFORE DELETE on users_all
    FOR EACH ROW
    EXECUTE FUNCTION trigger_delete_user();

CREATE VIEW users AS
SELECT id, first_name, middle_name, last_name, school_id, created_at, auth0_id FROM users_all
WHERE deleted_at IS NOT NULL;

CREATE TABLE bookmarks (
  "user_id" int NOT NULL,
  "work_id" int NOT NULL,
  PRIMARY KEY ("user_id", "work_id")
);

CREATE TABLE students (
  "user_id" int PRIMARY KEY
);

CREATE FUNCTION trigger_insert_student()
RETURNS TRIGGER AS $$
BEGIN
    IF exists(SELECT 1 FROM teachers WHERE user_id = new.user_id) THEN
        RAISE EXCEPTION 'User is already a teacher!';
    END IF;
    RETURN new;
END
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_student
    BEFORE INSERT ON students
    FOR EACH ROW
    EXECUTE FUNCTION trigger_insert_student();

CREATE TABLE "teachers" (
  "user_id" int PRIMARY KEY,
  "about" text,
  "image_url" text
);

CREATE FUNCTION trigger_insert_teacher()
RETURNS TRIGGER AS $$
BEGIN
    IF exists(SELECT 1 FROM students WHERE user_id = new.user_id) THEN
        RAISE EXCEPTION 'User is already a student!';
    END IF;
    RETURN new;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_teacher
    BEFORE INSERT ON teachers
    FOR EACH ROW
    EXECUTE FUNCTION trigger_insert_teacher();

CREATE TABLE "teacher_requests" (
  "user_id" int PRIMARY KEY,
  "status" int NOT NULL DEFAULT 0,
  "created_at" timestamp NOT NULL DEFAULT (localtimestamp),
  "updated_at" timestamp
);

CREATE TRIGGER teacher_requests_after_status_update
    AFTER UPDATE ON teacher_requests
    FOR EACH ROW
    WHEN (OLD.status IS DISTINCT FROM NEW.status)
    EXECUTE FUNCTION trigger_set_updated_at();

CREATE TABLE teacher_student_associations (
  "teacher_id" int NOT NULL,
  "student_id" int NOT NULL,
  "initiator_id" int NOT NULL,
  "status" int NOT NULL DEFAULT 0,
  PRIMARY KEY ("student_id", "teacher_id")
);

CREATE TABLE works (
  "id" SERIAL PRIMARY KEY,
  "user_id" int NOT NULL,
  "teacher_id" int,
  "status" int NOT NULL DEFAULT 0,
  "content" text NOT NULL,
  "content_hash" text NOT NULL UNIQUE GENERATED ALWAYS AS (md5(content)) STORED,
  "created_at" timestamp NOT NULL DEFAULT (localtimestamp),
  "updated_at" timestamp
);

CREATE TRIGGER update_works_status
    BEFORE UPDATE ON works
    FOR EACH ROW
    WHEN (old.status IS DISTINCT FROM new.status)
    EXECUTE FUNCTION trigger_set_updated_at();

CREATE TABLE essays (
  "work_id" int PRIMARY KEY,
  "title_id" int NOT NULL
);

CREATE FUNCTION trigger_insert_essay()
RETURNS TRIGGER AS $$
BEGIN
    IF exists(SELECT 1 FROM characterizations WHERE work_id = new.work_id) THEN
        RAISE EXCEPTION 'Work is already a characterization!';
    END IF;
    RETURN new;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_essay
    BEFORE INSERT on essays
    FOR EACH ROW
    EXECUTE FUNCTION trigger_insert_essay();

CREATE TABLE "characterizations" (
  "work_id" int PRIMARY KEY,
  "character_id" int NOT NULL
);

CREATE FUNCTION trigger_insert_characterization()
RETURNS TRIGGER AS $$
BEGIN
    IF exists(SELECT 1 FROM essays WHERE work_id = new.work_id) THEN
        RAISE EXCEPTION 'Work is already an essay!';
    END IF;
    RETURN new;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_characterization
    BEFORE INSERT on essays
    FOR EACH ROW
    EXECUTE FUNCTION trigger_insert_characterization();

CREATE TABLE "characters" (
  "id" SERIAL PRIMARY KEY,
  "name" text NOT NULL,
  "title_id" int NOT NULL
);

CREATE TABLE "titles" (
  "id" SERIAL PRIMARY KEY,
  "name" text NOT NULL,
  "author_id" int NOT NULL
);

CREATE TABLE "authors" (
  "id" SERIAL PRIMARY KEY,
  "first_name" text DEFAULT null,
  "middle_name" text DEFAULT null,
  "last_name" text NOT NULL
);

CREATE TABLE "schools" (
  "id" SERIAL PRIMARY KEY,
  "name" text NOT NULL,
  "short_name" text,
  "county_id" varchar(2) NOT NULL
);

CREATE TABLE "counties" (
  "id" varchar(2) PRIMARY KEY,
  "name" text NOT NULL
);

ALTER TABLE "students" ADD CONSTRAINT "fk_user_student" FOREIGN KEY ("user_id") REFERENCES "users_all" ("id") ON DELETE CASCADE;

ALTER TABLE "teachers" ADD CONSTRAINT "fk_user_teacher" FOREIGN KEY ("user_id") REFERENCES "users_all" ("id") ON DELETE CASCADE;

ALTER TABLE "works" ADD CONSTRAINT "fk_user_works" FOREIGN KEY ("user_id") REFERENCES "users_all" ("id") ON DELETE NO ACTION;

ALTER TABLE "bookmarks" ADD CONSTRAINT "fk_user_bookmarks" FOREIGN KEY ("user_id") REFERENCES "users_all" ("id") ON DELETE CASCADE;

ALTER TABLE "teacher_requests" ADD CONSTRAINT "fk_user_teacher_request" FOREIGN KEY ("user_id") REFERENCES "users_all" ("id") ON DELETE CASCADE;

ALTER TABLE "teacher_student_associations" ADD CONSTRAINT "fk_user_teacher_student_associations" FOREIGN KEY ("initiator_id") REFERENCES "users_all" ("id") ON DELETE CASCADE;

ALTER TABLE "teacher_student_associations" ADD CONSTRAINT "fk_student_teacher_student_associations" FOREIGN KEY ("student_id") REFERENCES "students" ("user_id") ON DELETE CASCADE;

ALTER TABLE "works" ADD CONSTRAINT "fk_teacher_works" FOREIGN KEY ("teacher_id") REFERENCES "teachers" ("user_id") ON DELETE SET NULL;

ALTER TABLE "teacher_student_associations" ADD CONSTRAINT "fk_teacher_teacher_student_associations" FOREIGN KEY ("teacher_id") REFERENCES "teachers" ("user_id") ON DELETE CASCADE;

ALTER TABLE "essays" ADD CONSTRAINT "fk_work_essay" FOREIGN KEY ("work_id") REFERENCES "works" ("id") ON DELETE RESTRICT;

ALTER TABLE "characterizations" ADD CONSTRAINT "fk_work_characterization" FOREIGN KEY ("work_id") REFERENCES "works" ("id") ON DELETE RESTRICT;

ALTER TABLE "bookmarks" ADD CONSTRAINT "fk_work_bookmarks" FOREIGN KEY ("work_id") REFERENCES "works" ("id") ON DELETE CASCADE;

ALTER TABLE "characterizations" ADD CONSTRAINT "fk_character_characterizations" FOREIGN KEY ("character_id") REFERENCES "characters" ("id") ON DELETE RESTRICT;

ALTER TABLE "essays" ADD CONSTRAINT "fk_title_essays" FOREIGN KEY ("title_id") REFERENCES "titles" ("id") ON DELETE RESTRICT;

ALTER TABLE "characters" ADD CONSTRAINT "fk_title_character" FOREIGN KEY ("title_id") REFERENCES "titles" ("id") ON DELETE CASCADE;

ALTER TABLE "titles" ADD CONSTRAINT "fk_author_title" FOREIGN KEY ("author_id") REFERENCES "authors" ("id") ON DELETE CASCADE;

ALTER TABLE "users_all" ADD CONSTRAINT "school_user" FOREIGN KEY ("school_id") REFERENCES "schools" ("id") ON DELETE RESTRICT;

ALTER TABLE "schools" ADD CONSTRAINT "county_school" FOREIGN KEY ("county_id") REFERENCES "counties" ("id") ON DELETE RESTRICT;

CREATE INDEX idx_users_school ON "users_all" ("school_id");

CREATE INDEX idx_teacher_student_associations_initiator ON "teacher_student_associations" ("initiator_id");

CREATE INDEX idx_teacher_student_associations_student ON "teacher_student_associations" ("student_id");

CREATE INDEX idx_teacher_student_associations_teacher ON "teacher_student_associations" ("teacher_id");

CREATE INDEX idx_teacher_student_associations_status ON "teacher_student_associations" ("status");

CREATE INDEX idx_works_user ON "works" ("user_id");

CREATE INDEX idx_works_teacher ON "works" ("teacher_id");

CREATE INDEX idx_works_status ON "works" ("status");

CREATE INDEX idx_characters_title ON "characters" ("title_id");

CREATE INDEX idx_titles_author ON "titles" ("author_id");

COMMENT ON COLUMN "teacher_requests"."status" IS '0: Pending
1: Approved
2: Rejected';

COMMENT ON COLUMN "teacher_student_associations"."status" IS '0: Pending
1: Accepted
2: Denied';

COMMENT ON COLUMN "works"."status" IS '0: Draft
1: Pending review
2: In review
3: Approved
4: Rejected';

COMMENT ON COLUMN "works"."content_hash" IS 'Set by the database, do not assign this column!';
