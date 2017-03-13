defmodule NewRelix.Poller do
  @moduledoc """
  Pushes accumulated metrics to `NewRelix.Agent` at specified interval.

  Executes each call to `NewRelix.Agent.push/1` in a supervised `Task` started
  by the `GenRetry.Task.Supervisor`. Polling interval and retry options are
  configured in `config.exs`.
  """

  use GenServer

  import Application

  require Logger

  @poll_interval get_env(:new_relix, :poll_interval) || 30_000
  @retry_options get_env(:new_relix, :retry_options) ||
    [retries: 3, jitter: 0.2]
  @adapters get_env(:new_relix, Adapters)

  # Client API

  @doc false
  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  # Callbacks

  def init(:ok) do
    timer = :erlang.send_after(@poll_interval, self(), :poll)
    {:ok, %{timer_ref: timer, tasks: []}}
  end

  def handle_info(:poll, %{timer_ref: ref, tasks: tasks}) do
    :erlang.cancel_timer(ref)
    timer = :erlang.send_after(@poll_interval, self(), :poll)
    components = @adapters[:aggregator].get_components()
    task = start_task(components)
    {:noreply, %{timer_ref: timer, tasks: task ++ tasks}}
  end

  def handle_info({ref, reply}, %{tasks: tasks} = state) do
    Process.demonitor(ref, [:flush])
    new_tasks = Enum.reject(tasks, fn %Task{ref: x} -> x == ref end)
    :ok = handle_task_reply(reply)
    {:noreply, %{state | tasks: new_tasks}}
  end

  def handle_info({:DOWN, ref, _proc, _pid, reason}, %{tasks: tasks} = state) do
    new_tasks = Enum.reject(tasks, fn %Task{ref: x} -> x == ref end)
    :ok = log_task_failure(reason)
    {:noreply, %{state | tasks: new_tasks}}
  end

  # Helper functions.

  defp start_task([]), do: []
  defp start_task(components) do
    push_fun = fn ->
      Kernel.apply(@adapters[:agent], :push, [components])
    end
    task = GenRetry.Task.Supervisor.async_nolink(NewRelix.Task.Supervisor,
            push_fun, @retry_options)
    List.wrap(task)
  end

  defp handle_task_reply(:ok), do: :ok
  defp handle_task_reply({:error, msg}) do
    log_task_failure(msg)
  end

  defp log_task_failure(msg) do
    Logger.warn "#{__MODULE__} Task failed with message: #{inspect msg}"
  end

end
