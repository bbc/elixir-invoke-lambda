defmodule LambdaInvoke do
  def invoke(lambda_arn) do
    HTTPoison.post!(lambda_url(lambda_arn), %{}, headers())
  end

  defp lambda_url(lambda_arn) do
    "https://lambda.eu-west-1.amazonaws.com/2015-03-31/functions/#{lambda_arn}>/invocations"
  end

  defp headers do
    [
      {"content-type", "application/json"},
      {"x-amz-date", DateTime.utc_now()},
      {"accept-encoding", "identity"},
      {"content-length", "0"},
      {"authorization", LambdaAuth.header()}
    ]
  end
end
