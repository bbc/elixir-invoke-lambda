ExUnit.start()

defmodule TestHelper do
  def expected_meta_data_response(),
    do: %{
      body: ~s({"Code" : "Success",
    "LastUpdated" : "2019-02-06T11:04:42Z",
    "Type" : "AWS-HMAC",
    "AccessKeyId" : "aws-access-key",
    "SecretAccessKey" : "aws-secret-key",
    "Token" : "aws-token",
    "Expiration" : "2019-02-06T17:08:56Z"})
    }

  def expected_sts_response() do
    {
      :ok,
      %{
        status_code: 200,
        body:
          Poison.encode!(%{
            "AssumeRoleResponse" => %{
              "AssumeRoleResult" => %{
                "Credentials" => %{
                  "AccessKeyId" => "sts-aws-access-key",
                  "Expiration" => 1_550_056_374.0,
                  "SecretAccessKey" => "sts-aws-secret-key",
                  "SessionToken" => "sts-aws-token"
                }
              },
              "ResponseMetadata" => %{
                "RequestId" => "ed5adf3b-2f77-11e9-8ad1-45a6556a97a0"
              }
            }
          })
      }
    }
  end

  def example_credentials,
    do: %{
      aws_access_key: "aws-access-key",
      aws_secret_key: "secret-access-key",
      aws_token: "aws-token"
    }

  def example_function_name, do: "hello-world"

  def example_lambda_role_arn, do: "lambda_role-to-invoke-lambda-with"
  def example_instance_role_name, do: "ec2_role-to-assume-role-to-get-invoke-lambda-credentials"

  def expected_meta_data_url(instance_role),
    do: "http://169.254.169.254/latest/meta-data/iam/security-credentials/#{instance_role}"

  def expected_invocation_url(function_name),
    do: "https://lambda.eu-west-1.amazonaws.com/2015-03-31/functions/#{function_name}/invocations"

  def expected_sts_url(),
    do: "https://sts.amazonaws.com/"

  def example_invocation_result, do: {:ok, %{body: ~s({"hello": "world"}), status_code: 200}}

  def default_meta_data_host, do: "http://169.254.169.254"
end
