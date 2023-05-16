defmodule Chat.Repo.Migrations.CreateSubMessages do
  use Ecto.Migration

  def change do
    create table(:sub_messages) do
      add :content, :string
      add :message_id, references(:messages), null: false
      add :user_id, references(:users), null: false

      timestamps()
    end
  end
end
