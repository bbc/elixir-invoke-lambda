defmodule E2eTest do
  use ExUnit.Case

  import Mock

  alias InvokeLambda.{Crypto, Utils}

  @function_name TestHelper.example_function_name()
  @invocation_result TestHelper.example_invocation_result()
  @expected_invocation_url TestHelper.expected_invocation_url(@function_name)
  @expected_sts_url TestHelper.expected_sts_url()
  @expected_sts_response TestHelper.expected_sts_response()
  @expected_invocation_body "{\"query\":\"I want the title please\"}"
  @expected_sts_body "{\"RoleSessionName\":\"lambda-access\",\"RoleArn\":\"lambda_role-to-invoke-lambda-with\",\"Version\":\"2011-06-15\",\"Action\":\"AssumeRole\"}"
  @lambda_role_arn TestHelper.example_lambda_role_arn()
  @instance_role TestHelper.example_instance_role_name()
  @expected_meta_data_url TestHelper.expected_meta_data_url(@instance_role)
  @options %{
    lambda_role_arn: @lambda_role_arn,
    instance_role_name: @instance_role,
    function_payload: %{query: "I want the title please"}
  }

  @expected_invoke_headers [
    {"content-type", "application/json"},
    {"host", "lambda.eu-west-1.amazonaws.com"},
    {"x-amz-date", "20190207T163512Z"},
    {"authorization",
     "AWS4-HMAC-SHA256 Credential=sts-aws-access-key/20190207/eu-west-1/lambda/aws4_request, SignedHeaders=host;x-amz-date, Signature=hex"},
    {"x-amz-security-token", "sts-aws-token"}
  ]

  @expected_sts_headers [
    {"content-type", "application/json"},
    {"host", "sts.eu-west-1.amazonaws.com"},
    {"x-amz-date", "20190207T163512Z"},
    {"authorization",
     "AWS4-HMAC-SHA256 Credential=aws-access-key/20190207/eu-west-1/sts/aws4_request, SignedHeaders=host;x-amz-date, Signature=hex"},
    {"x-amz-security-token", "aws-token"}
  ]

  test "GET & POST AWS requests are sent correctly" do
    with_mocks([
      {HTTPoison, [],
       [
         get!: fn @expected_meta_data_url -> TestHelper.expected_meta_data_response() end,
         post: fn
           @expected_sts_url, _, _, _ -> @expected_sts_response
           @expected_invocation_url, _, _, _ -> @invocation_result
         end
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
      {200, result} = InvokeLambda.invoke(@function_name, @options)

      assert_called(
        HTTPoison.post(
          @expected_invocation_url,
          @expected_invocation_body,
          @expected_invoke_headers,
          follow_redirect: true
        )
      )

      assert_called(
        HTTPoison.post(@expected_sts_url, @expected_sts_body, @expected_sts_headers,
          follow_redirect: true
        )
      )

      assert_called(HTTPoison.get!(@expected_meta_data_url))

      assert result == %{"hello" => "world"}
    end
  end
end
