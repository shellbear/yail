# Yail

A real-time collaborative song-request queue for Spotify.

## 🎧 Demo

To do...

## ⚙️ Environment variables

You have to create a Spotify app. You can refer to the [official documentation](https://developer.spotify.com/documentation/general/guides/app-settings/) to create in a minute.

After created your app, you must first define the following environment variables:
- `SPOTIFY_CLIENT_ID`
- `SPOTIFY_CLIENT_SECRET`

You can put them inside a `.env` file at the root of the project or by manually exporting them.

## 🐳 Using Docker

```shell script
docker build yail:latest .
docker run yail
```

## 🚀 Self-hosting

You can easily self-host this app. The easiest version is to run the app with Docker.

You have to define the following mandatory environment variables.

- `SECRET_KEY_BASE` (64 bytes)

A secret used to encode session and other sensitive data. For security reasons it must be composed of at least 64 characters.

You can easily generate it inside the root of this repo using the mix [phx.gen.secret](https://hexdocs.pm/phoenix/Mix.Tasks.Phx.Gen.Secret.html) command:

```shell script
mix phx.gen.secret 64
```

- `BASE_URL`

The base URL of the web application. This is for example the URL of a custom domain: `https://example.com` or an ip address.

## 🧑‍💻 Get started 

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Install Node.js dependencies with `npm install` inside the `assets` directory
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## 🏗 Built with

- [Elixir](https://elixir-lang.org/)
- [Phoenix Framework](https://www.phoenixframework.org/)
- [jsncmgs1/spotify_ex](https://github.com/jsncmgs1/spotify_ex)

## 📧 Contributing

All contributions are welcome. Code must be formatted with `hex format`.