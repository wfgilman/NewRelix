use Mix.Config

config :new_relix,
  license_key: System.get_env("NEW_RELIC_LICENSE_KEY"),
  plugin_guid: "com.mycompany.elixir",
  application_name: "Test",
  poll_interval: 60_000,
  retry_options: [retries: 3, jitter: 0.2],
  httpoison_options: [timeout: 8000, recv_timeout: 8000]

config :new_relix, Adapters,
  aggregator: NewRelix.Aggregator,
  agent: NewRelix.Agent,
  collector: NewRelix.Collector
