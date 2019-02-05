defmodule Crypto do
  def hmac(key, value) do
    :crypto.hmac(:sha256, key, value)
  end

  def sha256(value) do
    :crypto.hash(:sha256, value)
  end

  def hex(string) do
    string |> Base.encode16
  end
end
