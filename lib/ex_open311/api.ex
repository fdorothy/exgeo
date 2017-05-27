defmodule ExOpen311.API do
  use Maru.Router

  plug Plug.Parsers,
    pass: ["*/*"],
    json_decoder: Poison,
    parsers: [:urlencoded, :json, :multipart]

  params do
    optional :jurisdiction_id, type: String
  end
  get "services.json" do
    services =
      ExOpen311.Server.get_services
      |> Enum.map(&Map.fetch!(&1, "value"))
    json(conn, services)
  end

  params do
    optional :jurisdiction_id, type: String
  end
  get "services.xml" do
    services =
      ExOpen311.Server.get_services
      |> Enum.map(&Map.fetch!(&1, "value"))
      |> ExOpen311.Xml.services_to_xml
    xml(conn, services)
  end

  defp xml(conn, data) do
    conn
    |> Plug.Conn.put_resp_content_type("text/xml")
    |> Plug.Conn.send_resp(200, XmlBuilder.doc(data))
    |> Plug.Conn.halt
  end
end
