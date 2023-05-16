defmodule Chat.SubMessages do
  @moduledoc """
  The SubMessages context.
  """

  import Ecto.Query, warn: false
  alias Chat.Repo

  alias Chat.SubMessages.SubMessage

  @doc """
  Returns the list of sub_messages.

  ## Examples

      iex> list_sub_messages()
      [%SubMessage{}, ...]

  """
  def list_sub_messages do
    Repo.all(SubMessage)
  end

  @doc """
  Gets a single sub_message.

  Raises `Ecto.NoResultsError` if the Sub message does not exist.

  ## Examples

      iex> get_sub_message!(123)
      %SubMessage{}

      iex> get_sub_message!(456)
      ** (Ecto.NoResultsError)

  """
  def get_sub_message!(id), do: Repo.get!(SubMessage, id)

  @doc """
  Creates a sub_message.

  ## Examples

      iex> create_sub_message(%{field: value})
      {:ok, %SubMessage{}}

      iex> create_sub_message(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_sub_message(attrs \\ %{}) do
    %SubMessage{}
    |> SubMessage.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a sub_message.

  ## Examples

      iex> update_sub_message(sub_message, %{field: new_value})
      {:ok, %SubMessage{}}

      iex> update_sub_message(sub_message, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_sub_message(%SubMessage{} = sub_message, attrs) do
    sub_message
    |> SubMessage.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a sub_message.

  ## Examples

      iex> delete_sub_message(sub_message)
      {:ok, %SubMessage{}}

      iex> delete_sub_message(sub_message)
      {:error, %Ecto.Changeset{}}

  """
  def delete_sub_message(%SubMessage{} = sub_message) do
    Repo.delete(sub_message)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking sub_message changes.

  ## Examples

      iex> change_sub_message(sub_message)
      %Ecto.Changeset{data: %SubMessage{}}

  """
  def change_sub_message(%SubMessage{} = sub_message, attrs \\ %{}) do
    SubMessage.changeset(sub_message, attrs)
  end
end
