defmodule LambdaTest do
  use ExUnit.Case

  alias InvokeLambda.{Utils}

  import Mock

  @expected_response_body ~s({"hello": "world"})

  @expected_lambda_response {:ok, %HTTPoison.Response{body: @expected_response_body, status_code: 200}}

  @expected_lambda_url "https://lambda.eu-west-1.amazonaws.com/2015-03-31/functions/function-name-to-invoke/invocations"
  @expected_lambda_body "{\"query\":\"I want the title please\"}"
  @expected_lambda_headers [
    {"content-type", "application/json"},
    {"host", "lambda.eu-west-1.amazonaws.com"},
    {"x-amz-date", "20190207T163512Z"},
    {"authorization",
     "AWS4-HMAC-SHA256 Credential=<aws-access-key>/20190207/eu-west-1/lambda/aws4_request, SignedHeaders=host;x-amz-date, Signature=997d9b9a97fd73b86986255e15ab88fcadeb5d5e3bcb0177c05b77f0f4f95436"},
    {"x-amz-security-token", "<aws-security-token>"}
  ]
  @expected_timeouts [recv_timeout: 15000, timeout: 15000]

  test "send post to lambda" do
    with_mocks([
      {HTTPoison, [],
       [
         post: fn _url, _body, _headers, _options -> @expected_lambda_response end
       ]},
      {Utils, [],
       [
         date_in_iso8601: fn _ -> "20190207T163512Z" end,
         short_date: fn _ -> "20190207" end
       ]}
    ]) do
      params = %{
        function_name: "function-name-to-invoke",
        region: "eu-west-1",
        body: %{
          query: "I want the title please"
        },
        service: :lambda,
        credentials: %{
          aws_access_key: "<aws-access-key>",
          aws_secret_key: "<aws-secret-key>",
          aws_token: "<aws-security-token>"
        }
      }

      {200, result} = InvokeLambda.SignedRequest.send(params)

      assert_called(
        HTTPoison.post(
          @expected_lambda_url,
          @expected_lambda_body,
          @expected_lambda_headers,
          @expected_timeouts
        )
      )

      assert result == Poison.decode!(@expected_response_body)
    end
  end
end
