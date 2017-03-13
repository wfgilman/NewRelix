defmodule NewRelix.Aggregator do
  @moduledoc """
  Aggregates collected metrics for submission to New Relic.
  """

  @adapters NewRelix.compile_config()

  @doc """
  Transforms `Collector.t` to components list.

  Aggregates values recorded for each key in the `data` key in `Collector.t` and
  puts the results into a list along with the required metadata. Each element
  in the components list has the following keys:
  * `name` - Application name. Set in `config.exs`.
  * `guid` - GUID for the plugin. Set in `config.exs`.
  * `duration` - Time in seconds that the metrics were collected.
  * `metrics` - Key-value pairs where the `key` is the metric name and the value
  is a map of key-value pairs with the following keys: "count", "total", "min",
  "max", "sum_of_squares".
  """
  @spec get_components() :: list
  def get_components do
    collector = @adapters[:collector].poll()
    %{start_time: start_time, data: data} = collector
    duration = (:os.system_time(:second) - start_time)
    metrics = get_metrics(data)

    metrics
    |> Stream.map(&%{"metrics" => &1})
    |> Stream.map(&Map.merge(&1, %{"duration" => duration}))
    |> Stream.map(&Map.merge(&1, get_static_components()))
    |> Enum.to_list()
  end

  defp get_metrics(data) do
    data
    |> Map.to_list()
    |> Enum.map(fn {k, v} ->
        %{prefix_metric_name(k) => calculate_metric_values(v)}
      end)
  end

  defp prefix_metric_name(key) do
    "Component/#{get_application_name()}/#{key}"
  end

  defp calculate_metric_values(values) do
    Map.new()
    |> Map.put("min", Enum.min(values))
    |> Map.put("max", Enum.max(values))
    |> Map.put("total", Enum.sum(values))
    |> Map.put("count", Enum.count(values))
    |> Map.put("sum_of_squares", Enum.reduce(values, 0, fn x, acc ->
        (x * x) + acc end))
  end

  defp get_static_components do
    Map.new()
    |> Map.put("name", get_application_name())
    |> Map.put("guid", get_plugin_guid())
  end

  defp get_application_name do
    Application.get_env(:new_relix, :application_name)
  end

  defp get_plugin_guid do
    Application.get_env(:new_relix, :plugin_guid)
  end
end
