FROM node:alpine
LABEL description="Instant high-performance GraphQL API for your PostgreSQL database https://github.com/graphile/postgraphile"

RUN npm install -g postgraphile @graphile/subscriptions-lds

EXPOSE 5000
ENTRYPOINT ["postgraphile"]
