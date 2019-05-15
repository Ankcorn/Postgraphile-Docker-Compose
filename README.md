# Rate The Meetup
This is the accompanying repo for [this](https://www.meetup.com/MancJS/events/261281331/) meetup. Its a graphql based Meetup Rating App. It uses:

* PostgreSQL
* Docker
* [Postgraphile](https://www.graphile.org/postgraphile/)

## Installation

All you need to get started is to have docker installed on your machine. Then you can simply run

```sh
git clone https://github.com/Ankcorn/MancJS-Talk.git
cd MancJS-Talk
docker-compose up
```

If you are having issues with the schema not updating run

`docker-compose down && docker-compose up --build`

## Projects structure

* db - contains db Dockerfile and talk.sql file
* postgraphile - contains postgraphile Dockerfile with the live query plugin installed

Contributions are welcome
