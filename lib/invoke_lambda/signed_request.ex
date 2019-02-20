defmodule InvokeLambda.SignedRequest do
  @aws_endpoint_version "2015-03-31"

  alias InvokeLambda.{Utils, AuthorizationHeader}

  def send(
        %{
          body: _,
          service: _,
          credentials: _
        } = options
      ) do
    params =
      options
      |> put_url
      |> put_region
      |> encode_url
      |> put_date
      |> encode_signed_request_payload
      |> put_headers

    HTTPoison.post(
      params.url,
      params.body,
      params.headers,
      [recv_timeout: 15000, timeout: 15000]
    )
    |> format_response
  end

  defp put_region(%{service: :sts} = params) do
    params
    |> Map.put(:region, "us-east-1")
  end

  defp put_region(%{service: :lambda} = params), do: params

  defp put_url(%{service: :sts} = params) do
    params
    |> Map.put(:url, "https://sts.amazonaws.com/")
  end

  defp put_url(%{service: :lambda} = params) do
    params
    |> Map.put(
      :url,
      "https://lambda.#{params.region}.amazonaws.com/#{@aws_endpoint_version}/functions/#{
        params.function_name
      }/invocations"
    )
  end

  defp format_response({_, request_response}) do
    {request_response.status_code, Poison.decode!(request_response.body)}
  end

  defp encode_url(params) do
    params
    |> Map.put(:url, URI.encode(params.url))
  end

  def encode_signed_request_payload(%{service: :sts} = params) do

    body = [
      "Version=2011-06-15",
      "RoleSessionName=lambda-access",
      "RoleArn=#{params.lambda_role_arn}",
      "Action=AssumeRole"
    ] |> Enum.join("&")

    params
    |> Map.put(:body, body)
  end

  def encode_signed_request_payload(%{service: :lambda} = params) do
    params
    |> Map.put(:body, Poison.encode!(params.body))
  end

  defp put_headers(params) do
    params
    |> Map.put(:headers, build_headers(params))
  end

  defp build_headers(params) do
    params
    |> build_base_headers
    |> add_auth_headers(params)
  end


  defp build_base_headers(%{service: :sts} = params) do
    parsed_uri = URI.parse(params.url)

    [
      {"accept", "application/json"},
      {"content-type", "application/x-www-form-urlencoded; charset=utf-8"},
      {"content-length", byte_size(params.body)},
      {"host", parsed_uri.host},
      {"x-amz-date", Utils.date_in_iso8601(params.date)}
    ]
  end

  defp build_base_headers(%{service: :lambda} = params) do
    parsed_uri = URI.parse(params.url)

    [
      {"content-type", "application/json"},
      {"host", parsed_uri.host},
      {"x-amz-date", Utils.date_in_iso8601(params.date)}
    ]
  end

  defp put_date(params), do: Map.put(params, :date, DateTime.utc_now())

  defp add_auth_headers(base_headers, params) do
    authorization = AuthorizationHeader.build(params, base_headers)

    base_headers ++
      [
        {"authorization", authorization},
        {"x-amz-security-token", params.credentials.aws_token}
      ]
  end
end
