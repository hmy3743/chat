defmodule Chat.ViewCounter.ViewCount do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "view_counts" do
    field :counter, :integer, default: 0
    field :date, :date, primary_key: true
    field :path, :string, primary_key: true
  end

  @doc false
  def changeset(view_count, attrs) do
    view_count
    |> cast(attrs, [:date, :path, :counter])
    |> validate_required([:date, :path, :counter])
  end
end
