# Postgraphile Docker Compose Playground
Prototyping apps can sometimes be tricky. This project helps to quickly try out ideas when building a graphql api.

It combines:

* PostgreSQL
* Docker Compose
* [Postgraphile](https://www.graphile.org/postgraphile/)

to build very fast graphql api with no server side code. Once you have installed PostgreSQL, and Docker Compose.

## Getting started


```sh
git clone https://github.com/Ankcorn/Postgraphile-Docker-Compose.git
cd Postgraphile-Docker-Compose
docker-compose up
```

If you are having issues with the schema not updating run

`docker-compose down && docker-compose up --build`


Contributions are welcome
