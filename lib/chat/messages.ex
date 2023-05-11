defmodule Chat.Messages do
  @moduledoc """
  The Messages context.
  """

  import Ecto.Query, warn: false
  alias Phoenix.Socket.Message
  alias Chat.Repo

  alias Chat.Messages.Message
  alias Chat.Channels.Channel

  @doc """
  Returns the list of messages.

  ## Examples

      iex> list_messages()
      [%Message{}, ...]

  """
  def list_messages(options \\ []) do
    default = [preload: [], channel: nil, limit: :infinit, offset: 0]

    options =
      Keyword.merge(default, options)
      |> Enum.into(%{})

    query =
      from m in Message,
        order_by: [desc: m.id],
        preload: ^options.preload,
        limit: ^options.limit,
        offset: ^options.offset

    query =
      case(options.channel) do
        %Channel{id: id} -> where(query, [m], m.channel_id == ^id)
        _ -> query
      end

    Repo.all(query)
  end

  def list_messages_with_user(channel = %Channel{} \\ %Channel{id: 1}),
    do:
      Repo.all(
        from m in Message,
          where: m.channel_id == ^channel.id,
          order_by: [desc: m.id],
          preload: [:user]
      )

  def list_messages_with_user_and_limit(limit),
    do: Repo.all(from m in Message, order_by: [desc: m.id], limit: ^limit, preload: [:user])

  def list_messages_with_user_and_limit_and_offset(limit, offset),
    do:
      Repo.all(
        from m in Message,
          order_by: [desc: m.id],
          limit: ^limit,
          offset: ^offset,
          preload: [:user]
      )

  @doc """
  Gets a single message.

  Raises `Ecto.NoResultsError` if the Message does not exist.

  ## Examples

      iex> get_message!(123)
      %Message{}

      iex> get_message!(456)
      ** (Ecto.NoResultsError)

  """
  def get_message!(id), do: Repo.get!(Message, id)

  @doc """
  Creates a message.

  ## Examples

      iex> create_message(%{field: value})
      {:ok, %Message{}}

      iex> create_message(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_message(attrs \\ %{}) do
    %Message{}
    |> Message.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a message.

  ## Examples

      iex> update_message(message, %{field: new_value})
      {:ok, %Message{}}

      iex> update_message(message, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_message(%Message{} = message, attrs) do
    message
    |> Message.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a message.

  ## Examples

      iex> delete_message(message)
      {:ok, %Message{}}

      iex> delete_message(message)
      {:error, %Ecto.Changeset{}}

  """
  def delete_message(%Message{} = message) do
    Repo.delete(message)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking message changes.

  ## Examples

      iex> change_message(message)
      %Ecto.Changeset{data: %Message{}}

  """
  def change_message(%Message{} = message, attrs \\ %{}) do
    Message.changeset(message, attrs)
  end
end
