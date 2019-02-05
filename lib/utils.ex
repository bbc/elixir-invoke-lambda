defmodule Utils do
  def short_date(date) do
    # current_date_time
  end
  
  def date_iso8601(date) do
    date |> DateTime.truncate(:seconds) |> DateTime.to_iso8601
  end
end
