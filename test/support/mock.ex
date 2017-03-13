defmodule NewRelix.Mock.Aggregator do
  @moduledoc false

  def get_components do
    [
      %{
        "name" => "Test",
        "guid" => "com.mycompany.elixir",
        "duration" => 53,
        "metrics" => %{
          "Database/ETL[ms|query]" => %{
            "count" => 4,
            "max" => 2_100,
            "min" => 1_800,
            "sum_of_squares" => 15_260_000,
            "total" => 7_800
          }
        }
      },
      %{
        "name" => "Test",
        "guid" => "com.mycompany.elixir",
        "duration" => 53,
        "metrics" => %{
          "Web/Api[ms|hit]" => %{
            "count" => 5,
            "max" => 150,
            "min" => 40,
            "sum_of_squares" => 47_000,
            "total" => 440
          }
        }
      }
    ]
  end
end

defmodule NewRelix.Mock.Agent do
  @moduledoc false

  def push(_components) do
    :ok
  end
end

defmodule NewRelix.Mock.Collector do
  @moduledoc false

  def poll do
    %{start_time: :os.system_time(:second) - 28_000_000,
      data: %{
        "Database/ETL[ms|query]" => [1_800, 1_900, 2_000, 2_100],
        "Web/Api[ms|hit]" => [70, 120, 150, 40, 60]
      }
    }
  end

  def record_value(label, elapsed) do
    send :test, {label, elapsed}
  end
end
