defmodule NewRelix.InstrumenterTest do
  @moduledoc false

  use ExUnit.Case, async: false

  import TestHelper.Assertions

  alias NewRelix.Instrumenter

  defmodule Instrument do
    use NewRelix.Instrumenter
  end

  defmodule Phoenix.Endpoint do

    defmacro instrument(event, runtime \\ Macro.escape(%{}), fun) do
      compile = Macro.escape(strip_caller(__ENV__))

      quote do
        result = Instrument.unquote(event)(:start, unquote(compile),
          unquote(runtime))
        start = :erlang.monotonic_time()
        try do
          unquote(fun).()
        after
          diff = :erlang.monotonic_time() - start
          Instrument.unquote(event)(:stop, diff, result)
        end
      end
    end

    defp strip_caller(%Macro.Env{module: mod, function: fun, file: file,
                                                              line: line}) do
      %{module: mod, function: form_fa(fun), file: file, line: line}
    end

    defp form_fa({name, arity}) do
      Atom.to_string(name) <> "/" <> Integer.to_string(arity)
    end
    defp form_fa(nil), do: nil

  end

  describe "instrumenter" do

    test "measure/2 executes MFA" do
      Process.register self(), :test
      mfa = {:timer, :sleep, [42]}
      Instrument.measure(mfa, [label: "Some/Label", count_unit: "message"])

      {label, elapsed} = assign_received()

      assert label == "Some/Label[ms|message]"
      assert_between(elapsed, 42, 50)
    end

    test "phoenix_controller_call callback records measurement" do
      require Phoenix.Endpoint

      Process.register self(), :test
      Phoenix.Endpoint.instrument :phoenix_controller_call, %Plug.Conn{}, fn ->
        :timer.sleep(500)
      end

      {label, elapsed} = assign_received()

      assert label == "Web/Endpoint/instrument[ms|call]"
      assert_between(elapsed, 500, 505)
    end

    test "phoenix_controller_render callback records measurement" do
      require Phoenix.Endpoint

      Process.register self(), :test
      Phoenix.Endpoint.instrument :phoenix_controller_render, %{template: nil},
        fn -> :timer.sleep(500) end

      {label, elapsed} = assign_received()

      assert label == "Web/Endpoint/instrument[ms|render]"
      assert_between(elapsed, 500, 505)
    end
  end

  defp assign_received do
    receive do
      msg ->
        msg
    after 100 ->
      {:error, :no_message}
    end
  end
end
