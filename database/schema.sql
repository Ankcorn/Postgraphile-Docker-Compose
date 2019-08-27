create schema app;

create table app.user (
  id               serial primary key,
  first_name       text not null check (char_length(first_name) < 80),
  about            text,
  created_at       timestamp default now()
);

create schema app_private;

create table app_private.account (
  user_id         integer primary key references app.user(id) on delete cascade,
  email           text not null unique check (email ~* '^.+@.+\..+$'),
  password_hash   text not null
);

create extension if not exists "pgcrypto";

create type app.jwt_token as (
  role text,
  user_id integer
);

create function app.register_user (
    first_name text,
    email text,
    password text
) returns app.user as $$
declare
  person app.user;
begin
  insert into app.user (first_name, created_at) values
    (first_name, now())
    returning * into person;

  insert into app_private.account (user_id, email, password_hash) values 
    (person.id, email, crypt(password, gen_salt('bf')));

  return person;
end;
$$ language plpgsql strict security definer;

create function app.authenticate(
  email text,
  password text
) returns app.jwt_token as $$
  select('app_user', user_id)::app.jwt_token
    from app_private.account
    where
      account.email = $1
      and account.password_hash = crypt($2, account.password_hash);
$$ language sql strict security definer;

create role app_user login password 'xyz';

create role app_anonymous;
grant app_anonymous to app_user;

create role app_person;
grant app_person to app_user;

grant usage on schema app to app_anonymous, app_person;

grant select on table app.user to app_anonymous;
grant select, update, delete on table app.user to app_person;

grant execute on function app.register_user(text, text, text) to app_anonymous;

grant execute on function app.authenticate(text, text) to app_anonymous, app_person;

alter table app.user enable row level security;

create policy select_person on app.user for select
  using (true);

create policy update_person on app.user for update to app_person
  using (id = current_setting('jwt.claims.user_id', true)::integer);

create policy delete_person on app.user for delete to app_person
  using (id = current_setting('jwt.claims.user_id', true)::integer);


create table app.group (
    id serial primary key,
    title text not null,
    description text not null,
    owner integer not null references app.user(id)
);

grant select on table app.group to app_anonymous;
grant insert, select, update, delete on table app.group to app_person;

create policy create_group on app.group for insert to app_person
  with check (true);

create policy select_group on app.group for select to app_person
  using (true);

create policy update_group on app.group for update to app_person
  using (owner = current_setting('jwt.claims.user_id', true)::integer);

create policy delete_group on app.group for delete to app_person
  using (id = current_setting('jwt.claims.user_id', true)::integer);

/** 
  Todo: Permissions and functions for events + organisers
*/
CREATE TABLE app.event (
	id serial PRIMARY KEY,
	title text NOT NULL,
	description text NOT NULL,
	LOCATION text NOT NULL,
	image text NOT NULL,
	date timestamp DEFAULT now(),
	meetup integer NOT NULL REFERENCES app.group (id)
);

grant select on table app.event to app_anonymous;
grant insert, select, update, delete on table app.event to app_person;

CREATE TABLE app.organiser (
	id serial PRIMARY KEY,
	organiser integer NOT NULL REFERENCES app.user(id),
	meetup integer NOT NULL REFERENCES app.group (id)
);

grant select on table app.organiser to app_anonymous;
grant insert, select, update, delete on table app.organiser to app_person;

CREATE TABLE app.comment (
	id serial PRIMARY KEY,
	message text NOT NULL,
	likes integer DEFAULT 0,
	person integer NOT NULL REFERENCES app.user(id),
	event integer NOT NULL REFERENCES app.event (id),
	parent integer NOT NULL REFERENCES app.comment (id)
);

grant select on table app.comment to app_anonymous;
grant insert, select, update, delete on table app.comment to app_person;

create policy create_comment on app.comment for insert to app_person
   with check (true);

create policy select_comment on app.comment for select to app_person
  using (true);
  
create policy update_comment on app.comment for update to app_person
  using (person = current_setting('jwt.claims.user_id', true)::integer);

create policy delete_comment on app.comment for delete to app_person
  using (person = current_setting('jwt.claims.user_id', true)::integer);

create type app.status as enum (
  'Attending',
  'Not Going',
  'Waitlist'
);

CREATE TABLE app.attending (
  id serial PRIMARY KEY,
  status app.status,
  person integer NOT NULL REFERENCES app.user(id),
  event integer NOT NULL REFERENCES app.event(id)
);

grant select on table app.attending to app_anonymous;
grant insert, select, update, delete on table app.attending to app_person;

GRANT USAGE, SELECT ON SEQUENCE app.group_id_seq TO app_anonymous, app_user;
GRANT USAGE, SELECT ON SEQUENCE app.organiser_id_seq TO app_anonymous, app_user;

-- INSERT INTO app.user (id, first_name, about, created_at) VALUES ('1', 'Thomas', NULL, '2019-08-27 21:31:17.745455'),
-- ('2', 'Not Thomas', NULL, '2019-08-27 21:31:32.579915'),
-- ('3', 'Really Not Thomas', NULL, '2019-08-27 21:31:43.277847');

-- ALTER SEQUENCE app.user
-- 	RESTART WITH 4;

-- INSERT INTO app_private.account ("user_id", "email", "password_hash")
-- 		VALUES
--       ('1', 'thomasankcorn@gmail.com', '$2a$06$7USR4TnqA/Rsi/XKjzIg0uycr.9uVOuV4/jQ6PQ30UWeBqInnrcOa'),
--       ('2', 'ankcorn@gmail.com', '$2a$06$c/KRFxMuW6yi/FWQKhB1IebJU6c6X93j/sXLXgIPx4olw3bAaF1n6'),
--       ('3', 'TAn@gmail.com', '$2a$06$XU1BoMJ4shV5NxBUoA4FcO6RGrCEAxkxh/HTDneJVv.FLCfnQhT/y');
