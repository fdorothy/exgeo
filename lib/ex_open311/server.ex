defmodule ExOpen311.Server do
  def server do
    Couchex.server_connection(config()[:server])
  end

  def services() do
    {:ok, db} = Couchex.open_db(server(), "open311_services")
    db
  end
  
  def get_services do
    {:ok, result} = Couchex.fetch_view(services(), {"services", "data"}, [])
    map_response(result)
  end

  defp map_response({list}) when is_list(list), do: Enum.map(list, fn {k, v} -> {k, map_response(v)} end) |> Enum.into(%{})
  defp map_response(list) when is_list(list), do: Enum.map(list, fn x -> map_response(x) end)
  defp map_response(response), do: response

  def config do
    Application.get_env(:ex_open311, :couchdb)
  end
end
