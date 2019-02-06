defmodule InvokeLambda do

  alias InvokeLambda.{AuthorizationHeader, Utils, Config, Crypto}

  @aws_endpoint_version "2015-03-31"

  def invoke(function_name, region \\ "eu-west-1") do
    invoke_lambda_url = lambda_url(region, function_name)
    HTTPoison.post(
      invoke_lambda_url,
      post_body(),
      headers(region, invoke_lambda_url)
    )
  end

  def post_body, do: ""
  def service, do: "lambda"

  def lambda_url(region, function_name) do
    "https://lambda.#{region}.amazonaws.com/#{@aws_endpoint_version}/functions/#{function_name}/invocations" |> URI.encode
  end
  
  defp headers(region, invoke_lambda_url) do
    date = DateTime.utc_now
    parsed_uri = URI.parse(invoke_lambda_url)

    [
      {"host",  parsed_uri.host},
      {"x-amz-date", Utils.date_in_iso8601(date)},
    ]
      |> add_auth_header(region, invoke_lambda_url, date)
  end

  defp add_auth_header(headers, region, invoke_lambda_url, date) do
    authorization = AuthorizationHeader.build(region, invoke_lambda_url, headers, date)
    headers ++ [{"authorization", authorization}]
  end
end
