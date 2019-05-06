begin;

drop schema if exists rtm;
drop schema if exists rtm_private;

create schema rtm;
create schema rtm_private;

create table rtm.user (
  id               serial primary key,
  first_name       text not null check (char_length(first_name) < 80),
  last_name        text check (char_length(last_name) < 80),
  about            text,
  created_at       timestamp default now()
);

comment on table rtm.user is 'A User';
comment on column rtm.user.id is 'The primary unique identifier for the user.';
comment on column rtm.user.first_name is 'The user’s first name.';
comment on column rtm.user.last_name is 'The user’s last name.';
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

create function rtm.register_person (
    first_name text,
    email text,
    password text
) returns rtm.user as $$
declare
  person rtm.user;
begin
  insert into rtm.user (first_name) values
    (first_name)
    returning * into person;

  insert into rtm_private.account (user_id, email, password_hash) values 
    (person.id, email, crypt(password, gen_salt('bf')));

  return person;
end;
$$ language plpgsql strict security definer;

commit;
