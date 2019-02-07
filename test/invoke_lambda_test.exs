defmodule LambdaAuthTest do
  use ExUnit.Case

  @params %{function_name: "hello-world", region: "eu-west-1"}

  test "lambda_url/2" do
    actual =
      @params
      |> InvokeLambda.put_invoke_lambda_url()

    expected =
      "https://lambda.eu-west-1.amazonaws.com/2015-03-31/functions/hello-world/invocations"

    assert expected == actual.invoke_lambda_url
  end
end
