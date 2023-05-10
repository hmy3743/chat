defmodule ChatWeb.ChatLive do
  alias ChatWeb.Presence
  alias Phoenix.PubSub
  alias Chat.Messages.Message
  alias Chat.Messages
  use ChatWeb, :live_view

  @pubsub Chat.PubSub
  @topic __MODULE__ |> Atom.to_string()

  @impl Phoenix.LiveView
  def mount(_param, _session, socket) do
    form = %Message{} |> Messages.change_message() |> to_form()

    messages = Messages.list_messages_with_user()

    socket =
      socket
      |> assign(form: form, presences: refine_presences(Presence.list(@topic)))
      |> stream(:messages, messages)

    if connected?(socket) do
      :ok = PubSub.subscribe(@pubsub, @topic)
      Presence.track(self(), @topic, socket.assigns.current_user.id, socket.assigns.current_user)
    end

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="flex">
      <div class="p-1 m-1 border-2 border-dashed border-grey">
        <h1 class="text-xl font-bold">
          접속 현황
        </h1>
        <ul
          :for={{_id, user} <- @presences}
          class="p-1 m-0.5 max-w-md divide-y divide-gray-200 dark:divide-gray-700 border-dashed border-zinc-150 border-2"
        >
          <li>
            <div class="flex items-center space-x-4">
              <div class="flex-1 min-w-0">
                <p class="text-sm font-medium text-gray-900 truncate dark:text-white">
                  <%= name_from_email(user.email) %>
                </p>
                <p class="text-sm text-gray-500 truncate dark:text-gray-400">
                  <%= user.email %>
                </p>
              </div>
            </div>
          </li>
        </ul>
      </div>
      <div class="w-full m-1">
        <.form phx-submit="new-message" for={@form} class="flex">
          <.input field={@form[:content]} placeholder="Type here" />
          <button
            class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded focus:outline-none focus:shadow-outline"
            type="submit"
          >
            Submit
          </button>
        </.form>
        <div id="message-container" class="mt-5" phx-update="stream">
          <div :for={{id, message} <- @streams.messages} id={id} class="m-1 p-1 shadow-lg">
            <span class="inline-block bg-gray-200 rounded-full px-3 py-1">
              <%= message.user.email %>
            </span>
            <span class="p-1">
              <%= message.content %>
            </span>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl Phoenix.LiveView
  def handle_event("new-message", %{"message" => message}, socket) do
    result =
      message
      |> Map.put("user_id", socket.assigns.current_user.id)
      |> Messages.create_message()

    case result do
      {:ok, message} ->
        PubSub.broadcast!(@pubsub, @topic, {:new_message, message, socket.assigns.current_user})
        {:noreply, assign(socket, form: to_form(Messages.change_message(%Message{})))}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  @impl Phoenix.LiveView
  def handle_info({:new_message, message, sender}, socket) do
    message = Map.put(message, :user, sender)

    socket =
      socket
      |> stream_insert(:messages, message, at: 0)

    {:noreply, socket}
  end

  def handle_info(
        %{topic: @topic, event: "presence_diff", payload: %{joins: joins, leaves: leaves}},
        socket
      ) do
    socket =
      socket
      |> apply_leaves(leaves)
      |> apply_joins(joins)

    {:noreply, socket}
  end

  defp refine_presences(presences) do
    Enum.into(presences, %{}, fn {id, %{metas: [user | _]}} -> {id, user} end)
  end

  defp apply_leaves(socket, leaves) do
    update(socket, :presences, &Map.drop(&1, Map.keys(leaves)))
  end

  defp apply_joins(socket, joins) do
    update(socket, :presences, &Map.merge(&1, refine_presences(joins)))
  end

  defp name_from_email(email) do
    email |> String.split("@") |> hd()
  end
end
