defmodule Chat.Repo.Migrations.InsertAidkrChannel do
  use Ecto.Migration

  alias Chat.Repo
  alias Chat.Channels.Channel

  def change do
    Repo.transaction(fn ->
      Repo.insert!(%Channel{id: 1, name: "default"})
      Repo.insert!(%Channel{id: 2, name: "aidkr"})
    end)
  end
end
