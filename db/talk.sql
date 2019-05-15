-- Part 1

create schema rtm;

create table rtm.meetup (
  id               serial primary key,
  title            text not null check (char_length(title) < 80),
  about            text,
  post_code        text,
  date_time        timestamp
);

insert into rtm.meetup (title, about, post_code, date_time) values ('MancJS', 'Best Meetup in the Greater Manchester Area', 'M1 43A', '2020-05-15 6:30PM');
insert into rtm.meetup (title, about, post_code, date_time) values ('LNUG', 'Londons Longest Running Community Node.js meetup', 'SW1', '2019-05-22 6:30PM');

-- Part 2

create table rtm.review (
  id               serial primary key,
  meetup_id        int references rtm.meetup on delete cascade,
  comment          text,
  stars            int,
  check (stars >= 0 and stars < 6)
);

insert into rtm.review (meetup_id, comment, stars) values ('1', 'Wow Good Vibes', '5');
insert into rtm.review (meetup_id, comment, stars) values ('2', 'Conde Nast Is the Best Venue of all time', '5');

-- Part 3 Functions
alter default privileges revoke execute on functions from public;

create function rtm.meetup_average_rating(
  meetup rtm.meetup
) returns numeric as $$
  select AVG (stars) from rtm.review where rtm.review.meetup_id = meetup.id
$$ language sql stable;

create function rtm.meetup_ordered_by_rating(
  
) returns setof rtm.meetup as $$
  select *
  from rtm.meetup
  order by rtm.meetup_average_rating(meetup) desc
$$ language sql stable;

-- Part 4 Security

create table rtm.user (
  id               serial primary key,
  first_name       text not null check (char_length(first_name) < 80),
  about            text,
  created_at       timestamp default now()
);

create schema rtm_private;

create table rtm_private.account (
  user_id         integer primary key references rtm.user(id) on delete cascade,
  email           text not null unique check (email ~* '^.+@.+\..+$'),
  password_hash   text not null
);

-- Part 5

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

-- Part 6


create type rtm.jwt_token as (
  role text,
  user_id integer
);

-- Part 7

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


-- Part 8

create role rtm_user login password 'xyz';

create role rtm_anonymous;
grant rtm_anonymous to rtm_user;

create role rtm_person;
grant rtm_person to rtm_user;

-- Part 9

grant usage on schema rtm to rtm_anonymous, rtm_person;

grant select, update, delete on table rtm.user to rtm_person;
grant select, update, insert, delete on table rtm.meetup to rtm_person;
grant select, update, insert, delete on table rtm.review to rtm_person;

grant execute on function rtm.register_user(text, text, text) to rtm_anonymous;

grant execute on function rtm.authenticate(text, text) to rtm_anonymous, rtm_person;

grant execute on function rtm.meetup_average_rating to rtm_person;
grant execute on function rtm.meetup_ordered_by_rating to rtm_person;



