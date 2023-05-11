defmodule Chat.ChannelsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Chat.Channels` context.
  """

  @doc """
  Generate a channel.
  """
  def channel_fixture(attrs \\ %{}) do
    {:ok, channel} =
      attrs
      |> Enum.into(%{
        name: "some name"
      })
      |> Chat.Channels.create_channel()

    channel
  end
end
