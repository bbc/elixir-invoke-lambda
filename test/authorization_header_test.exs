defmodule AuthorizationHeaderTest do
  use ExUnit.Case

  import Mock

  test "canonical_headers/1" do
    expected = "host:example.com\nx-amz-date:20150325T105958Z\n"
    
    headers = Map.new
    |> Map.put("X-Amz-Date", "20150325T105958Z")
    |> Map.put("Host", "example.com")

    assert expected == AuthorizationHeader.canonical_headers(headers)
  end

  test "canonical_request/2" do
    expected = Enum.join(
      ["POST", "/", "", "host:example.com",
       "x-amz-date:20150325T105958Z", "", "host;x-amz-date",
       "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"],
      "\n")

      headers = Map.new
      |> Map.put("X-Amz-Date", "20150325T105958Z")
      |> Map.put("Host", "example.com")

    actual = AuthorizationHeader.canonical_request("https://example.com/", headers)
    assert expected == actual
  end

  test "credential_scope/1" do
    {:ok, date, _} = DateTime.from_iso8601 "2019-02-06T08:43:09.961127Z"
    expected = "20190206/eu-west-1/lambda/aws4_request"
    assert expected == AuthorizationHeader.credential_scope(date)
  end

  test "string_to_sign/2" do
    {:ok, date, _} = DateTime.from_iso8601 "2019-02-06T08:43:09.961127Z"
    long_date = Utils.date_in_iso8601(date)

    headers = Map.new
    |> Map.put("X-Amz-Date", long_date)
    |> Map.put("Host", "example.com")

    credential_scope = "20190206/eu-west-1/lambda/aws4_request"

    lambda_invoke_url = "https://lambda.eu-west-1.amazonaws.com/2015-03-31/functions/ingress-hello-world/invocations"
    canonical_request = AuthorizationHeader.canonical_request(lambda_invoke_url, headers)
    IO.puts "canonical_request:"
    IO.puts canonical_request
    hashed_canonical_request = Crypto.sha256(canonical_request) |> Crypto.hex

    actual = AuthorizationHeader.string_to_sign(date, canonical_request)
    expected = Enum.join(["AWS4-HMAC-SHA256", long_date, credential_scope, hashed_canonical_request], "\n")
    IO.puts expected

    assert expected == actual
  end

  test "signing_key/1" do
    with_mock Config, [
      aws_secret_key: fn -> "secret-access-key" end,
      region:         fn -> "us-east-1" end,
      service:         fn -> "s3" end
    ] do
      {:ok, date, _} = DateTime.from_iso8601 "2015-03-26T08:43:09.961127Z"
      expected =  <<108, 238, 174, 127,  62,  29, 151, 251,
                  60,  200, 152, 110,  95, 108, 195, 104,
                  208, 222,  84, 216, 129,  34, 102, 127,
                  208,  93,  22,  61,  71,  54, 199, 206>>

      actual = AuthorizationHeader.signing_key(date)  
      assert expected == actual
    end
  end
end
