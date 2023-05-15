defmodule Chat.ViewCounter.Worker do
  use GenServer, restart: :temporary

  @registry Chat.ViewCounter.Registry
  @max_idle_second 30

  def start_link(path) do
    GenServer.start_link(__MODULE__, path, name: {:via, Registry, {@registry, path}})
  end

  @impl GenServer
  def init(path) do
    Process.flag(:trap_exit, true)

    {:ok,
     {
       path,
       _counter = 0,
       Process.send_after(self(), :shutdown, @max_idle_second * 1_000)
     }}
  end

  @impl GenServer
  def handle_info(:bump, {path, 0, ref}) do
    schedule_upsert()
    {:noreply, {path, 1, schedule_shutdown(ref)}}
  end

  @impl GenServer
  def handle_info(:bump, {path, counter, ref}) do
    {:noreply, {path, counter + 1, schedule_shutdown(ref)}}
  end

  @impl GenServer
  def handle_info(:upsert, {path, counter, ref}) do
    upsert!(path, counter)
    {:noreply, {path, 0, ref}}
  end

  @impl GenServer
  def handle_info(:shutdown, {path, counter, ref}) do
    Registry.unregister(@registry, path)

    Process.send_after(self(), :stop, 2_000)
    {:noreply, {path, counter, ref}}
  end

  @impl GenServer
  def handle_info(:stop, {path, counter, ref}) do
    {:stop, :shutdown, {path, counter, ref}}
  end

  defp schedule_upsert() do
    Process.send_after(self(), :upsert, Enum.random(10..20) * 1_000)
  end

  defp schedule_shutdown(timer_ref) do
    Process.cancel_timer(timer_ref, async: true, info: false)
    Process.send_after(self(), :shutdown, @max_idle_second * 1_000)
  end

  defp upsert!(path, counter) do
    import Ecto.Query
    alias Chat.Repo
    alias Chat.ViewCounter.ViewCount

    date = Date.utc_today()
    query = from m in ViewCount, update: [inc: [counter: ^counter]]

    Repo.insert!(
      %ViewCount{date: date, path: path, counter: counter},
      on_conflict: query,
      conflict_target: [:date, :path]
    )
  end

  @impl GenServer
  def terminate(_, {_path, 0, _ref}), do: :ok
  def terminate(_, {path, counter, _ref}), do: upsert!(path, counter)
end
