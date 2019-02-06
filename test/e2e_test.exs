defmodule E2eTest do
  use ExUnit.Case
  
  import Mock

  alias InvokeLambda.{Config}

  @function_name "hello-world"
  @invocation_result {:ok,  %{body: "Hello world!", status_code: 200} }
  @expected_invocation_url "https://lambda.eu-west-1.amazonaws.com/2015-03-31/functions/#{@function_name}/invocations"
  @expected_body ""


  test "sends POST to invoke AWS lambda" do
    with_mocks([
      {HTTPoison,
       [],
       [post: fn(@expected_invocation_url, @expected_body, _headers) -> @invocation_result end]},
      {Config,
       [],
       [
        aws_secret_key: fn -> "aws-secret-key" end,
        aws_access_key: fn -> "aws-access-key" end
        ]}
    ]) do
      {:ok, result} = InvokeLambda.invoke(@function_name)

      assert_called HTTPoison.post(@expected_invocation_url, :_, :_)
      assert result.body == "Hello world!"
      assert result.status_code == 200, result.body
    end
  end

  test "invokes lambda by sending live request" do
    {:ok, result} = InvokeLambda.invoke("ingress-hello-world")
  
    assert result.body == "\"<html><body><h1>Hello world</h1></body></html>\""
    assert result.status_code == 200, result.body
  end
end
