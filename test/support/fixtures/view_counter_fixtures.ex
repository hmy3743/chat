defmodule Chat.ViewCounterFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Chat.ViewCounter` context.
  """

  @doc """
  Generate a view_count.
  """
  def view_count_fixture(attrs \\ %{}) do
    {:ok, view_count} =
      attrs
      |> Enum.into(%{
        counter: 42,
        date: ~D[2023-05-14],
        path: "some path"
      })
      |> Chat.ViewCounter.create_view_count()

    view_count
  end
end
