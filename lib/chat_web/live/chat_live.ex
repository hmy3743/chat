defmodule ChatWeb.ChatLive do
  alias Chat.SubMessages
  alias Chat.Channels
  alias ChatWeb.Presence
  alias Phoenix.PubSub
  alias Chat.Messages.Message
  alias Chat.Messages
  alias Chat.ChatGptClient
  alias Chat.Accounts.User

  use ChatWeb, :live_view

  @pubsub Chat.PubSub
  @topic __MODULE__ |> Atom.to_string()
  @limit 30
  @chatGPT %User{id: 0, email: "chatgpt@open.ai"}

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    form = %Message{} |> Messages.change_message() |> to_form()

    channels = Channels.list_channels()

    socket =
      socket
      |> assign(
        form: form,
        channels: channels,
        chat_gpt_token: ""
      )

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(param, _uri, socket) do
    channel_name = Map.get(param, "channel", "default")
    channel = Channels.get_channel_by_name!(channel_name)

    if connected?(socket) do
      # unsubscribe previous channel
      if prv_channel = Map.get(socket.assigns, :channel) do
        PubSub.unsubscribe(@pubsub, "#{@topic}/#{prv_channel.name}")
        Presence.untrack(self(), "#{@topic}/#{prv_channel.name}", socket.assigns.current_user.id)
      end

      :ok = PubSub.subscribe(@pubsub, "#{@topic}/#{channel.name}")

      Presence.track(
        self(),
        "#{@topic}/#{channel.name}",
        socket.assigns.current_user.id,
        %{user: socket.assigns.current_user, is_typing: false}
      )
    end

    messages =
      Messages.list_messages(channel: channel, offset: 0, limit: @limit, preload: [:user])

    socket =
      socket
      |> assign(
        channel: channel,
        presences: refine_presences(Presence.list("#{@topic}/#{channel.name}")),
        limit: @limit,
        offset: 0,
        loading_done: false,
        loading: false,
        is_typing: false,
        typing_users: []
      )
      |> stream(:messages, refine_messages(messages), reset: true)

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <h1 class="text-4xl font-bold"># <%= @channel.name %></h1>
    <.chat_gpt_token_input chat_gpt_token={@chat_gpt_token} />
    <div class="p-1">
      <label for="channels"><span class="font-mono font-semibold">Channels</span></label>
      <div id="channels">
        <.link
          :for={channel <- @channels}
          patch={~p"/chat/#{channel.name}"}
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
                phx-update="ignore"
                placeholder="Type here"
                phx-hook="MessageInput"
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
          <%= if @typing_users |> length > 0 do %>
            <ul>
              <%= @typing_users
              |> Enum.map(fn user -> user.email end)
              |> Enum.join(", ")
              |> Kernel.<>(" is typing...") %>
            </ul>
          <% end %>
        </div>
        <div class="mt-5">
          <div id="message-container" phx-update="stream">
            <.message_card :for={{id, message} <- @streams.messages} id={id} message={message} />
          </div>
          <.skeleton_loading display={@loading} />
          <%= if !@loading_done do %>
            <div id="infinite-scroll-marker" phx-hook="InfiniteScroll"></div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  attr(:chat_gpt_token, :string, required: true)

  def chat_gpt_token_input(assigns) do
    ~H"""
    <div class="m-1">
      <label for="chatGTPToken" class="text-s"> ChatGPT token: </label>
      <input
        id="chatGTPToken"
        value={@chat_gpt_token}
        phx-blur="update_chat_gpt_token"
        type="password"
        class="shadow rounded border-2 border-black text-xs"
      />
    </div>
    """
  end

  attr :id, :string, required: true
  attr :message, Chat.Messages.Message, required: true

  def message_card(assigns) do
    ~H"""
    <div id={@id}>
      <div class="m-1 p-1 shadow-lg flex" phx-click="open-thread" phx-value-message_id={@message.id}>
        <div class="flex max-h-8">
          <div class="shrink-0 w-1 min-w-1" style={background_color(@message.user.color)}></div>
          <span class="shrink-0 bg-gray-200 rounded-3xl px-2 py-1 truncate w-36">
            <%= @message.user.email %>
          </span>
        </div>
        <span class="break-all p-1">
          <%= @message.content %>
        </span>
      </div>
      <div :if={@message.is_thread_open} class="border ml-8">
        <div class="relative h-5">
          <a
            class="absolute right-1 -top-2 text-2xl"
            phx-click="close-thread"
            phx-value-message_id={@message.id}
            href="#none"
          >
            &times
          </a>
        </div>
        <.simple_form
          class="flex items-center bg-white border border-gray-300 rounded-lg p-2"
          for={@message.sub_message_form}
          phx-submit="new-sub_message"
          phx-value-message_id={@message.id}
        >
          <.input
            id={"sub_message_form_input-#{@message.id}"}
            type="text"
            placeholder="메시지를 입력하세요"
            class="grow px-2 py-1 mr-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-1 focus:ring-blue-500"
            field={@message.sub_message_form[:content]}
          />
          <button class="min-w-fit px-2 py-1 bg-blue-500 text-white rounded-lg hover:bg-blue-600 focus:outline-none focus:ring-1 focus:ring-blue-500">
            Submit
          </button>
        </.simple_form>
        <.sub_message :for={sub_message <- @message.sub_messages} sub_message={sub_message} />
      </div>
    </div>
    """
  end

  attr :sub_message, Chat.SubMessages.SubMessage, required: true

  def sub_message(assigns) do
    ~H"""
    <div class="m-1 p-1 shadow-lg flex">
      <div class="flex max-h-8">
        <div class="shrink-0 w-1 min-w-1" style={background_color(@sub_message.user.color)}></div>
        <span class="shrink-0 bg-gray-200 rounded-3xl px-2 py-1 truncate w-36">
          <%= @sub_message.user.email %>
        </span>
      </div>
      <span class="break-all p-1">
        <%= @sub_message.content %>
      </span>
    </div>
    """
  end

  attr :display, :boolean, required: true
  attr :count, :integer, default: 30

  def skeleton_loading(assigns) do
    ~H"""
    <div :for={_ <- 1..@count} :if={@display} class="p-2">
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

        if String.trim(socket.assigns.chat_gpt_token) != "",
          do: spawn_gpt_client(socket.assigns.chat_gpt_token, message.content)

        {:noreply, assign(socket, form: to_form(Messages.change_message(%Message{})))}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  def handle_event("start_typing", _, socket) do
    # is_typing 플래그가 false라면, true로 바꾸고 방송을 한다.
    if socket.assigns.is_typing == false do
      PubSub.broadcast!(
        @pubsub,
        "#{@topic}/#{socket.assigns.channel.name}",
        {:start_typing, socket.assigns.current_user}
      )
    end

    socket = socket |> assign(is_typing: true)
    {:noreply, socket}
  end

  def handle_event("end_typing", _, socket) do
    if socket.assigns.is_typing == true do
      PubSub.broadcast!(
        @pubsub,
        "#{@topic}/#{socket.assigns.channel.name}",
        {:end_typing, socket.assigns.current_user}
      )
    end

    socket = socket |> assign(is_typing: false)
    {:noreply, socket}
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
  def handle_event("update_chat_gpt_token", %{"value" => token}, socket) do
    {:noreply, assign(socket, chat_gpt_token: token)}
  end

  @impl Phoenix.LiveView
  def handle_event("open-thread", %{"message_id" => message_id}, socket) do
    message =
      message_id
      |> Messages.get_message!()
      |> Chat.Repo.preload([:user, sub_messages: :user])
      |> refine_message()
      |> Map.put(:is_thread_open, true)

    socket = stream_insert(socket, :messages, message)

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event(
        "new-sub_message",
        %{"sub_message" => sub_message, "message_id" => message_id},
        socket
      ) do
    sub_message
    |> put_in(["user_id"], socket.assigns.current_user.id)
    |> put_in(["message_id"], message_id)
    |> SubMessages.create_sub_message()

    message =
      message_id
      |> Messages.get_message!()
      |> Chat.Repo.preload([:user, sub_messages: :user])
      |> refine_message()

    socket = stream_insert(socket, :messages, message)

    {:noreply, socket}
  end

  def handle_event("close-thread", %{"message_id" => message_id}, socket) do
    message =
      message_id
      |> Messages.get_message!()
      |> Chat.Repo.preload([:user])
      |> refine_message()

    socket = stream_insert(socket, :messages, message)

    {:noreply, socket}
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

  @impl Phoenix.LiveView
  def handle_info({:new_message, message, sender}, socket) do
    message = Map.put(message, :user, sender)

    socket =
      socket
      |> stream_insert(:messages, refine_message(message), at: 0)

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
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

  @impl Phoenix.LiveView
  def handle_info({:start_typing, user}, socket) do
    typing_users = [user | socket.assigns.typing_users]

    socket =
      socket
      |> assign(typing_users: typing_users)

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_info({:end_typing, user}, socket) do
    typing_users =
      socket.assigns.typing_users
      |> Enum.filter(fn usr -> usr.email != user.email end)

    socket =
      socket
      |> assign(
        typing_users: typing_users,
        is_typing: false
      )

    {:noreply, socket}
  end

  def handle_info({__MODULE__, :gpt, reply}, socket) do
    {:ok, message} =
      %{"content" => reply}
      |> Map.put("user_id", 0)
      |> Map.put("channel_id", socket.assigns.channel.id)
      |> Messages.create_message()

    PubSub.broadcast!(
      @pubsub,
      "#{@topic}/#{socket.assigns.channel.name}",
      {:new_message, message, @chatGPT}
    )

    {:noreply, assign(socket, form: to_form(Messages.change_message(%Message{})))}
  end

  defp spawn_gpt_client(token, content) do
    pid = self()

    spawn(fn ->
      reply = ChatGptClient.chat(token, content)
      send(pid, {__MODULE__, :gpt, reply})
    end)
  end

  defp stream_insert_many_messages(socket, name, messages) do
    Enum.reduce(messages, socket, fn message, acc ->
      Phoenix.LiveView.stream_insert(acc, name, refine_message(message), at: -1)
    end)
  end

  defp refine_presences(presences) do
    Enum.into(presences, %{}, &refine_presence/1)
  end

  defp refine_presence({id, %{metas: [meta | _]}}) do
    user = meta.user
    user = user |> Map.put(:is_typing, meta.is_typing) |> Map.put(:color, user_color(user))
    {id, user}
  end

  defp refine_messages(messages) do
    Enum.map(messages, &refine_message/1)
  end

  defp refine_message(message) do
    form =
      %Chat.SubMessages.SubMessage{}
      |> Chat.SubMessages.change_sub_message()
      |> to_form()

    %{user: user} = message

    message
    |> put_in([Access.key!(:user), Access.key!(:color)], user_color(user))
    |> put_in([Access.key!(:sub_message_form)], form)
    |> update_in([Access.key!(:sub_messages)], fn
      sub_messages when is_list(sub_messages) -> Enum.map(sub_messages, &refine_sub_message/1)
      sub_messages -> sub_messages
    end)
  end

  defp refine_sub_message(sub_message) do
    sub_message
    |> put_in([Access.key!(:user), Access.key!(:color)], user_color(sub_message.user))
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
