begin;

drop schema if exists rtm;

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

create table rtm.review (
  id               serial primary key,
  meetup_id        int references rtm.meetup on delete cascade,
  comment          text,
  stars            int,
  check (stars >= 0 and stars < 6)
);

insert into rtm.review (meetup_id, comment, stars) values ('1', 'Wow Good Vibes', '5');
insert into rtm.review (meetup_id, comment, stars) values ('2', 'Conde Nast Is the Best Venue of all time', '5');

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

commit;