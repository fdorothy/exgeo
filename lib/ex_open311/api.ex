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

  params do
    requires :service_code, type: String
    optional :jurisdiction_id, type: String
    optional :attribute, type: Attributes
    optional :lat, type: String
    optional :long, type: String
    optional :address_string, type: String
    optional :address_id, type: String
    optional :email, type: String
    optional :device_id, type: String
    optional :account_id, type: String
    optional :first_name, type: String
    optional :last_name, type: String
    optional :phone, type: String
    optional :description, type: String
    optional :media_url, type: String
  end
  post "requests.json" do
    has_location = (params[:lat] != nil and params[:long] != nil) or
                   params[:address_string] != nil or params[:address_id] != nil
    if not has_location do
      conn
      |> put_status(400)
      |> text("""
      Invalid location parameter. lat & long both need to be sent \
      even though they are sent as two separate parameters. lat & long \
      are required if no address_string or address_id is provided.
      """)
    else
      result = ExOpen311.Server.create_service_request(params)
      data = [
	%{
	  service_request_id: result["_id"],
	  service_notice: "",
	  account_id: params[:account_id]
	}
      ]
      json(conn, data)
    end
  end

  params do
    requires :service_code, type: String
    optional :jurisdiction_id, type: String
    optional :attribute, type: Attributes
    optional :lat, type: String
    optional :long, type: String
    optional :address_string, type: String
    optional :address_id, type: String
    optional :email, type: String
    optional :device_id, type: String
    optional :account_id, type: String
    optional :first_name, type: String
    optional :last_name, type: String
    optional :phone, type: String
    optional :description, type: String
    optional :media_url, type: String
  end
  post "requests.xml" do
    has_location = (params[:lat] != nil and params[:long] != nil) or
                   params[:address_string] != nil or params[:address_id] != nil
    if not has_location do
      conn
      |> put_status(400)
      |> text("""
      Invalid location parameter. lat & long both need to be sent \
      even though they are sent as two separate parameters. lat & long \
      are required if no address_string or address_id is provided.
      """)
    else
      result = ExOpen311.Server.create_service_request(params)
      data = [
	%{
	  service_request_id: result["_id"],
	  service_notice: "",
	  account_id: params[:account_id]
	}
      ]
      result = ExOpen311.Xml.service_requests_to_xml(data)
      xml(conn, result)
    end
  end

  defp xml(conn, data) do
    conn
    |> Plug.Conn.put_resp_content_type("text/xml")
    |> Plug.Conn.send_resp(200, XmlBuilder.doc(data))
    |> Plug.Conn.halt
  end
end
