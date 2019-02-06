defmodule LambdaInvoke do
  def invoke(function_name) do
    invoke_lambda_url = lambda_url(function_name)
    req_headers = headers(invoke_lambda_url)

    response = HTTPoison.post(invoke_lambda_url, "", req_headers)

    response
  end

  defp lambda_url(function_name) do
    host = "https://lambda.eu-west-1.amazonaws.com"
    path = "/2015-03-31/functions/#{function_name}/invocations"

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

    base_headers = base_headers
    |> Map.put("host", parsed_uri.host)
    |> Map.put("x-amz-date", Utils.date_in_iso8601(date))

    authorization = AuthorizationHeader.build(invoke_lambda_url, base_headers, date)
    
    [
      {"content-type", "application/json"},
      {"accept-encoding", "identity"},
      {"host",  parsed_uri.host},
      {"x-amz-date", Utils.date_in_iso8601(date)},
      {"authorization", authorization}
    ]
  end
end
