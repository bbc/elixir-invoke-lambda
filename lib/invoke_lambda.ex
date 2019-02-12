defmodule InvokeLambda do
  alias InvokeLambda.{AuthorizationHeader, Utils, CredentialStore, SignedRequest}

  @aws_endpoint_version "2015-03-31"

  def invoke(function_name, %{
    lambda_role_arn: _,
    instance_role_name: _,
  } = options) do
    params = build_params(function_name, options)

    IO.puts "InvokeLambda.invoke/2, params:"
    IO.inspect params

    params
    |> instance_credentials
    |> assume_role
    |> invoke_lambda

  end

  defp assume_role(params) do
    {200, lambda_credentials} = SignedRequest.send(%{
      service: :sts,
      region: params.region,
      credentials: params.instance_credentials,
      body: %{
        "RoleArn" => params.lambda_role_arn,
        "RoleSessionName" => "lambda-access",
        "Action": "AssumeRole",
        "Version": "2011-06-15",
      }
    })

    params
    |> Map.put(:lambda_credentials, %{
      aws_access_key: lambda_credentials["AccessKeyId"],
      aws_secret_key: lambda_credentials["SecretAccessKey"],
      aws_token: lambda_credentials["Token"]
    })
  end

  defp invoke_lambda(params) do
    SignedRequest.send(%{
      function_name: params.function_name,
      region: params.region,
      credentials: params.lambda_credentials,
      service: :lambda,
      body: params.function_payload
    })
  end

  def build_params(function_name, options) do
    %{
      region: "eu-west-1",
      function_name: function_name,
      meta_data_host: "http://169.254.169.254",
      function_payload: %{}
    }
    |> Map.merge(options)
  end

  defp instance_credentials(params) do
    credentials = CredentialStore.retrieve_using_instance_role(params)
    Map.put(params, :instance_credentials, credentials)
  end
end
