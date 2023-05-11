defmodule Chat.Repo.Migrations.AddChannelIdToMessagesTable do
  use Ecto.Migration

  def change do
    alter table("messages") do
      add :channel_id, references(:channels), null: false, default: 1
    end
  end
end
