begin;

drop schema if exists rtm;

create schema rtm;

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

commit;
