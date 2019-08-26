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

CREATE TABLE app.organiser (
	id serial PRIMARY KEY,
	organiser integer NOT NULL REFERENCES app.user(id),
	meetup integer NOT NULL REFERENCES app.group (id)
);

grant select on table app.organiser to app_anonymous;

CREATE TABLE app.comment (
	id serial PRIMARY KEY,
	message text NOT NULL,
	likes integer DEFAULT 0,
	person integer NOT NULL REFERENCES app.user(id),
	event integer NOT NULL REFERENCES app.event (id),
	parent integer NOT NULL REFERENCES app.comment (id)
);

grant select on table app.comment to app_anonymous;

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
