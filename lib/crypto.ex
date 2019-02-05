defmodule Crypto do
  def hmac do
    :crypto.hmac(:sha256, "key", "hash me")
    |> Base.encode16()
  end
end
