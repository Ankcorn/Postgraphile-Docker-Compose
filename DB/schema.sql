begin;

drop schema if exists rtm;
drop schema if exists rtm_private;

create schema rtm;
create schema rtm_private;

create role rtm_user login password 'xyz';
create role rtm_anonymous;
grant rtm_anonymous to rtm_user;

create role rtm_person;
grant rtm_person to rtm_user;

create table rtm.meetup (
  id               serial primary key,
  title            text not null check (char_length(title) < 80),
  about            text,
  post_code        text,
  date_time        timestamp
);

comment on table rtm.meetup is 'A Meetup';
comment on column rtm.meetup.id is 'The primary unique identifier for the meetup.';
comment on column rtm.meetup.title is 'The meetups name.';
comment on column rtm.meetup.about is 'A short description about the meetup.';
comment on column rtm.meetup.created_at is 'The time this meetup was created.';


create table rtm.user (
  id               serial primary key,
  first_name       text not null check (char_length(first_name) < 80),
  about            text,
  created_at       timestamp default now()
);

comment on table rtm.user is 'A User';
comment on column rtm.user.id is 'The primary unique identifier for the user.';
comment on column rtm.user.first_name is 'The user’s first name.';
comment on column rtm.user.about is 'A short description about the user, written by the user.';
comment on column rtm.user.created_at is 'The time this user was created.';

create table rtm_private.account (
  user_id         integer primary key references rtm.user(id) on delete cascade,
  email           text not null unique check (email ~* '^.+@.+\..+$'),
  password_hash   text not null
);

comment on table rtm_private.account is 'Private information associated with a user account';
comment on column rtm_private.account.user_id is 'The primary key for a user';
comment on column rtm_private.account.email is 'The email of the user';
comment on column rtm_private.account.password_hash is 'The hashed password of the user account';

create extension if not exists "pgcrypto";

create function rtm.register_user (
    first_name text,
    email text,
    password text
) returns rtm.user as $$
declare
  person rtm.user;
begin
  insert into rtm.user (first_name, created_at) values
    (first_name, now())
    returning * into person;

  insert into rtm_private.account (user_id, email, password_hash) values 
    (person.id, email, crypt(password, gen_salt('bf')));

  return person;
end;
$$ language plpgsql strict security definer;

comment on function rtm.register_user(text, text, text) is 'Registers a single user';


create type rtm.jwt_token as (
  role text,
  user_id integer
);

create function rtm.authenticate(
  email text,
  password text
) returns rtm.jwt_token as $$
  select('rtm_user', user_id)::rtm.jwt_token
    from rtm_private.account
    where
      account.email = $1
      and account.password_hash = crypt($2, account.password_hash);
$$ language sql strict security definer;

comment on function rtm.authenticate(text, text) is 'Creates a JWT token that will securely identify a person and give them certain permissions.';

create function rtm.current_user() returns rtm.user as $$
  select *
  from rtm.user
  where id = current_setting('jwt.claims.user_id')::integer
$$ language sql stable;

comment on function rtm.current_user() is 'Gets the user who was identified by our JWT.';

grant usage on schema rtm to rtm_anonymous, rtm_person;


grant select, update, delete on table rtm.user to rtm_person;
grant select, update, insert, delete on table rtm.meetup to rtm_anonymous, rtm_person;

grant execute on function rtm.authenticate(text, text) to rtm_anonymous, rtm_person;
grant execute on function rtm.current_user() to rtm_anonymous, rtm_person;

grant execute on function rtm.register_user(text, text, text) to rtm_anonymous;
commit;
