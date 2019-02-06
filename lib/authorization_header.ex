defmodule AuthorizationHeader do
  def build(invoke_lambda_url, headers, date) do
    IO.puts "build headers"
    IO.inspect headers

    string_to_sign = string_to_sign(
      date,
      canonical_request(invoke_lambda_url, headers)
    )

    [
      "AWS4-HMAC-SHA256 Credential=#{credential(date)}",
      "SignedHeaders=#{signed_headers()}",
      "Signature=#{signature(date, string_to_sign)}",
    ]
    |> Enum.join(", ")
  end

  defp signed_headers do
    "host;x-amz-date"
  end

  # https://github.com/aws/aws-sdk-ruby/blob/master/gems/aws-sigv4/lib/aws-sigv4/signer.rb#L369
  def string_to_sign(date, canonical_request) do
    [
      "AWS4-HMAC-SHA256",
      Utils.date_in_iso8601(date),
      credential_scope(date),
      Crypto.sha256(canonical_request) |> Crypto.hex
    ]
    |> Enum.join("\n")
  end

  defp content_sha256 do
    Crypto.sha256("") |> Crypto.hex
  end

  # https://github.com/aws/aws-sdk-ruby/blob/master/gems/aws-sigv4/lib/aws-sigv4/signer.rb#L391
  defp signature(date, string_to_sign) do
    Crypto.hmac(
      signing_key(date), 
      string_to_sign
    ) |> Crypto.hex
  end

  def signing_key(date) do
    "AWS4" <> Config.aws_secret_key()
    |> Crypto.hmac(Utils.short_date(date))
    |> Crypto.hmac(Config.region())
    |> Crypto.hmac(Config.service())
    |> Crypto.hmac("aws4_request")
  end

  def canonical_request(invoke_lambda_url, headers) do
    parsed_uri = URI.parse(invoke_lambda_url)

    [
      "POST",
      parsed_uri.path,
      '', # parsed_uri.query
      canonical_headers(headers),
      signed_headers(),
      content_sha256(),
    ]
    |> Enum.join("\n")
  end

  def canonical_headers(headers) when is_map(headers) do
    canon_headers = headers |> Enum.map(fn {header_name, header_value} -> 
      header_name = header_name |> String.downcase |> String.trim
      header_value = header_value |> String.trim

      header_name <> ":" <> header_value <> "\n"
    end)

    canon_headers |> Enum.join("")
  end

  def credential_scope(date) do
    [
      Utils.short_date(date),
      Config.region(),
      Config.service(),
      "aws4_request"
    ]
    |> Enum.join("/")
  end

  defp credential(date) do
    "#{Config.aws_access_key()}/#{credential_scope(date)}"
  end
end
