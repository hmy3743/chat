defmodule Chat.Repo.Migrations.InsertAidkrChannel do
  use Ecto.Migration

  alias Chat.Repo
  alias Chat.Channels.Channel

  def change do
    Repo.transaction(fn ->
      Repo.insert!(%Channel{id: 1, name: "default"})
      Repo.insert!(%Channel{id: 2, name: "aidkr"})
      execute "SELECT setval('channels_id_seq', (SELECT MAX(id) from \"channels\"));"
    end)
  end
end
