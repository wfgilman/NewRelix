defmodule NewRelix.Instrumenter do
  @moduledoc """
  Instrumentation functions.
  """

  defmacro __using__(_opts) do
    quote do
      @adapters NewRelix.compile_config()

      @doc """
      Records execution time of a function.

      Executes the MFA in an anonymous function and sends the time of execution
      in milliseconds to `NewRelix.Collector`. You may specify the name of the
      metric you are recording by using the `opts` argument which is a `Keyword`
      list with the following options. Any others will be ignored.

      Options:
      * `label` - New Relic metric name, e.g. "Database/ETL". See docs for naming
      accepted conventions. Defaults to "Other/ModuleName/function_name" where
      ModuleName is the alias (e.g. NewRelixApp.Repo -> Repo).
      * `count_unit` - Description of the unit that is beging recorded. Defaults to
      blank.

      The `opts` are concatentated to form a key which will be updated with
      subsequent recorded execution times. This key is the same label that will be
      posted to New Relic, e.g. "Database/ETL[ms|query]". All keys will be prefixed
      with the required "Component/AppName/" before submission to New Relic.
      """
      @spec measure({atom, atom, list}, Keyword.t) :: any
      def measure({mod, fun, args}, opts \\ []) do
        {elapsed, result} = :timer.tc(mod, fun, args)
        name = opts[:label] || "Other/#{get_alias(mod)}/#{fun}"
        count_unit = opts[:count_unit] || ""
        label = "#{name}[ms|#{count_unit}]"
        @adapters[:collector].record_value(label, elapsed / 1_000)
        result
      end

      @doc """
      Instrumenter callbacks for Phoenix default events.

      These events are instrumented in Phoenix by default. See the [documentation](https://hexdocs.pm/phoenix/Phoenix.Endpoint.html)
      under the section "Instrumentation API - Phoenix default events".

      The label passed to `NewRelix.Collector.record_value/1` is a concatentation
      of "Web/", alias of the calling module (e.g. MyApp.UserController ->
      UserController), and the function.

      Time is measures in milliseconds.
      """
      @spec phoenix_controller_call(:start | :stop, map | integer, Plug.Conn.t | String.t) :: String.t
                                                                                            | :ok
      def phoenix_controller_call(:start, compile_metadata, _runtime_metadata) do
        %{module: mod, function: fun} = compile_metadata
        name = "Web/#{get_alias(mod)}/#{trim_arity(fun)}"
        "#{name}[ms|call]"
      end
      def phoenix_controller_call(:stop, time_diff, label) do
        @adapters[:collector].record_value(label, time_diff / 1_000_000)
        :ok
      end

      @spec phoenix_controller_render(:start | :stop, map | integer, map | String.t) :: String.t
                                                                                      | :ok
      def phoenix_controller_render(:start, compile_metadata, _runtime_metadata) do
        %{module: mod, function: fun} = compile_metadata
        name = "Web/#{get_alias(mod)}/#{trim_arity(fun)}"
        "#{name}[ms|render]"
      end
      def phoenix_controller_render(:stop, time_diff, label) do
        @adapters[:collector].record_value(label, time_diff / 1_000_000)
        :ok
      end

      defp get_alias(mod) do
        mod |> Atom.to_string() |> String.split(".") |> List.last()
      end
      defp trim_arity(fun) do
        arity = String.last(fun)
        String.replace_suffix(fun, "/#{arity}", "")
      end

      @doc false
      @spec log_entry(map) :: :ok
      def log_entry(%{query_time: time} = log_entry) do
        label = "Database/Query[ms|query]"
        @adapters[:collector].record_value(label, time / 1_000_000)
      end

      defoverridable [measure: 2, log_entry: 1, phoenix_controller_call: 3,
                      phoenix_controller_render: 3]

    end
  end
end
