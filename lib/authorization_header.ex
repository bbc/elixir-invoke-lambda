defmodule AuthorizationHeader do
  def build(invoke_lambda_url, headers, date) do

    string_to_sign = string_to_sign(
      date,
      canonical_request(invoke_lambda_url, headers)
    )

    [
      "AWS4-HMAC-SHA256 Credential=#{credential(date)}",
      "SignedHeaders=#{signed_headers()}",
      "Signature=#{signature(date, string_to_sign)}",
    ]
    |> Enum.join ", "
  end

  defp signed_headers do
    "host;x-amz-date"
  end

  # https://github.com/aws/aws-sdk-ruby/blob/master/gems/aws-sigv4/lib/aws-sigv4/signer.rb#L369
  defp string_to_sign(date, canonical_request) do
    [
      "AWS4-HMAC-SHA256",
      Utils.date_in_iso8601(date),
      credential_scope(date),
      Crypto.sha256(canonical_request) |> Crypto.hex
    ]
    |> Enum.join("\n")
  end

  # https://github.com/aws/aws-sdk-ruby/blob/master/gems/aws-sigv4/lib/aws-sigv4/signer.rb#L391
  defp signature(date, string_to_sign) do
    k_date = Crypto.hmac("AWS4" <> Config.aws_secret_key(), Utils.date_in_iso8601(date))
    k_region = Crypto.hmac(k_date, Config.region())
    k_service = Crypto.hmac(k_region, Config.service())
    k_credentials = Crypto.hmac(k_service, "aws4_request")
    Crypto.hmac(k_credentials, string_to_sign) |> Crypto.hex
  end

  defp canonical_request(invoke_lambda_url, headers) do
    parsed_uri = URI.parse(invoke_lambda_url)
    [
      "POST",
      parsed_uri.path,
      parsed_uri.query || '',
      canonical_headers(headers) <> "\n",
      signed_headers(),
      # content_sha256,
    ]
    |> Enum.join("\n")
  end

  defp canonical_headers(headers) do
    Map.keys(headers)
    |> Enum.map(fn header_key -> "#{header_key}:#{headers.get(header_key)}" end)
    |> Enum.join("\n")
  end

  defp credential_scope(date) do
    [
      Utils.short_date(date),
      Config.region(),
      Config.service(),
      "aws4_request"
    ]
    |> Enum.join "/"
  end

  defp credential(date) do
    "#{Config.aws_access_key()}/#{credential_scope(date)}"
  end
end
