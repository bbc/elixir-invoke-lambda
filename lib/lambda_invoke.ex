defmodule LambdaInvoke do
  def invoke(lambda_arn) do
    invoke_lambda_url = lambda_url(lambda_arn)
    req_headers = headers(invoke_lambda_url)
    IO.inspect req_headers

    response = HTTPoison.post(invoke_lambda_url, "", req_headers)

    response
  end

  defp lambda_url(lambda_arn) do
    host = "https://lambda.eu-west-1.amazonaws.com"
    # host = "http://localhost:3000"
    path = "/2015-03-31/functions/#{lambda_arn}/invocations"

    host <> uri_encoded_path(path)
  end

  defp uri_encoded_path(path) do
    path
    |> String.split("/")
    |> Enum.map(fn (segment) -> URI.encode_www_form(segment) end)
    |> Enum.join("/")
  end
  
  defp headers(invoke_lambda_url) do
    date = DateTime.utc_now
    parsed_uri = URI.parse(invoke_lambda_url)

    base_headers = Map.new

    base_headers
    |> Map.put("host", parsed_uri.host)
    |> Map.put("x-amz-date", Utils.date_in_iso8601(date))

    authorization = AuthorizationHeader.build(invoke_lambda_url, base_headers, date)
    
    [
      {"content-type", "application/json"},
      {"host",  parsed_uri.host},
      {"x-amz-date", Utils.date_in_iso8601(date)},
      {"authorization", authorization}
    ]
  end
end
