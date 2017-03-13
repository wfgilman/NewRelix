defmodule NewRelix.Mixfile do
  use Mix.Project

  @description """
    An Elixir Agent for New Relic
  """

  def project do
    [app: :new_relix,
     version: "0.1.0",
     elixir: "~> 1.4",
     description: @description,
     package: package(),
     elixirc_paths: elixirc_paths(Mix.env),
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(),
     dialyzer: [plt_add_deps: false],
     test_coverage: [tool: ExCoveralls],
     preferred_cli_env: ["coveralls": :test, "coveralls.detail": :test]
    ]
  end

  def application do
    [mod: {NewRelix, []}, extra_applications: [:logger]]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  defp deps do
    [
     {:httpoison, "~> 0.9"},
     {:poison, "~> 2.0"},
     {:gen_retry, "~> 1.0.1"},
     {:bypass, "~> 0.6", only: [:test]},

     {:credo, "~> 0.5", only: [:dev]},
     {:excoveralls, "~> 0.6", only: [:test]},
     {:ex_doc, "~> 0.14", only: [:dev], runtime: false},
     {:dialyxir, "~> 0.4", only: [:dev], runtime: false},
    ]
  end

  defp package do
    [
      name: :new_relix,
      files: ["config", "lib", "test", "mix.exs", "README*", "LICENSE*"],
      licenses: ["MIT"],
      maintainers: ["Will Gilman"],
      links: %{"Github" => "https://github.com/wfgilman/NewRelix"}
    ]
  end
end
