defmodule LambdaAuthTest do
  use ExUnit.Case
  
  import Mock

  alias InvokeLambda.{Config}

  @function_name "hello-world"
  @region "eu-west-1"
  
  test "lambda_url/2" do
    actual = InvokeLambda.lambda_url @region, @function_name
    expected = "https://lambda.eu-west-1.amazonaws.com/2015-03-31/functions/hello-world/invocations"

    assert expected == actual
  end
end
