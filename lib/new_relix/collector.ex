defmodule NewRelix.Collector do
  @moduledoc """
  Server which collects and stores metrics in state.

  Collected metrics are polled for sending to New Relic. State the type
  `Collector.t`: a map with the time at which the server was last polled and
  a map of key-value pairs of metrics tracked. The server accumulates all
  recorded values in a list under the key in which they were passed.
  """

  use GenServer

  alias NewRelix.Collector

  defstruct start_time: :os.system_time(:second), data: %{}

  @type t :: %Collector{start_time: integer, data: %{String.t => [integer]}}

  # Client API

  @doc false
  def start_link do
    GenServer.start_link(__MODULE__, %Collector{}, name: __MODULE__)
  end

  @doc """
  Puts recorded metrics into state under a `String` key for later polling.

  Adds a new key-value pair or adds the recorded metric to the values under
  and existing key.
  """
  @spec record_value(key :: String.t, value :: integer) :: :ok
  def record_value(key, value) do
    GenServer.cast(__MODULE__, {:record_value, key, value})
  end

  @doc """
  Returns current state.
  """
  @spec poll() :: Collector.t
  def poll do
    GenServer.call(__MODULE__, :poll)
  end

  # Callbacks

  def handle_cast({:record_value, key, value}, %{data: data} = state) do
    new_data = Map.update(data, key, List.wrap(value), &([value | &1]))
    {:noreply, %{state | data: new_data}}
  end

  def handle_call(:poll, _from, state) do
    {:reply, state, %Collector{}}
  end

end
