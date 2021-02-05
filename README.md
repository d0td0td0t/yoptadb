# YoptaDb

**YoptaDB is a simple time series database backed by Scylla or Cassandra**

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


Currently, just 2 methods are implemented:
      iex> YoptaDb.put("7dc62817-e855-4568-ac93-d4f0b7f294da",1609892726,21.0)
      {:ok, "7dc62817-e855-4568-ac93-d4f0b7f294da"}
      iex> YoptaDb.get("7dc62817-e855-4568-ac93-d4f0b7f294da",1609892726, 1609892730)
      {:ok, [{1609892726, 21.0},{1609892727", 21.1}]}

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/yopta_db](https://hexdocs.pm/yopta_db).
