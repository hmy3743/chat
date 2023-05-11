defmodule Chat.Repo.Migrations.ModifyContentInMessages do
  use Ecto.Migration

  def change do
    alter table("messages") do
      modify :content, :string, null: false, size: 1024
    end
  end
end
