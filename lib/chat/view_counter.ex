defmodule Chat.ViewCounter do
  @moduledoc """
  The ViewCounter context.
  """
  use Supervisor

  @worker Chat.ViewCounter.Worker
  @registry Chat.ViewCounter.Registry
  @supervisor Chat.ViewCounter.WorkerSupervisor

  def start_link(_opts) do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl Supervisor
  def init(:ok) do
    children = [
      {Registry, keys: :unique, name: @registry},
      {DynamicSupervisor, name: @supervisor, strategy: :one_for_one}
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end

  def bump(path) when is_binary(path) do
    pid =
      case Registry.lookup(@registry, path) do
        [{pid, _}] ->
          pid

        [] ->
          case DynamicSupervisor.start_child(@supervisor, {@worker, path}) do
            {:ok, pid} -> pid
            {:error, {:already_started, pid}} -> pid
          end
      end

    :bump = send(pid, :bump)
    :ok
  end
end
