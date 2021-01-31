defmodule YoptaDb.Keyspace do
  use Triton.Keyspace

  keyspace :my_keyspace, conn: Triton.Conn do
    with_options [
      replication: "{'class' : 'SimpleStrategy', 'replication_factor': 3}"
    ]
  end
end
defmodule YoptaDb.RKI do
  require YoptaDb.Keyspace  
  use Triton.Table

  table :rki, keyspace: YoptaDb.Keyspace do
    field :key, :text, validators: [presence: true]  # validators using vex
    field :dp_ts, :timestamp
    partition_key [{:key, :dp_ts}]
    with_options [ 
      clustering_order_by: [
        timestamp: :asc
      ]
    ]
  end
end

defmodule YoptaDb.DP do
  require YoptaDb.Keyspace  
  use Triton.Table

  table :dp, keyspace: YoptaDb.Keyspace do
    field :key, :text, validators: [presence: true]  # validators using vex
    field :ts, :timestamp
    field :data, :blob
    partition_key [:key]
    with_options [
      clustering_order_by: [
        offset: :asc
      ]
    ]
  end
end

  

defmodule YoptaDb do
  @moduledoc """
  Documentation for `YoptaDb`.
  """

  @doc """
  YoptaDb is a time series database inspired by kairosdb.

  ## Examples

      iex> YoptaDb.put("7dc62817-e855-4568-ac93-d4f0b7f294da",1609892726,21.0)
      {:ok, "7dc62817-e855-4568-ac93-d4f0b7f294da"}
      iex> YoptaDb.get("7dc62817-e855-4568-ac93-d4f0b7f294da",1609892726, 1609892730)
      {:ok, [{1609892726, 21.0},{1609892727", 21.1}]}

  """
# Tables:
# rki: [{key, timestamp}] (key index) 
# dp: [{dp_key, offset, data}] (datapoints)

  alias YoptaDb.DP
  alias YoptaDb.RKI 
  import Triton.Query

  defmacro gen_offset(ts) do 
    quote do 
      rem(unquote(ts),18144000)
    end
  end
  defmacro gen_dp_ts(ts,offset) do
    quote do
      (unquote(ts) - unquote(offset))
    end
  end

  def put(key,ts,v) do 
    offset=gen_offset(ts)
    dp_ts=gen_dp_ts(ts,offset)
    dp_key="#{key}:{dp_ts}"
    RKI 
    |> prepared(key: key, dp_ts: dp_ts) 
    |> insert(key: :key, dp_ts: :dp_ts) 
    |> if_not_exists 
    |> RKI.save
    
    DP 
    |> prepared(key: dp_key, ts: ts, data: v) 
    |> insert(key: :key, ts: :ts, data: :data) 
    |> if_not_exists 
    |> DP.save
  end 
  def get(key,ts1,ts2) do
    dp_keys = RKI 
    |> prepared(key: key, ts1: ts1, ts2: ts2)  
    |> select([key, :data])
    |> where(key: key, dp_ts: [">=": ts1], dp_ts: ["<=": ts2])
    |> RKI.all
# All the metrics are within the same datapoint
    DP
    |> select([:key, :offset, :data])
    |> where(key: [in: dp_keys], ts: [">=": ts1], ts: ["<": ts2]) 
    |> DP.all
  end
end
