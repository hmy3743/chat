defmodule Chat.SubMessagesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Chat.SubMessages` context.
  """

  @doc """
  Generate a sub_message.
  """
  def sub_message_fixture(attrs \\ %{}) do
    {:ok, sub_message} =
      attrs
      |> Enum.into(%{
        content: "some content"
      })
      |> Chat.SubMessages.create_sub_message()

    sub_message
  end
end
