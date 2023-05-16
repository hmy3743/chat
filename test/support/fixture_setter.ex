defmodule Chat.FixtureSetter do
  import Chat.{
    AccountsFixtures,
    ChannelsFixtures,
    MessagesFixtures,
    SubMessagesFixtures
  }

  def setup(%{fixtures: requests} = context) do
    fixtures =
      Enum.reduce(
        requests,
        %{},
        fn
          {name, options}, fixtures ->
            apply(__MODULE__, name, [fixtures | [options]])

          name, fixtures ->
            apply(__MODULE__, name, [fixtures])
        end
      )

    %{context | fixtures: fixtures}
  end

  # no fixtures tag
  def setup(context), do: context

  def user(fixtures, options \\ []) do
    %{key: key} = options_to_map(options, key: :user)

    fixtures
    |> put_in([key], user_fixture())
  end

  def channel(fixtures, options \\ []) do
    %{key: key, name: name} =
      options_to_map(
        options,
        key: :channel,
        name: "test_channel"
      )

    fixtures
    |> put_in([key], channel_fixture(%{name: name}))
  end

  def message(fixtures, options \\ []) do
    %{key: key, content: content, user_key: user_key, channel_key: channel_key} =
      options_to_map(
        options,
        key: :message,
        content: "test content",
        user_key: :user,
        channel_key: :channel
      )

    %{id: user_id} = get_in(fixtures, [user_key])
    %{id: channel_id} = get_in(fixtures, [channel_key])

    fixtures
    |> put_in(
      [key],
      message_fixture(%{
        content: content,
        user_id: user_id,
        channel_id: channel_id
      })
    )
  end

  def sub_message(fixtures, options \\ []) do
    %{key: key, content: content, message_key: message_key, user_key: user_key} =
      options_to_map(
        options,
        key: :sub_message,
        content: "test message",
        message_key: :message,
        user_key: :user
      )

    %{id: message_id} = get_in(fixtures, [message_key])
    %{id: user_id} = get_in(fixtures, [user_key])

    fixtures
    |> put_in(
      [key],
      sub_message_fixture(%{
        content: content,
        message_id: message_id,
        user_id: user_id
      })
    )
  end

  defp options_to_map(keyword, default) do
    Keyword.merge(default, keyword)
    |> Enum.into(%{})
  end
end
