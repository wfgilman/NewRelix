defmodule NewRelix do
  @moduledoc """
  An Elixir Plugin Agent for New Relic.
  """

  use Application

  @doc false
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(NewRelix.Collector, []),
      worker(NewRelix.Poller, []),
      supervisor(Task.Supervisor, [[name: NewRelix.Task.Supervisor]])
    ]

    opts = [strategy: :one_for_one, name: NewRelix.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @doc false
  @spec configured? :: boolean
  def configured? do
    Application.get_env(:new_relix, :application_name) != nil &&
    Application.get_env(:new_relix, :plugin_guid) != nil &&
    Application.get_env(:new_relix, :license_key) != nil
  end
end
