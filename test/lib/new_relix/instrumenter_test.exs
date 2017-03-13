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

  defmodule Ecto.LogEntry do

    defstruct query: nil, source: nil, params: [], query_time: nil,
              decode_time: nil, queue_time: nil, result: nil,
              connection_pid: nil, ansi_color: nil

    def entry do
      %Ecto.LogEntry{
        ansi_color: nil,
        connection_pid: nil,
        decode_time: 29971,
        params: [2],
        query: "SELECT u0.\"id\", u0.\"name\", u0.\"inserted_at\", u0.\"updated_at\" FROM \"user\" AS u0 WHERE (u0.\"id\" = $1)",
        query_time: 2550178,
        queue_time: 82553,
        result: {:ok, %{
          columns: ["id", "name", "inserted_at", "updated_at"],
          command: :select,
          connection_id: 75519,
          num_rows: 1,
          rows: [[%{
                    __meta__: nil,
                    id: 2,
                    inserted_at: ~N[2017-03-13 18:12:07.322992],
                    name: "user2",
                    updated_at: ~N[2017-03-13 18:12:07.322999]
                  }]
                ]
          }
        },
        source: "user"
      }
    end
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

    test "log_entry records query time" do
      require Ecto.LogEntry

      Process.register self(), :test
      entry = Ecto.LogEntry.entry()
      Instrument.log_entry(entry)

      {label, elapsed} = assign_received()

      assert label == "Database/Query[ms|query]"
      assert elapsed == 2.550178
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
