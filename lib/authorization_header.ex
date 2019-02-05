defmodule AuthorizationHeader do
  def build(invoke_lambda_url) do
    # URI.parse(invoke_lambda_url)
    [
      "AWS4-HMAC-SHA256 Credential=#{credential(creds, date)}",
      "SignedHeaders=#{signed_headers(headers)}",
      "Signature=#{sig}",
    ]
    |> Enum.join ", "
  end

  defp headers(invoke_lambda_url) do
    {host} = URI.parse(invoke_lambda_url)

    [
      {"host", host},
      {"x-amz-date", }
    ]
  end

  defp credential do
    
  end
end
