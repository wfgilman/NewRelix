defmodule NewRelix.CollectorTest do
  @moduledoc false

  use ExUnit.Case

  alias NewRelix.Collector

  setup_all do
    key = "Database/ETL"
    value = 1_800

    {:ok, key: key, value: value}
  end

  describe "collector" do

    test "record_value/1 accepts instrumentation", %{key: key, value: value} do
      assert :ok = Collector.record_value(key, value)
    end

    test "handle_cast/2 stores instrumentation in state", %{key: k, value: v} do
       {:noreply, state} = Collector.handle_cast({:record_value, k, v},
                                                                  %Collector{})

       assert state.data == %{k => [v]}
    end

    test "poll/0 returns state with data", %{key: k, value: v} do
      Collector.poll() # Purge
      :ok = Collector.record_value(k, v)
      state = Collector.poll()

      assert state.data == %{k => [v]}
    end

    test "record_value/1 updates key with additional values",
                                                        %{key: k, value: v} do
      Collector.poll() # Purge
      :ok = Collector.record_value(k, v)
      :ok = Collector.record_value(k, 2_000)
      state = Collector.poll()

      assert state.data == %{k => [2_000, 1_800]}
    end
  end
end
