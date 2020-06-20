FROM php:7.4-alpine

VOLUME ["/feeds", "/app/cache"]

WORKDIR /app

ADD LICENSE .
ADD entrypoint .
ADD vendor vendor
ADD schemas schemas

RUN mkdir -p cache

ENTRYPOINT /app/entrypoint
