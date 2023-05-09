defmodule ChatWeb.ChatLive do
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
      |> assign(form: form)
      |> stream(:messages, messages)

    if connected?(socket) do
      :ok = PubSub.subscribe(@pubsub, @topic)
    end

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.form phx-submit="new-message" for={@form} class="flex">
      <.input field={@form[:content]} placeholder="Type here" />
      <button
        class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded focus:outline-none focus:shadow-outline"
        type="submit"
      >
        Submit
      </button>
    </.form>
    <div id="message-container" class="m-1 mt-5" phx-update="stream">
      <div :for={{id, message} <- @streams.messages} id={id} class="m-1 p-1 shadow-lg">
        <span class="inline-block bg-gray-200 rounded-full px-3 py-1">
          <%= message.user.email %>
        </span>
        <span class="p-1">
          <%= message.content %>
        </span>
      </div>
    </div>
    """
  end

  @impl Phoenix.LiveView
  def handle_event("new-message", %{"message" => message}, socket) do
    {:ok, message} =
      message
      |> Map.put("user_id", socket.assigns.current_user.id)
      |> Messages.create_message()

    PubSub.broadcast!(@pubsub, @topic, {:new_message, message, socket.assigns.current_user})

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_info({:new_message, message, sender}, socket) do
    message = Map.put(message, :user, sender)

    socket =
      socket
      |> stream_insert(:messages, message)

    {:noreply, socket}
  end
end
