defmodule AppTest do
  use ExUnit.Case
  doctest App

  test "greets the world" do
    assert Backup.hello() == :world
  end
end
