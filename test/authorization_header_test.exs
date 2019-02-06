defmodule AuthorizationHeaderTest do

  alias InvokeLambda.{AuthorizationHeader, Config, Utils, Crypto}

  use ExUnit.Case

  import Mock

  def example_headers do
    [
      {"host",  "example.com"},
      {"X-Amz-Date", "20150325T105958Z"},
    ]
  end

  test "canonical_headers/1 with valid headers" do
    expected = "host:example.com\nx-amz-date:20150325T105958Z\n"
    
    assert expected == AuthorizationHeader.canonical_headers(example_headers())
  end

  test "canonical_headers/1 filters out invalid headers" do
    expected = "host:example.com\nx-amz-date:20150325T105958Z\n"
    headers = example_headers() ++ [{"content-type", "application/json"}]

    assert expected == AuthorizationHeader.canonical_headers(headers)
  end

  test "canonical_request/2" do
    expected = Enum.join(
      ["POST", "/", "", "host:example.com",
       "x-amz-date:20150325T105958Z", "", "host;x-amz-date",
       "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"],
      "\n")
    actual = AuthorizationHeader.canonical_request("https://example.com/", example_headers())

    assert expected == actual
  end

  test "credential_scope/2" do
    {:ok, date, _} = DateTime.from_iso8601 "2019-02-06T08:43:09.961127Z"
    expected = "20190206/eu-west-1/lambda/aws4_request"

    assert expected == AuthorizationHeader.credential_scope(date, "eu-west-1")
  end

  test "string_to_sign/3" do
    {:ok, date, _} = DateTime.from_iso8601 "2019-02-06T08:43:09.961127Z"
    long_date = Utils.date_in_iso8601(date)

    headers = [
      {"Host",  "example.com"},
      {"X-Amz-Date", long_date},
    ]

    credential_scope = "20190206/eu-west-1/lambda/aws4_request"
    invoke_lambda_url = "https://lambda.eu-west-1.amazonaws.com/2015-03-31/functions/ingress-hello-world/invocations"
    canonical_request = AuthorizationHeader.canonical_request(invoke_lambda_url, headers)
    hashed_canonical_request = Crypto.sha256(canonical_request) |> Crypto.hex

    actual = AuthorizationHeader.string_to_sign("eu-west-1", date, canonical_request)
    expected = Enum.join(["AWS4-HMAC-SHA256", long_date, credential_scope, hashed_canonical_request], "\n")

    assert expected == actual
  end

  test "signing_key/2" do
    with_mock Config, [
      aws_secret_key: fn -> "secret-access-key" end
    ] do
      {:ok, date, _} = DateTime.from_iso8601 "2015-03-26T08:43:09.961127Z"
      expected =  <<244, 225, 119, 75, 253, 57, 203, 17, 224, 217, 134, 83, 15, 42,
      180, 4, 254, 5, 107, 232, 23, 122, 68, 204, 248, 146, 206, 86, 9,
      85, 17, 229>>

      actual = AuthorizationHeader.signing_key(date, "eu-west-1")
      assert expected == actual
    end
  end
end
