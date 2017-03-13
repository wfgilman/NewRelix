defmodule TestHelper.Assertions do
  import ExUnit.Assertions

  def assert_between(actual, lower_bound, upper_bound) do
    assert actual >= lower_bound && actual <= upper_bound, "expected " <>
    "#{inspect(actual)} to be between #{inspect(lower_bound)} and " <>
    "#{inspect(upper_bound)}"
  end

end

Application.put_env(:new_relic, :application_name, "Test")
Application.put_env(:new_relic, :license_key, "xyz")

Application.ensure_all_started(:bypass)

ExUnit.start()
