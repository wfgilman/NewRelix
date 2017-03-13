# NewRelix

An Elixir Plugin Agent for New Relic Custom Metrics.

Forked from [newrelix.ex](https://github.com/romul/newrelic.ex), this library
conforms to the New Relic Plugin API for custom metric monitoring. It *does not*
publish any APM stats to New Relic.

The main changes are that this library targets the Plugin API specifically and
doesn't use any legacy code or aggregation logic from `newrelic-erlang`. It also
is designed to work with the instrumentation API from Phoenix.

New Relic Plugins [documentation](https://docs.newrelic.com/docs/plugins/plugins-new-relic).

See a sample application using NewRelix [here](https://github.com/wfgilman/NewRelixApp) for an implementation example of all the below instrumentation methods.

## Installation

Add `new_relix` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:new_relix, "~> 0.1.0"}]
end
```

Add the following configuration options to `config.exs`:

```elixir
config :new_relix,
  license_key: System.get_env("NEW_RELIC_LICENSE_KEY"),
  plugin_guid: "com.mycompany.elixir",
  application_name: "Test",
  poll_interval: 60_000,
  retry_options: [retries: 3, jitter: 0.2],
  httpoison_options: [timeout: 8000, recv_timeout: 8000]
```
`poll_interval`, `retry_options` and `httpoison_options` are optional and default to
the values above.

If you want to use NewRelix to instrument Phoenix and Ecto, you need to follow
an additional step.

For Phoenix, you need to add the name of your instrumentation module to the
Endpoint config.
```elixir
config :my_app, MyApp.Endpoint,
  instrumenters: [MyApp.Instrument]
```
For Ecto, if you want to instrument all database queries, add your instrumentation
module to the Repo config:
```elixir
config :my_app, MyApp.Repo,
  loggers: [{Ecto.LogEntry, :log, []}, {MyApp.Instrument, :log_entry, []}]
```
Note that if you take this step, be sure to include `{Ecto.LogEntry, :log, []}`.

## Usage

Create a module in your application that imports the instrumentation functions.
This is where you will put any additional instrumentation callbacks for Phoenix.
It will also be the entry point for your instrumentation.
```elixir
defmodule MyApp.Instrument do
  use NewRelix.Instrumenter
end
```

### Generic

Generic instrumentation is achieved using `MyApp.Instrument.measure/1`:

For example, you can replace any function in your application:
```elixir
result = MyModule.my_function(my_arg)
```
with the following:
```elixir
result = MyApp.Instrument.measure({MyModule, :my_function, [my_arg]})
```
The time it takes to execute the function will be recorded and sent to New
Relic. The label associated with the measurement defaults to "Other/Mod/fun[ms|]",
but can be overridden by providing a Keyword list to `measure/1`.
```elixir
opt = [label: "Database/ETL", count_unit: "query"]
result = MyApp.Instrument.measure(mfa, opts)
```

### Phoenix

Phoenix instrumentation is achieved by implementing callback functions which are
called by `Phoenix.Endpoint.instrument/3`. Two callbacks are implemented by
default: `:phoenix_controller_call` and `:phoenix_controller_render`. The labels
associated with these events are "Web/Mod/fun[ms|call]" and "Web/Mod/fun[ms|render]",
respectively.

Any Phoenix function can be instrumented with Phoenix's extensible API. Just add
the callbacks to `MyApp.Instrument` like so:
```elixir
defmodule MyApp.Instrument do
  use NewRelix.Instrumenter

  render_view(:start, _compile_metadata, %{view: name}) do
    "Web/#{name}[ms|render]"
  end
  render_view(:stop, time_diff, label) do
    NewRelix.Collector.record_value(label, time_diff / 1_000_000)
  end
end
```
The callback arguments are specified in the Phoenix Instrumentation API [docs](https://hexdocs.pm/phoenix/Phoenix.Endpoint.html).

If you don't want to use this, simply don't configure the Phoenix endpoint.

### Ecto

Ecto instrumentation is a little more crude as it piggybacks off the logger
extensibility. This limits the metadata available for instrumentation to the
fields in the `Ecto.LogEntry` struct. However, if you do want to measure all
database query execution times, simply configure Ecto `:loggers` as described above.

`log_entry/1` simply records the query time under the label "Database/Query[ms|query]".
However, this function can be overridden to provide more detail. For example:
```elixir
defmodule MyApp.Instrument do
  use NewRelix.Instrumenter

  def log_entry(%{query_time: time, result: {:ok, %{command: command}}} = entry) do
    str_command = command |> to_string() |> String.upcase()
    label = "Database/#{to_string(str_command)}[ms|query]"
    NewRelix.Collector.record_value(label, time / 1_000_000)
  end
end
```
This will provide some additional detail about the query:
```elixir
%{"Database/SELECT[ms|query]" => [2.5567]}
```
If you want more detail than this, it's better to wrap your query in `measure/1`
so you can specify the name explicitly.

Ecto Logger specification is documented [here](https://hexdocs.pm/ecto/Ecto.Repo.html#content).

Details on the `Ecto.LogEntry` struct are [here](https://hexdocs.pm/ecto/Ecto.LogEntry.html#content).

Again, if you're not interested in this, just don't configure the Ecto loggers.
