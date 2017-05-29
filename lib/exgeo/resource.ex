defmodule Maru.Types.Resource do
  use Maru.Type

  @re_resource ~r/^([A-Za-z0-9]+)\.(xml|json)$/

  def parse(val, _) when is_bitstring(val) do
    case Regex.run(@re_resource, val) do
      [_, resource, format] -> %{resource: resource, format: format}
      _ -> raise Maru.Exceptions.InvalidFormat
    end
  end
end
