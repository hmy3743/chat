defmodule Chat.Repo.Migrations.AddChannelIdIndexToMessages do
  use Ecto.Migration

  def change do
    create index("messages", [:channel_id], using: :hash)
  end
end
