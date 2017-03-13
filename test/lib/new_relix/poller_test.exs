defmodule NewRelix.PollerTest do

  use ExUnit.Case

  alias NewRelix.Poller

  setup_all do
    state = %{timer_ref: make_ref(), tasks: []}
    {:ok, state: state}
  end

  describe "poller" do

    test "init/1 starts process timer" do
      {:ok, %{timer_ref: ref}} = Poller.init(:ok)

      assert is_reference(ref)
    end

    test "handle_info/2 starts Task and puts in state", %{state: state} do
      {:noreply, new_state} = Poller.handle_info(:poll, state)

      assert %Task{} = new_state.tasks |> List.first()
    end

    test "handle_info/2 receives success reply", %{state: state} do
      {:noreply, new_state} = Poller.handle_info(:poll, state)
      %Task{ref: ref} = Enum.random(new_state.tasks)
      {:noreply, %{tasks: tasks}} = Poller.handle_info({ref, :ok}, new_state)

      assert [] = Enum.filter(tasks, fn %Task{ref: x} -> x == ref end)
    end

    test "handle_info/2 recieve error reply", %{state: state} do
      {:noreply, new_state} = Poller.handle_info(:poll, state)
      %Task{ref: ref} = Enum.random(new_state.tasks)
      {:noreply, %{tasks: tasks}} = Poller.handle_info({ref, {:error, "err"}},
                                                                      new_state)

      assert [] = Enum.filter(tasks, fn %Task{ref: x} -> x == ref end)
    end

    test "handle_info/2 receives :DOWN message", %{state: state} do
      {:noreply, new_state} = Poller.handle_info(:poll, state)
      %Task{ref: ref} = Enum.random(new_state.tasks)
      msg = {:DOWN, ref, :process, self(), ":DOWN"}
      {:noreply, %{tasks: tasks}} = Poller.handle_info(msg, new_state)

      assert [] = Enum.filter(tasks, fn %Task{ref: x} -> x == ref end)
    end
  end
end
