defmodule Chat.SubMessages.SubMessage do
  use Ecto.Schema
  import Ecto.Changeset

  schema "sub_messages" do
    field :content, :string
    belongs_to :message, Chat.Messages.Message
    belongs_to :user, Chat.Accounts.User

    timestamps()
  end

  @doc false
  def changeset(sub_message, attrs) do
    sub_message
    |> cast(attrs, [:content, :message_id, :user_id])
    |> validate_required([:content, :message_id, :user_id])
  end
end
