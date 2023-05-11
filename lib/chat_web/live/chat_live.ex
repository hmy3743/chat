defmodule ChatWeb.ChatLive do
  alias Chat.Channels
  alias ChatWeb.Presence
  alias Phoenix.PubSub
  alias Chat.Messages.Message
  alias Chat.Messages
  use ChatWeb, :live_view

  @pubsub Chat.PubSub
  @topic __MODULE__ |> Atom.to_string()
  @limit 30

  @impl Phoenix.LiveView
  def mount(params, _session, socket) do
    channel =
      params
      |> Map.get("channel", "default")
      |> Channels.get_channel_by_name!()

    form = %Message{} |> Messages.change_message() |> to_form()

    messages =
      Messages.list_messages(channel: channel, offset: 0, limit: @limit, preload: [:user])

    channels = Channels.list_channels()

    socket =
      socket
      |> assign(
        form: form,
        presences: refine_presences(Presence.list("#{@topic}/#{channel.name}")),
        channel: channel,
        channels: channels,
        limit: @limit,
        offset: 0,
        loading_done: false,
        loading: false
      )
      |> stream(:messages, refine_messages(messages))

    if connected?(socket) do
      :ok = PubSub.subscribe(@pubsub, "#{@topic}/#{channel.name}")

      Presence.track(
        self(),
        "#{@topic}/#{channel.name}",
        socket.assigns.current_user.id,
        socket.assigns.current_user
      )
    end

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <h1 class="text-4xl font-bold"># <%= @channel.name %></h1>
    <div class="p-1">
      <label for="channels"><span class="font-mono font-semibold">Channels</span></label>
      <div id="channels">
        <.link
          :for={channel <- @channels}
          navigate={~p"/chat/#{channel.name}"}
          class="inline-block bg-blue-200 rounded px-1 m-0.5"
        >
          <%= channel.name %>
        </.link>
      </div>
    </div>
    <div class="flex">
      <div class="p-1 m-1 border-2 border-dashed border-grey h-min sticky top-0">
        <h1 class="text-xl font-bold">
          접속 현황
        </h1>
        <ul class="p-0 m-0.5 max-w-md divide-y divide-gray-200 dark:divide-gray-700 border-dashed border-zinc-150 border-2">
          <li :for={{_id, user} <- @presences} class="border-none m-1">
            <div class="flex items-center space-x-4">
              <div class="flex-1 min-w-0">
                <div class="w-full h-1" style={background_color(user.color)}></div>
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
        <div class="sticky top-0 left-0 right-0">
          <.simple_form phx-submit="new-message" for={@form}>
            <div class="flex">
              <.input
                field={@form[:content]}
                phx-hook="InputCleanUp"
                placeholder="Type here"
                autocomplete="off"
              />
              <button
                class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded focus:outline-none focus:shadow-outline"
                type="submit"
              >
                Submit
              </button>
            </div>
          </.simple_form>
        </div>
        <div class="mt-5 overflow-scroll">
          <div id="message-container" phx-update="stream">
            <div :for={{id, message} <- @streams.messages} id={id} class="m-1 p-1 shadow-lg flex">
              <div class="w-1" style={background_color(message.user.color)}></div>
              <span style="width: 140px;" class="inline-block bg-gray-200 rounded-3xl px-3 py-1">
                <%= message.user.email %>
              </span>
              <span style="max-width: 350px;" class="p-1">
                <%= message.content %>
              </span>
            </div>
          </div>
          <%= if assigns.loading do %>
            <!-- Skeleton Loading -->
            <div :for={_ <- 1..30 |> Enum.to_list()} class="p-2">
              <div class="animate-pulse flex space-x-4">
                <div class="flex-1 space-y-6 py-1">
                  <div class="space-y-3">
                    <div class="grid grid-cols-3 gap-4">
                      <div class="h-2 bg-slate-400 rounded col-span-1"></div>
                      <div class="h-2 bg-slate-400 rounded col-span-2"></div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          <% end %>
          <%= if !@loading_done do %>
            <div id="infinite-scroll-marker" phx-hook="InfiniteScroll"></div>
          <% end %>
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
      |> Map.put("channel_id", socket.assigns.channel.id)
      |> Messages.create_message()

    case result do
      {:ok, message} ->
        PubSub.broadcast!(
          @pubsub,
          "#{@topic}/#{socket.assigns.channel.name}",
          {:new_message, message, socket.assigns.current_user}
        )

        {:noreply, assign(socket, form: to_form(Messages.change_message(%Message{})))}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  def handle_event("load-more", _params, socket) do
    channel = socket.assigns.channel
    new_offset = socket.assigns.offset + @limit

    messages =
      Messages.list_messages(
        channel: channel,
        limit: @limit,
        offset: new_offset,
        preload: [:user]
      )

    socket =
      socket
      |> stream_insert_many_messages(:messages, messages)
      |> assign(loading_done: length(messages) == 0)

    {:noreply, assign(socket, offset: new_offset, loading: false)}
  end

  @impl Phoenix.LiveView
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

  def handle_info({:new_message, message, sender}, socket) do
    message = Map.put(message, :user, sender)

    socket =
      socket
      |> stream_insert(:messages, refine_message(message), at: 0)

    {:noreply, socket}
  end

  def handle_info(
        %{event: "presence_diff", payload: %{joins: joins, leaves: leaves}},
        socket
      ) do
    socket =
      socket
      |> apply_leaves(leaves)
      |> apply_joins(joins)

    {:noreply, socket}
  end

  defp stream_insert_many_messages(socket, name, messages) do
    Enum.reduce(messages, socket, fn message, acc ->
      Phoenix.LiveView.stream_insert(acc, name, refine_message(message), at: -1)
    end)
  end

  defp refine_presences(presences) do
    Enum.into(presences, %{}, &refine_presence/1)
  end

  defp refine_presence({id, %{metas: [user | _]}}) do
    {id, Map.put(user, :color, user_color(user))}
  end

  defp refine_messages(messages) do
    Enum.map(messages, &refine_message/1)
  end

  defp refine_message(message) do
    update_in(message.user, &Map.put(&1, :color, user_color(&1)))
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

  defp user_color(user) do
    seed = :erlang.phash2(user.email)

    r = seed |> Kernel.+(0) |> rem(256)
    g = seed |> Kernel.+(64) |> rem(256)
    b = seed |> Kernel.+(128) |> rem(256)

    %{r: r, g: g, b: b, a: 0.8}
  end

  defp background_color(color) do
    "background-color: rgba(#{color.r}, #{color.g}, #{color.b}, #{color.a})"
  end
end
