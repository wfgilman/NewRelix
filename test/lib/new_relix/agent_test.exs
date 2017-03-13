defmodule NewRelix.AgentTest do

  use ExUnit.Case

  alias NewRelix.Agent

  setup do
    bypass = Bypass.open()
    {:ok, bypass: bypass}
  end

  describe "agent" do

    test "push/1 requests POST and returns success", %{bypass: bypass} do
      Bypass.expect bypass, fn conn ->
        assert "POST" == conn.method
        Plug.Conn.resp(conn, 200, "{\"status\":\"ok\"}")
      end
      components = NewRelix.Mock.Aggregator.get_components()

      assert :ok = Agent.push(components, endpoint_uri(bypass.port))
    end

    test "push/1 requests POST and handles error", %{bypass: bypass} do
      Bypass.expect bypass, fn conn ->
        assert "POST" == conn.method
        Plug.Conn.resp(conn, 400, "{\"error\": \"Invalid content format\"}")
      end
      components = NewRelix.Mock.Aggregator.get_components()

      resp = Agent.push(components, endpoint_uri(bypass.port))
      assert resp == {:error , %{"error" => "Invalid content format"}}
    end

    test "push/1 doesn't send when NewRelix isn't configured" do
      name = Application.get_env(:new_relix, :application_name)
      :ok = Application.put_env(:new_relix, :application_name, nil)

      assert :ok = Agent.push([])
      :ok = Application.put_env(:new_relix, :application_name, name)
    end
  end

  defp endpoint_uri(port), do: "http://localhost:#{port}/"
end
