defmodule NewRelixTest do
  @moduledoc false

  use ExUnit.Case

  describe "new_relix" do

    test "configured?/0 returns true when configured" do
      assert NewRelix.configured? == true
    end

    test "configured?/0 returns false when :application_name is nil" do
      name = Application.get_env(:new_relix, :application_name)
      :ok = Application.put_env(:new_relix, :application_name, nil)

      assert NewRelix.configured? == false
      :ok = Application.put_env(:new_relix, :application_name, name)
    end

    test "configured?/0 returns false when :plugin_guid is nil" do
      guid = Application.get_env(:new_relix, :plugin_guid)
      :ok = Application.put_env(:new_relix, :plugin_guid, nil)

      assert NewRelix.configured? == false
      :ok = Application.put_env(:new_relix, :plugin_guid, guid)
    end

    test "configured?/0 returns false when :license_key is nil" do
      key = Application.get_env(:new_relix, :license_key)
      :ok = Application.put_env(:new_relix, :license_key, nil)

      assert NewRelix.configured? == false
      :ok = Application.put_env(:new_relix, :license_key, key)
    end
  end
end
