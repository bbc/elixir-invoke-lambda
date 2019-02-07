defmodule UtilsTest do
  alias InvokeLambda.{Utils}
  use ExUnit.Case

  test "short_date/1" do
    {:ok, date, _} = DateTime.from_iso8601 "2019-02-06T08:43:09.961127Z"

    assert "20190206" == Utils.short_date(date)
  end

  test "date_in_iso8601/1" do
    {:ok, date, _} = DateTime.from_iso8601 "2019-02-06T08:43:09.961127Z"

    assert "20190206T084309Z" == Utils.date_in_iso8601(date)
  end
end
