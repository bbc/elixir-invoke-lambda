defmodule InvokeLambda do
  alias InvokeLambda.{AuthorizationHeader, Utils, CredentialStore, SignedRequest}

  import SweetXml, only: [sigil_x: 2]

  @aws_endpoint_version "2015-03-31"

  def invoke(
        function_name,
        %{
          lambda_role_arn: _,
          instance_role_name: _
        } = options
      ) do
    params = build_params(function_name, options)

    IO.puts("InvokeLambda.invoke/2, params:")
    IO.inspect(params)

    params
    |> assume_role
    |> invoke_lambda
  end

  defp assume_role(params) do
    #

    {:ok, %{body: lambda_credentials}} =
      ExAws.STS.assume_role(
        params.lambda_role_arn,
        List.last(String.split(params.lambda_role_arn, "/"))
      )
      |> ExAws.request()
      |> parse_xml

    params
    |> Map.put(:lambda_credentials, %{
      aws_access_key: lambda_credentials.access_key_id,
      aws_secret_key: lambda_credentials.secret_access_key,
      aws_token: lambda_credentials.session_token
    })
  end

  defp parse_xml({:ok, %{body: xml} = resp}) do
    parsed_body =
      xml
      |> SweetXml.xpath(~x"//AssumeRoleResponse",
        access_key_id: ~x"./AssumeRoleResult/Credentials/AccessKeyId/text()"s,
        secret_access_key: ~x"./AssumeRoleResult/Credentials/SecretAccessKey/text()"s,
        session_token: ~x"./AssumeRoleResult/Credentials/SessionToken/text()"s,
        expiration: ~x"./AssumeRoleResult/Credentials/Expiration/text()"s,
        assumed_role_id: ~x"./AssumeRoleResult/AssumedRoleUser/AssumedRoleId/text()"s,
        assumed_role_arn: ~x"./AssumeRoleResult/AssumedRoleUser/Arn/text()"s,
        request_id: request_id_xpath()
      )

    {:ok, Map.put(resp, :body, parsed_body)}
  end

  defp request_id_xpath do
    ~x"./ResponseMetadata/RequestId/text()"s
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
