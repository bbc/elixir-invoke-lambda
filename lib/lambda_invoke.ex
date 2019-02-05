defmodule LambdaInvoke do
  def invoke(lambda_arn) do
    invoke_lambda_url = lambda_url(lambda_arn)

    HTTPoison.post!(invoke_lambda_url, %{}, headers(url))
  end

  defp lambda_url(lambda_arn) do
    "https://lambda.eu-west-1.amazonaws.com/2015-03-31/functions/#{lambda_arn}>/invocations"
  end

  defp headers(invoke_lambda_url) do
    current_date_time = DateTime.utc_now
    
    [
      {"content-type", "application/json"},
      {"x-amz-date", DateTime.utc_now()},
      {"accept-encoding", "identity"},
      {"content-length", "0"},
      {"authorization", AuthorizationHeader.build(invoke_lambda_url)}
    ]
  end
end
