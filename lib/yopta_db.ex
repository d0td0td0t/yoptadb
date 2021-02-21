defmodule YoptaDb do


  defmacro __using__(_) do
    quote do
      import YoptaDb
    end
  end


  @moduledoc """
  Documentation for `YoptaDb`.
  """

  @doc """
  YoptaDb is a time series database inspired by kairosdb.

  ## Examples
      iex> import YoptaDb
      YoptaDb
      iex> YoptaDb.init(["10.88.0.2:9042","10.88.0.3:9042"], %{:keyspace=> "my_keyspace1", :replication_factor=>1})
      iex> YoptaDb.put("7dc62817-e855-4568-ac93-d4f0b7f294da",1609892726,21.0)
      {:ok, "7dc62817-e855-4568-ac93-d4f0b7f294da"}
      iex> YoptaDb.get("7dc62817-e855-4568-ac93-d4f0b7f294da",1609892726, 1609892730)
      {:ok, [{1609892726, 21.0},{1609892727", 21.1}]}

  ## Tables:
     rki: [{key, timestamp}] (key index) 
     dp: [{key, dp_key, offset, data}] (datapoints)

  """

  defp create_keyspace(conn,config) do
    keyspace_st = "CREATE KEYSPACE IF NOT EXISTS #{config[:keyspace]} WITH REPLICATION = {'class' : 'SimpleStrategy', 'replication_factor' : #{config[:replication_factor]} } "
    IO.puts(keyspace_st)
    {:ok, _} = Xandra.execute(conn, keyspace_st, _params = [])
    use_st = "USE #{config[:keyspace]}"
    {:ok, _} = Xandra.execute(conn, use_st, _params = [])
    rki_st = "CREATE TABLE IF NOT EXISTS rki ( key text, dp_ts timestamp, PRIMARY KEY (key, dp_ts)) WITH CLUSTERING ORDER BY (dp_ts ASC)"
    {:ok, _} = Xandra.execute(conn, rki_st, _params = [])
    dp_st = "CREATE TABLE IF NOT EXISTS dp (dp_key text, ts timestamp, v blob, PRIMARY KEY (dp_key, ts)) WITH CLUSTERING ORDER BY ( ts ASC )"
    {:ok, _} = Xandra.execute(conn, dp_st, _params = [])
    {:ok, conn}
  end

  def init(nodes,config) when is_map(config) do
    {:ok, conn} = Xandra.start_link(nodes: nodes)
    {:ok, conn} = create_keyspace(conn,config)
  end

  defmacro gen_offset(ts) do 
    quote do 
      rem(unquote(ts),18144000000)
    end
  end

  defmacro gen_dp_ts(ts,offset) do
    quote do
      (unquote(ts) - unquote(offset))
    end
  end

  def put(conn, key,ts,v) do 
    offset=gen_offset(ts)
    dp_ts=gen_dp_ts(ts,offset)
    dp_key="#{key}:#{dp_ts}"
    rki_st = Xandra.prepare!(conn, "INSERT INTO rki (key, dp_ts) VALUES (:key, :dp_ts)")
    {:ok, _} = Xandra.execute(conn, rki_st, %{"key" => key, "dp_ts" => dp_ts})
    dp_st = Xandra.prepare!(conn, "INSERT INTO dp (dp_key, ts, v) VALUES (:dp_key, :ts, :v)")
    {:ok, _} = Xandra.execute(conn, dp_st, %{"dp_key" => dp_key, "ts" => ts, "v" => v})
  end

  def get(conn, key,ts1,ts2) do
    rki_st = Xandra.prepare!(conn, "SELECT dp_ts FROM rki WHERE key=:key AND dp_ts >=:ts1 AND dp_ts <= :ts2")
    {:ok, %Xandra.Page{}=dp_tss} = Xandra.execute(conn, rki_st, %{ "key" => key, "ts1" => ts1, "ts2" => ts2})
    dp_keys = Enum.map(dp_tss, fn %{ "dp_ts" => dp_ts } -> "#{key}:#{DateTime.to_unix(dp_ts)}000" end)
     
    dp_st = Xandra.prepare!(conn, "SELECT ts, v FROM dp WHERE dp_key IN :dp_keys AND ts>= :ts1 AND ts<= :ts2")
    {:ok, %Xandra.Page{}=dp_data} = Xandra.execute(conn, dp_st, %{ "dp_keys" => dp_keys, "ts1" => ts1, "ts2" => ts2})
    {:ok, Enum.map(dp_data, fn %{ "ts" => ts, "v" => v} -> {ts,v} end)}
  end

end
