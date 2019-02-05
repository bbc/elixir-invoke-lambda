defmodule LambdaAuthTest do
  use ExUnit.Case

  test "build authorization header" do
    result = LambdaInvoke.invoke("arn:aws:lambda:eu-west-1:134209033928:function:ingress-hello-world")
    IO.inspect result
  end
end
