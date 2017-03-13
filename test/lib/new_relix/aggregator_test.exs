defmodule NewRelix.AggregatorTest do

  use ExUnit.Case

  alias NewRelix.Aggregator

  describe "aggregator" do

    test "get_components/0 renders aggregated metrics" do
      components = Aggregator.get_components()
      first = Enum.at(components, 0)
      second = Enum.at(components, 1)

      assert first["name"] == "Test"
      assert first["guid"] == "com.mycompany.elixir"
      assert first["duration"] == 28_000_000
      assert first["metrics"] == %{
        "Component/Test/Database/ETL[ms|query]" => %{
          "count" => 4,
          "max" => 2_100,
          "min" => 1_800,
          "sum_of_squares" => 15_260_000,
          "total" => 7_800
        }
      }
      assert second["name"] == "Test"
      assert second["guid"] == "com.mycompany.elixir"
      assert second["duration"] == 28_000_000
      assert second["metrics"] == %{
        "Component/Test/Web/Api[ms|hit]" => %{
          "count" => 5,
          "max" => 150,
          "min" => 40,
          "sum_of_squares" => 47_000,
          "total" => 440
        }
      }
    end
  end
end
