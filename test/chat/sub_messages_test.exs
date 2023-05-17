defmodule Chat.SubMessagesTest do
  use Chat.DataCase

  alias Chat.SubMessages

  describe "sub_messages" do
    alias Chat.SubMessages.SubMessage

    import Chat.SubMessagesFixtures

    @invalid_attrs %{content: nil}

    @tag fixtures: [:user, :channel, :message, :sub_message]
    test "list_sub_messages/0 returns all sub_messages", %{fixtures: fixtures} do
      %{sub_message: sub_message} = fixtures
      assert SubMessages.list_sub_messages() == [sub_message]
    end

    @tag fixtures: [:user, :channel, :message, :sub_message]
    test "get_sub_message!/1 returns the sub_message with given id", %{fixtures: fixtures} do
      %{sub_message: sub_message} = fixtures
      assert SubMessages.get_sub_message!(sub_message.id) == sub_message
    end

    @tag fixtures: [:user, :channel, :message]
    test "create_sub_message/1 with valid data creates a sub_message", %{fixtures: fixtures} do
      valid_attrs = %{
        content: "some content",
        user_id: fixtures.user.id,
        message_id: fixtures.message.id
      }

      assert {:ok, %SubMessage{} = sub_message} = SubMessages.create_sub_message(valid_attrs)
      assert sub_message.content == "some content"
    end

    test "create_sub_message/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = SubMessages.create_sub_message(@invalid_attrs)
    end

    @tag fixtures: [:user, :channel, :message, :sub_message]
    test "update_sub_message/2 with valid data updates the sub_message", %{fixtures: fixtures} do
      sub_message = fixtures.sub_message
      update_attrs = %{content: "some updated content"}

      assert {:ok, %SubMessage{} = sub_message} =
               SubMessages.update_sub_message(sub_message, update_attrs)

      assert sub_message.content == "some updated content"
    end

    @tag fixtures: [:user, :channel, :message, :sub_message]
    test "update_sub_message/2 with invalid data returns error changeset", %{fixtures: fixtures} do
      sub_message = fixtures.sub_message

      assert {:error, %Ecto.Changeset{}} =
               SubMessages.update_sub_message(sub_message, @invalid_attrs)

      assert sub_message == SubMessages.get_sub_message!(sub_message.id)
    end

    @tag fixtures: [:user, :channel, :message, :sub_message]
    test "delete_sub_message/1 deletes the sub_message", %{fixtures: fixtures} do
      sub_message = fixtures.sub_message
      assert {:ok, %SubMessage{}} = SubMessages.delete_sub_message(sub_message)
      assert_raise Ecto.NoResultsError, fn -> SubMessages.get_sub_message!(sub_message.id) end
    end

    @tag fixtures: [:user, :channel, :message, :sub_message]
    test "change_sub_message/1 returns a sub_message changeset", %{fixtures: fixtures} do
      sub_message = fixtures.sub_message
      assert %Ecto.Changeset{} = SubMessages.change_sub_message(sub_message)
    end
  end
end
