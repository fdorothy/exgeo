defmodule ExGeo.API do
  use Maru.Router

  plug Plug.Parsers,
    pass: ["*/*"],
    json_decoder: Poison,
    parsers: [:urlencoded, :json, :multipart]

  ## GET /services.[json|xml] routes

  get "services.json" do
    process_get_services(conn, &json(conn, &1))
  end

  get "services.xml" do
    process_get_services(conn, fn result ->
      result = ExGeo.Xml.services_to_xml(result)
      xml(conn, result)
    end)
  end

  defp process_get_services(_conn, on_success_fn) do
    services = ExGeo.Server.get_services()
    data = Enum.map(services, fn service ->
      info = service["value"]
      %{
        service_code: Map.get(info, "service_code", "unknown service code"),
        service_name: Map.get(info, "service_name", "unknown service name"),
        description: Map.get(info, "description", ""),
        metadata: Map.get(info, "metadata", false),
        type: Map.get(info, "type", "realtime"),
        keywords: Map.get(info, "keywords", ""),
        group: Map.get(info, "group", "unknown group")
      }
    end)
    on_success_fn.(data)
  end

  ## POST /requests.[json|xml] routes

  # parameters for the /requests.* routes
  helpers do
    params :requests_params do
      requires :service_code, type: String
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
  end

  params do
    use :requests_params
  end
  post "requests.json" do
    process_requests(conn, params, &json(conn, &1))
  end

  params do
    use :requests_params
  end
  post "requests.xml" do
    process_requests(conn, params, fn data ->
      result = ExGeo.Xml.service_requests_to_xml(data)
      xml(conn, result)
    end)
  end

  defp process_requests(conn, params, on_success_fn) do
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
      result = ExGeo.Server.create_service_request(params)
      data = [
	      %{
	        service_request_id: result["_id"],
	        service_notice: "",
	        account_id: params[:account_id]
	      }
      ]
      on_success_fn.(data)
    end
  end

  defp xml(conn, data) do
    conn
    |> Plug.Conn.put_resp_content_type("text/xml")
    |> Plug.Conn.send_resp(200, XmlBuilder.doc(data))
    |> Plug.Conn.halt
  end
end
