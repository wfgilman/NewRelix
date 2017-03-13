# NewRelix

An Elixir Plugin Agent for New Relic Custom Metrics.

Forked from [newrelix.ex](https://github.com/romul/newrelic.ex), this library
conforms to the New Relic Plugin API for custom metric monitoring. It *does not*
publish any APM stats to New Relic.

The main changes are that this library targets the Plugin API specifically and
doesn't use any legacy code or aggregation logic from `newrelic-erlang`. It also
is designed to work with the instrumentation API from Phoenix.

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

## Usage

Generic instrumentation is achieved using `NewRelix.Instrumenter.measure/1`:

For example, you can replace any function in your application:
```elixir
result = MyModule.my_function(my_arg)
```
with the following:
```elixir
result = NewRelix.Instrumenter.measure({MyModule, :my_function, [my_arg]})
```
The time it takes to execute the function will be recorded and sent to New
Relic. The label associated with the measurement defaults to "Other/Mod/fun[ms|]", but can be overridden by providing a Keyword list to
`measure/1`.
```elixir
opt = [label: "Database/ETL", count_unit: "query"]
result = NewRelix.Instrumenter.measure(mfa, opts)
```

### Phoenix

Phoenix instrumentation is achieved by implementing callback functions which are called by `Phoenix.Endpoint.instrument/3`. Two callbacks are implemented by
default: `:phoenix_controller_call` and `:phoenix_controller_render`. The labels
associated with these events are "Web/Mod/fun[ms|call]" and "Web/Mod/fun[ms|render]", respectively.
