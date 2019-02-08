defmodule InvokeLambda do
  alias InvokeLambda.{AuthorizationHeader, Utils, CredentialStore}

  @aws_endpoint_version "2015-03-31"

  def invoke(function_name, %{role: _} = options) do
    params = build_params(function_name, options)

    HTTPoison.post(
      params.invoke_lambda_url,
      params.function_payload,
      params.headers
    )
    |> format_invocation_response()
  end

  def format_invocation_response({_, function_response}) do
    {function_response.status_code, Poison.decode!(function_response.body)}
  end

  def build_params(function_name, options) do
    %{
      region: "eu-west-1",
      function_name: function_name,
      service: "lambda",
      meta_data_host: "http://169.254.169.254",
      function_payload: %{}
    }
    |> Map.merge(options)
    |> put_credentials
    |> put_date
    |> put_invoke_function_url
    |> encode_function_payload
    |> put_headers
  end

  def encode_function_payload(params) do
    %{params | function_payload: Poison.encode!(params.function_payload) }
  end

  def put_invoke_function_url(params) do
    Map.put(
      params,
      :invoke_lambda_url,
      URI.encode(
        "https://lambda.#{params.region}.amazonaws.com/#{@aws_endpoint_version}/functions/#{
          params.function_name
        }/invocations"
      )
    )
  end

  defp put_date(params), do: Map.put(params, :date, DateTime.utc_now())

  defp put_headers(params), do: Map.put(params, :headers, build_headers(params))

  defp put_credentials(params) do
    credentials = CredentialStore.retrieve_using_role(params)
    Map.put(params, :credentials, credentials)
  end

  defp build_headers(params) do
    params
    |> build_base_headers
    |> add_auth_headers(params)
  end

  defp build_base_headers(params) do
    parsed_uri = URI.parse(params.invoke_lambda_url)

    [
      {"content-type", "application/json"},
      {"host", parsed_uri.host},
      {"x-amz-date", Utils.date_in_iso8601(params.date)}
    ]
  end

  defp add_auth_headers(base_headers, params) do
    authorization = AuthorizationHeader.build(params, base_headers)

    base_headers ++
      [
        {"authorization", authorization},
        {"x-amz-security-token", params.credentials.aws_token}
      ]
  end
end
