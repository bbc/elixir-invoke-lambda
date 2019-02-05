defmodule LambdaAuth do
  def header do
    [
      "Credential=#{credential()}",
      "SignedHeaders=#{signed_headers()}",
      "Signature=#{signature()}"
    ]
    |> Enum.join(", ")
  end

  defp credential do
    [
      aws_access_key(),
      short_date(),
      region(),
      "lambda",
      "aws4_request"
    ]
    |> Enum.join("/")
  end

  defp signed_headers do
    "host;x-amz-date"
  end

  defp signature do
    # 1. signing key: https://github.com/aws/aws-sdk-js/blob/cc29728c1c4178969ebabe3bbe6b6f3159436394/lib/signers/v4_credentials.js#L54
    # 2. Hmac hash signing key
    "signature"
  end

  defp region do
    "eu-west-1"
  end

  defp short_date do
    # YYYYMMDD
    "20190204"
  end

  defp aws_access_key do
    "access"
  end

  defp aws_secret_key do
    "secret"
  end
end
