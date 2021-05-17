#### Builder
FROM hexpm/elixir:1.11.4-erlang-24.0-alpine-3.13.3 as buildcontainer

# preparation
ARG APP_VER=0.0.1
ENV MIX_ENV=prod
ENV NODE_ENV=production
ENV APP_VERSION=$APP_VER

RUN mkdir /app
WORKDIR /app

# install build dependencies
RUN apk add --no-cache git nodejs yarn python3 npm ca-certificates wget gnupg make erlang gcc libc-dev && \
    npm install npm@latest -g && \
    npm install -g webpack-cli

COPY mix.exs ./
COPY mix.lock ./
RUN mix local.hex --force && \
    mix local.rebar --force && \
    mix deps.get --only prod && \
    mix deps.compile

COPY assets/package.json assets/package-lock.json ./assets/

RUN npm install --prefix ./assets

COPY assets ./assets
COPY config ./config
COPY priv ./priv
COPY lib ./lib

RUN npm run deploy --prefix ./assets
RUN mix phx.digest priv/static

WORKDIR /app
COPY rel rel
RUN mix release

#### Main
FROM frolvlad/alpine-glibc:alpine-3.13

RUN apk update && apk upgrade

RUN apk add --no-cache openssl ncurses libstdc++

RUN adduser -h /app -u 1000 -s /bin/sh -D yail

COPY --from=buildcontainer /app/_build/prod/rel/yail /app
RUN chown -R yail:yail /app
USER yail
WORKDIR /app
ENTRYPOINT ["/app/bin/yail"]
EXPOSE 4000
CMD ["start"]