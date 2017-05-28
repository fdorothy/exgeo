defmodule ExOpen311.Server do
  @doc ~S"""
  Recreates the entire ExOpen311 couchdb database. This is dangerous!
  """
  def recreate do
    config = Application.get_env(:ex_open311, :couchdb)
    server = Couchex.server_connection(config[:server])
    Couchex.delete_db(ExOpen311.Server.services())
    Couchex.create_db(server, config[:services_db])
    Couchex.delete_db(ExOpen311.Server.service_requests())
    Couchex.create_db(server, config[:service_requests_db])

    # views: services.data
    services_data_view = """
    function (doc) {
      if (doc.service_code) {
        emit(doc.code, doc);
      }
    }
    """
    doc = %{
      "_id" => "_design/services",
      "language" => "javascript",
      "views" => %{
        "data" => %{
          "map" => services_data_view
        }
      }
    }
    Couchex.save_doc(ExOpen311.Server.services(), doc)

    # initialize with a default service
    doc = %{
      "_id" => "default",
      "data" => %{
        service_name: "new service",
        service_notice: "message sent to users when opening new requests",
        description: "service description",
        group: "service_group",
        metadata: false,
        type: "realtime",
        keywords: "",
        expected_work_time: ""
      }
    }
    Couchex.save_doc(ExOpen311.Server.services(), doc)
  end

  @doc ~S"""
  Gets a connection to the couchdb server
  """
  def server do
    Couchex.server_connection(config()[:server])
  end

  ###  SERVICES  ###

  @doc ~S"""
  Gets a connection to the open311_services couchdb database
  """
  def services() do
    {:ok, db} = Couchex.open_db(server(), config()[:services_db])
    db
  end
  
  def create_service(data) when is_map(data) do
    defaults = Couchex.open_doc(services(), %{id: "default"})["data"]
    {:ok, result} = Couchex.save_doc(services(), Map.merge(defaults, data))
    map_response(result)
  end

  def create_service(code, name, description, group) do
    create_service(
      %{
        "_id" => code,
        "service_code" => code,
        "service_name" => name,
        "description" => description,
        "group" => group
    })
  end

  def get_services do
    {:ok, result} = Couchex.fetch_view(services(), {"services", "data"}, [])
    map_response(result)
  end

  def get_service(service_code) do
    result = Couchex.open_doc(services(), %{id: service_code})
    map_response(result)
  end

  ###  SERVICE REQUESTS ###

  @doc ~S"""
  Gets a connection to the open311_service_requests couchdb database
  """
  def service_requests() do
    {:ok, db} = Couchex.open_db(server(), config()[:service_requests_db])
    db
  end
  
  def create_service_request(data) when is_map(data) do
    uuid = Couchex.uuid(server())
    now = timestamp()
    defaults = %{
      "_id" => uuid,
      service_request_id: uuid,
      status: "open",
      status_notes: "",
      description: "",
      agency_responsible: "",
      service_notice: "",
      requested_datetime: now,
      updated_datetime: now,
      expected_datetime: "",
      address: "",
      address_id: "",
      lat: "",
      long: "",
      media_url: "",
      zipcode: ""
    }
    {:ok, result} = Couchex.save_doc(service_requests(), Map.merge(defaults, data))
    map_response(result)
  end

  def find_service_requests(params) do
    case params[:service_request_id] do
      nil ->
        selectors = []

        # build selectors for time range
        start_date = params[:start_date]
        end_date = params[:end_date]
        date_selectors =
          cond do
            start_date != nil and end_date != nil ->
              [{"$and", [%{"requested_datetime": %{"$gte": start_date}},
                         %{"requested_datetime": %{"$lte": end_date}}]}]
            start_date == nil and end_date != nil ->
              [{"requested_datetime", %{"$lte": end_date}}]
            start_date != nil and end_date == nil ->
              [{"requested_datetime", %{"$gte": start_date}}]
            true ->
              []
          end

        # build selector for the service code
        service_code = params[:service_code]
        service_code_selector = if service_code != nil do
          [{"service_code", %{"$in": String.split(service_code, [" ", ","], trim: true)}}]
        else
          []
        end

        # build selector for the status
        status = params[:status]
        status_selector = if status != nil do
          [{"status", %{"$in": String.split(status, [" ", ","], trim: true)}}]
        else
          []
        end

        selectors = Enum.into(selectors ++ date_selectors ++ service_code_selector ++ status_selector, %{})
        Couchex.find(service_requests(), %{"selector" => selectors})
      id ->
        [Couchex.open_doc(service_requests(), %{id: id})]
    end
  end

  ###  PRIVATE  ###

  defp map_response({list}) when is_list(list), do: Enum.map(list, fn {k, v} -> {k, map_response(v)} end) |> Enum.into(%{})
  defp map_response(list) when is_list(list), do: Enum.map(list, fn x -> map_response(x) end)
  defp map_response(response), do: response

  defp config do
    Application.get_env(:ex_open311, :couchdb)
  end

  @doc ~S"""
  Returns a w3 timestamp to the nearest second, i.e.

  2017-05-28T17:28:52Z
  """
  def timestamp do
    DateTime.utc_now
    |> Map.put(:microsecond, {0,0})
    |> DateTime.to_iso8601
  end
end
