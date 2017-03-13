defmodule NewRelix.Agent do
  @moduledoc """
  Posts metrics to New Relic Plugin API.

  A New Relic Agent using the Elixir HTTP Client `HTTPoison`. Designed to
  conform directly to the current New Relic Plugin API [documentation](https://docs.newrelic.com/docs/plugins/plugin-developer-resources/developer-reference/working-directly-plugin-api).
  """

  require Logger

  @doc """
  Pushes metrics to New Relic.

  Posts a JSON request body to the New Relic API. An HTTP request is made only
  if the application is configured, otherwise a warning is logged.

  The request body conforms to the following [spec](https://docs.newrelic.com/docs/plugins/plugin-developer-resources/developer-reference/metric-data-plugin-api).
  """
  @spec push(list, String.t) :: :ok | {:error, any}
  def push(components, uri \\ get_root_uri()) do
    if NewRelix.configured? do
      body = %{agent: get_agent(), components: components}
      make_request(:post, uri, body, %{})
      |> handle_response()
    else
      :ok = Logger.warn "NewRelix Agent is not configured."
      :ok
    end
  end

  defp get_agent do
    Map.new()
    |> Map.put("host", get_host())
    |> Map.put("pid", get_pid())
    |> Map.put("version", get_version())
  end

  defp get_request_headers do
    Map.new()
    |> Map.put("X-License-Key", get_license_key())
    |> Map.put("Content-Type", "application/json")
    |> Map.put("Accept", "application/json")
  end

  # Needs to raise on failure in order for GenRetry to work.
  defp make_request(method, endpoint, body, headers, options \\ []) do
    rb = Poison.encode!(body)
    rh = get_request_headers() |> Map.merge(headers) |> Map.to_list()
    options = httpoison_request_options() ++ options
    HTTPoison.request!(method, endpoint, rb, rh, options)
  end

  defp handle_response(%{status_code: 200}), do: :ok
  defp handle_response(response) do
    {:error, Poison.decode!(response.body)}
  end

  defp get_root_uri do
    "https://platform-api.newrelic.com/platform/v1/metrics"
  end

  defp get_license_key do
    Application.get_env(:new_relix, :license_key)
  end

  defp httpoison_request_options do
    Application.get_env(:new_relix, :httpoison_options, [])
  end

  defp get_host do
    {:ok, host} = :inet.gethostname()
    List.to_string(host)
  end

  defp get_pid do
    :os.getpid() |> :erlang.list_to_integer()
  end

  defp get_version do
    {:ok, version} = :application.get_key(:new_relix, :vsn)
    List.to_string(version)
  end
end
