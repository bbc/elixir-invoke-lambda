defmodule StsTest do
  use ExUnit.Case

  alias InvokeLambda.{Utils}

  import Mock

  @expected_response_body "{\"AssumeRoleResponse\":{\"AssumeRoleResult\":{\"AssumedRoleUser\":{\"Arn\":\"assumed-role-arn\",\"AssumedRoleId\":\"assumed-role-id\"},\"Credentials\":{\"AccessKeyId\":\"<access-key-id>\",\"Expiration\":1.550049068E9,\"SecretAccessKey\":\"<secret-access-key>\",\"SessionToken\":\"<session-token>\"}}}}"

  @expected_sts_response {:ok,
                          %HTTPoison.Response{
                            status_code: 200,
                            body: @expected_response_body
                          }}

  @expected_sts_url "https://sts.amazonaws.com/"
  @expected_sts_body "Version=2011-06-15&RoleSessionName=lambda-access&RoleArn=lambda-role-arn&Action=AssumeRole"
  @expected_sts_headers [
    {"accept", "application/json"},
    {"content-type", "application/x-www-form-urlencoded; charset=utf-8"},
    {"content-length", 90},
    {"host", "sts.amazonaws.com"},
    {"x-amz-date", "20190207T163512Z"},
    {"authorization",
     "AWS4-HMAC-SHA256 Credential=<aws-access-key>/20190207/us-east-1/sts/aws4_request, SignedHeaders=host;x-amz-date, Signature=3c0bd50b6b469fc3f9d308aa2e34a89e190f9c0c50822053b0e415bafddde355"},
    {"x-amz-security-token", "<aws-security-token>"}
  ]
  @expected_timeouts [recv_timeout: 15000, timeout: 15000]

  test "send post to sts" do
    with_mocks([
      {HTTPoison, [],
       [
         post: fn _url, _body, _headers, _options -> @expected_sts_response end
       ]},
      {Utils, [],
       [
         date_in_iso8601: fn _ -> "20190207T163512Z" end,
         short_date: fn _ -> "20190207" end
       ]}
    ]) do
      params = %{
        lambda_role_arn: "lambda-role-arn",
        region: "eu-west-1",
        body: %{},
        service: :sts,
        credentials: %{
          aws_access_key: "<aws-access-key>",
          aws_secret_key: "<aws-secret-key>",
          aws_token: "<aws-security-token>"
        }
      }

      {200, result} = InvokeLambda.SignedRequest.send(params)

      assert_called(
        HTTPoison.post(
          @expected_sts_url,
          @expected_sts_body,
          @expected_sts_headers,
          @expected_timeouts
        )
      )

      assert result == Poison.decode!(@expected_response_body)
    end
  end
end
