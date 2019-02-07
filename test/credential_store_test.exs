defmodule CredentialStoreTest do
  use ExUnit.Case
  import Mock

  alias InvokeLambda.CredentialStore

  @role TestHelper.example_role_name()

  test "makes a request for the credentials when given a role" do
    with_mocks([
      {HTTPoison, [], [get!: fn _ -> TestHelper.expected_meta_data_response() end]}
    ]) do
      result = CredentialStore.retrieve_for_role(@role)

      expected_result = %{
        aws_access_key: "aws-access-key",
        aws_secret_key: "aws-secret-key",
        aws_token: "aws-token"
      }

      assert_called(HTTPoison.get!(TestHelper.expected_meta_data_url(@role)))
      assert result == expected_result
    end
  end
end
