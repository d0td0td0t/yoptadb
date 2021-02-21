defmodule YoptaDbTest do
  use ExUnit.Case
  doctest YoptaDb

  test "gen_dp_ts" do
    assert YoptaDb.gen_dp_ts(1612633578000,YoptaDb.gen_offset(1612633578000)) == 1596672000000
  end
end
