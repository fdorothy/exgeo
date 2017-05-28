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
    params :post_requests_params do
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
    use :post_requests_params
  end
  post "requests.json" do
    process_requests(conn, params, &json(conn, &1))
  end

  params do
    use :post_requests_params
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

  ## GET /requests.[json|xml] routes
  helpers do
    params :get_requests_params do
      optional :service_request_id, type: String
      optional :service_code, type: String
      optional :start_date, type: String
      optional :end_date, type: String
      optional :status, type: String
    end
  end

  params do
    use :get_requests_params
  end
  get "requests.json" do
    process_get_requests(conn, params, &json(conn, &1))
  end

  params do
    use :get_requests_params
  end
  get "requests.xml" do
    process_get_requests(conn, params, fn result ->
      result = ExGeo.Xml.service_requests_to_xml(result)
      xml(conn, result)
    end)
  end

  defp process_get_requests(_conn, params, on_success_fn) do
    requests = ExGeo.Server.find_service_requests(params)
    data = Enum.map(requests, fn request ->
      info = request
      %{
        service_request_id: Map.get(info, "service_request_id", ""),
        status: Map.get(info, "status", ""),
        status_note: Map.get(info, "status_note", ""),
        service_name: Map.get(info, "service_name", ""),
        service_code: Map.get(info, "service_code", ""),
        description: Map.get(info, "description", ""),
        agency_responsible: Map.get(info, "agency_responsible", ""),
        service_notice: Map.get(info, "service_notice", ""),
        requested_datetime: Map.get(info, "requested_datetime", ""),
        updated_datetime: Map.get(info, "updated_datetime", ""),
        expected_datetime: Map.get(info, "expected_datetime", ""),
        address: Map.get(info, "address", ""),
        address_id: Map.get(info, "address_id", ""),
        zipcode: Map.get(info, "zipcode", ""),
        lat: Map.get(info, "lat", ""),
        long: Map.get(info, "long", ""),
        media_url: Map.get(info, "media_url", ""),
      }
    end)
    on_success_fn.(data)
  end

  defp xml(conn, data) do
    conn
    |> Plug.Conn.put_resp_content_type("text/xml")
    |> Plug.Conn.send_resp(200, XmlBuilder.doc(data))
    |> Plug.Conn.halt
  end
end
