defmodule InvokeLambda do

  alias InvokeLambda.{AuthorizationHeader, Utils}

  @aws_endpoint_version "2015-03-31"

  def invoke(function_name, options \\ %{}) do
    params = build_params(function_name, options)

    HTTPoison.post(
      params.invoke_lambda_url,
      post_body(),
      params.headers
    )
  end

  def build_params(function_name, options) do
    %{region: "eu-west-1", function_name: function_name, service: "lambda"} 
    |> Map.merge(options)
    |> put_date
    |> put_invoke_lambda_url
    |> put_headers
  end

  def post_body, do: ""

  def put_invoke_lambda_url(params) do
    Map.put(params, :invoke_lambda_url, URI.encode("https://lambda.#{params.region}.amazonaws.com/#{@aws_endpoint_version}/functions/#{params.function_name}/invocations"))
  end

  defp put_date(params), do: Map.put(params, :date, DateTime.utc_now)
  defp put_headers(params), do: Map.put(params, :headers, build_headers(params))

  defp build_headers(params) do
    parsed_uri = URI.parse(params.invoke_lambda_url)
    [
      {"host",  parsed_uri.host},
      {"x-amz-date", Utils.date_in_iso8601(params.date)},
      ]
    |> add_auth_header(params)
  end

  defp add_auth_header(headers, params) do
    authorization = AuthorizationHeader.build(params, headers)
    headers ++ [{"authorization", authorization}]
  end
end
