defmodule LambdaAuthTest do
  use ExUnit.Case

  test "build authorization header" do
    {:ok, result} = LambdaInvoke.invoke("ingress-hello-world")

    assert result.status_code == 200, result.body
  end
end
