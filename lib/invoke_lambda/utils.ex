defmodule InvokeLambda.Utils do
  def short_date(date) do
    date_in_iso8601(date)
    |> String.slice(0, 8)
  end

  def date_in_iso8601(date) do
    iso_date = date |> DateTime.truncate(:second) |> DateTime.to_iso8601()
    iso_date = String.replace(iso_date, "-", "")
    String.replace(iso_date, ":", "")
  end
end
