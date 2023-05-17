defmodule Chat.SubMessages.LastSubMessage do
  use Ecto.Schema

  schema "last_sub_messages" do
    field(:content, :string)
    belongs_to(:message, Chat.Messages.Message)
    belongs_to(:user, Chat.Accounts.User)

    timestamps()
  end
end
