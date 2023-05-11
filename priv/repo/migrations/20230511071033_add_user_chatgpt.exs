defmodule Chat.Repo.Migrations.AddUserChatgpt do
  use Ecto.Migration

  alias Chat.Repo
  alias Chat.Accounts.User

  def change do
    Repo.insert!(%User{
      id: 0,
      email: "chatgpt@open.ai",
      hashed_password: :crypto.strong_rand_bytes(16) |> inspect()
    })
  end
end
