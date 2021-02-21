# YoptaDb

**YoptaDB is a simple time series database backed by Scylla or Cassandra**

The design is inspired by KairosDB.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `yopta_db` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:yopta_db, "~> 0.1.0"}
  ]
end
```

## Usage 

Currently, just 3 methods are implemented:

```elixir
# connect to C* database and create the keyspace/tables if needed
{:ok, pid} = YoptaDb.init(["10.88.0.2:9042"], %{:keyspace=> "my_keyspace3", :replication_factor=>1})
# put the counter
{:ok, _} = YoptaDb.put(pid, "7dc62817-e855-4568-ac93-d4f0b7f294da",DateTime.to_unix(DateTime.utc_now())*1000,"21.0")
# get a list of counters ({timestamp, value})
{:ok, list} = YoptaDb.get(pid, "7dc62817-e855-4568-ac93-d4f0b7f294da", 0, 16098927260000)
```

## ToDo:

Implement the gen_server protocol.

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/yopta_db](https://hexdocs.pm/yopta_db).
