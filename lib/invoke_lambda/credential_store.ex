defmodule InvokeLambda.CredentialStore do
  def retrieve_for_role(role) do
    try do
      role
      |> meta_data_endpoint
      |> HTTPoison.get!()
      |> format_response
    rescue
      error -> {:error, error}
    end
  end

  defp format_response(response) do
    response.body
    |> Poison.decode!()
    |> standardise_keys
  end

  defp standardise_keys(decoded_response_body) do
    {
      :ok,
      %{
        aws_access_key: decoded_response_body["AccessKeyId"],
        aws_secret_key: decoded_response_body["SecretAccessKey"],
        aws_token: decoded_response_body["Token"]
      }
    }
  end

  defp meta_data_endpoint(role) do
    "http://169.254.169.254/latest/meta-data/iam/security-credentials/#{role}"
  end
end
