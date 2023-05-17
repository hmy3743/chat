defmodule Chat.Messages.Message do
  use Ecto.Schema
  import Ecto.Changeset
  alias Chat.SubMessages.{SubMessage, LastSubMessage}

  schema "messages" do
    field(:content, :string)
    belongs_to(:user, Chat.Accounts.User)
    belongs_to(:channel, Chat.Channels.Channel, define_field: false)
    field(:channel_id, :integer, read_after_writes: true)
    has_many(:sub_messages, SubMessage)
    has_one(:last_sub_message, LastSubMessage)

    field(:sub_message_form, :any, virtual: true)
    field(:is_thread_open, :boolean, virtual: true, default: false)

    timestamps()
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:content, :user_id, :channel_id])
    |> validate_required([:content])
  end
end
