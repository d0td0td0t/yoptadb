defmodule YoptaDbTest do
  use ExUnit.Case
  doctest YoptaDb

  test "greets the world" do
    assert YoptaDb.hello() == :world
  end
end
