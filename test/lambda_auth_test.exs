defmodule LambdaAuthTest do
  use ExUnit.Case

  test "build authorization header" do
    assert LambdaAuth.header() == ""
  end
end
