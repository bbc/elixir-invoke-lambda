defmodule E2eTest do
  use ExUnit.Case

  import Mock

  alias InvokeLambda.{Crypto, Utils}

  @function_name TestHelper.example_function_name()
  @invocation_result TestHelper.example_invocation_result()
  @expected_invocation_url TestHelper.expected_invocation_url(@function_name)
  @expected_body ""
  @role TestHelper.example_role_name()
  @expected_meta_data_url TestHelper.expected_meta_data_url(@role)
  @options %{role: @role}
  @expected_invoke_headers [
    {"host", "lambda.eu-west-1.amazonaws.com"},
    {"x-amz-date", "20190207T163512Z"},
    {"authorization",
     "AWS4-HMAC-SHA256 Credential=aws-access-key/20190207/eu-west-1/lambda/aws4_request, SignedHeaders=host;x-amz-date, Signature=hex"},
    {"x-amz-security-token", "aws-token"}
  ]

  test "GET & POST AWS requests are sent correctly" do
    with_mocks([
      {HTTPoison, [],
       [
         get!: fn @expected_meta_data_url -> TestHelper.expected_meta_data_response() end,
         post: fn _, _, _ -> @invocation_result end
       ]},
      {Crypto, [],
       [
         hmac: fn _, _ -> "hmac" end,
         sha256: fn _ -> "sha256" end,
         hex: fn _ -> "hex" end
       ]},
      {Utils, [],
       [
         date_in_iso8601: fn _ -> "20190207T163512Z" end,
         short_date: fn _ -> "20190207" end
       ]}
    ]) do
      {:ok, result} = InvokeLambda.invoke(@function_name, @options)

      assert_called(
        HTTPoison.post(@expected_invocation_url, @expected_body, @expected_invoke_headers)
      )

      assert result.body == "Hello world!"
      assert result.status_code == 200, result.body
    end
  end
end
