defmodule Chat.Repo.Migrations.AddConstraintsToMessages do
  use Ecto.Migration

  def change do
    drop constraint("messages", "messages_user_id_fkey")

    alter table("messages") do
      modify :content, :string, null: false
      modify :user_id, references(:users), null: false
    end
  end
end
