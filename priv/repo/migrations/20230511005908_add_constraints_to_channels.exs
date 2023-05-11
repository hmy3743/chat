defmodule Chat.Repo.Migrations.AddConstraintsToChannels do
  use Ecto.Migration

  def change do
    alter table("channels") do
      modify :name, :string, null: false
    end

    create index("channels", [:name], unique: true)
  end
end
