defmodule Maru.Types.Attributes do
  use Maru.Type

  def parse(val, _) when is_map(val) do
    val
  end
end
