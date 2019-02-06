defmodule InvokeLambda.AuthorizationHeader do

  alias InvokeLambda.{Crypto, Utils, Config}

  @signable_headers ["host", "x-amz-date"]

  def build(region, invoke_lambda_url, headers, date) do
    string_to_sign = string_to_sign(
      region,  
      date,
      canonical_request(invoke_lambda_url, headers)
    )

    [
      "AWS4-HMAC-SHA256 Credential=#{credential(date, region)}",
      "SignedHeaders=#{signed_headers()}",
      "Signature=#{signature(region, date, string_to_sign)}",
    ]
      |> Enum.join(", ")
  end

  defp signed_headers do
    @signable_headers |> Enum.join ";"
  end

  def string_to_sign(region, date, canonical_request) do
    [
      "AWS4-HMAC-SHA256",
      Utils.date_in_iso8601(date),
      credential_scope(date, region),
      Crypto.sha256(canonical_request) |> Crypto.hex
    ]
      |> Enum.join("\n")
  end

  defp content_sha256 do
    InvokeLambda.post_body |> Crypto.sha256 |> Crypto.hex
  end

  defp signature(region, date, string_to_sign) do
    date
      |> signing_key(region)
      |> Crypto.hmac(string_to_sign) 
      |> Crypto.hex
  end

  def signing_key(date, region) do
    "AWS4" <> Config.aws_secret_key()
      |> Crypto.hmac(Utils.short_date(date))
      |> Crypto.hmac(region)
      |> Crypto.hmac(InvokeLambda.service)
      |> Crypto.hmac("aws4_request")
  end

  def canonical_request(invoke_lambda_url, headers) do
    parsed_uri = URI.parse(invoke_lambda_url)

    [
      "POST",
      parsed_uri.path,
      parsed_uri.query || '',
      canonical_headers(headers),
      signed_headers(),
      content_sha256(),
    ]
      |> Enum.join("\n")
  end

  def canonical_headers(headers) when is_list(headers) do
    headers 
      |> Enum.filter(&is_canonical_header?/1)
      |> Enum.map(&canonical_header/1)
      |> Enum.join("")
  end

  defp is_canonical_header?({header_name, _}) do
    @signable_headers
      |> Enum.member?(String.downcase(header_name))
  end

  defp canonical_header({header_name, header_value}) do
    header_name = header_name |> String.downcase |> String.trim
    header_value = header_value |> String.trim

    header_name <> ":" <> header_value <> "\n"
  end

  def credential_scope(date, region) do
    [
      Utils.short_date(date),
      region,
      InvokeLambda.service,
      "aws4_request"
    ]
      |> Enum.join("/")
  end

  defp credential(date, region) do
    "#{Config.aws_access_key()}/#{credential_scope(date, region)}"
  end
end
