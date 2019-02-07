ExUnit.start()

defmodule TestHelper do
  def expected_meta_data_response(), do: %{
    body: ~s({"Code" : "Success",
    "LastUpdated" : "2019-02-06T11:04:42Z",
    "Type" : "AWS-HMAC",
    "AccessKeyId" : "aws-access-key",
    "SecretAccessKey" : "aws-secret-key",
    "Token" : "aws-token",
    "Expiration" : "2019-02-06T17:08:56Z"})
  }

  def example_credentials, do: %{
    aws_access_key: "aws-access-key",
    aws_secret_key: "secret-access-key",
    aws_token: "aws-token"
  }

  def example_function_name, do: "hello-world"

  def example_role_name, do: "role-to-invoke-lambda-with"

  def expected_meta_data_url(role), do: "http://169.254.169.254/latest/meta-data/iam/security-credentials/#{role}"
  
  def expected_invocation_url(function_name), do: "https://lambda.eu-west-1.amazonaws.com/2015-03-31/functions/#{function_name}/invocations"

  def example_invocation_result, do: {:ok,  %{body: "Hello world!", status_code: 200} }
end
