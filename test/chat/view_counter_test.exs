defmodule Chat.ViewCounterTest do
  use Chat.DataCase

  alias Chat.ViewCounter

  describe "view_counts" do
    alias Chat.ViewCounter.ViewCount

    import Chat.ViewCounterFixtures

    @invalid_attrs %{counter: nil, date: nil, path: nil}
  end
end
