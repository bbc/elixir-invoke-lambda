defmodule InvokeLambda.AuthorizationHeader do

  alias InvokeLambda.{Crypto, Utils}

  @signable_headers ["host", "x-amz-date"]

  def build(params, other_headers) do
    string_to_sign = string_to_sign(
      params,
      canonical_request(params, other_headers)
    )

    [
      "AWS4-HMAC-SHA256 Credential=#{credential(params)}",
      "SignedHeaders=#{signed_headers()}",
      "Signature=#{signature(params, string_to_sign)}",
    ]
      |> Enum.join(", ")
  end

  defp signed_headers do
    @signable_headers |> Enum.join ";"
  end

  def string_to_sign(params, canonical_request) do
    [
      "AWS4-HMAC-SHA256",
      Utils.date_in_iso8601(params.date),
      credential_scope(params),
      Crypto.sha256(canonical_request) |> Crypto.hex
    ]
      |> Enum.join("\n")
  end

  defp content_sha256 do
    InvokeLambda.post_body |> Crypto.sha256 |> Crypto.hex
  end

  defp signature(params, string_to_sign) do
      params
      |> signing_key
      |> Crypto.hmac(string_to_sign) 
      |> Crypto.hex
  end

  def signing_key(params) do
    "AWS4" <> params.credentials.aws_secret_key
      |> Crypto.hmac(Utils.short_date(params.date))
      |> Crypto.hmac(params.region)
      |> Crypto.hmac(params.service)
      |> Crypto.hmac("aws4_request")
  end

  def canonical_request(params, other_headers) do
    parsed_uri = URI.parse(params.invoke_lambda_url)

    [
      "POST",
      parsed_uri.path,
      parsed_uri.query || '',
      canonical_headers(other_headers),
      signed_headers(),
      content_sha256(),
    ]
      |> Enum.join("\n")
  end

  def canonical_headers(other_headers) when is_list(other_headers) do
    other_headers 
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

  def credential_scope(params) do
    [
      Utils.short_date(params.date),
      params.region,
      params.service,
      "aws4_request"
    ]
      |> Enum.join("/")
  end

  defp credential(params) do
    "#{params.credentials.aws_access_key}/#{credential_scope(params)}"
  end
end
