# SchmerdlePhoenix

To start your Phoenix server:

- Install dependencies with `mix deps.get`
- Create and migrate your database with `mix ecto.setup`
- Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

- Official website: https://www.phoenixframework.org/
- Guides: https://hexdocs.pm/phoenix/overview.html
- Docs: https://hexdocs.pm/phoenix
- Forum: https://elixirforum.com/c/phoenix-forum
- Source: https://github.com/phoenixframework/phoenix

## Loading words data into prod

Load the word data in your local db first with

```shell
mix run priv/repo/seeds.exs
```

Then, create a dump of the words data with

```shell
docker exec -it postgres bash -c "pg_dump -U postgres --data-only --table=words schmerdle_phoenix_dev > db.sql"
docker cp postgres:/db.sql ~/
```

You should now have a db.sql file in your home directory.

Now, activate the wireguard tunnel by opening wireguard and
clicking the appropriate connection.

Next, copy the db.sql file up to the db server with

```shell
cat db.sql | ssh root@birdie-db.internal 'tee /db.sql'
```

(found here: https://community.fly.io/t/scp-a-file-into-a-persistent-volume/2729/8)

Then, ssh into the db server

```shell
ssh root@birdie-db.internal
```

From there, restore the db dump with

```shell
psql -h localhost -p 5432 -U postgres birdie < db.sql
```
