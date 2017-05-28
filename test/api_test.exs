defmodule ExGeo.ApiTest do
  use ExUnit.Case, async: false
  use Maru.Test, for: ExGeo.API
  alias ExGeo.Server

  setup do
    ExGeo.Server.recreate
    :ok
  end

  test "GET /services.xml" do
    Server.create_service("001", "Cans left out", "Garbage cans left out", "street")
    Server.create_service("002", "Noise complaint", "Loud noise after 10pm", "police")
    result = request(:get, "/services.xml")
    assert result.status == 200
    headers = result.resp_headers |> Enum.into(%{})
    assert %{"content-type" => "text/xml; charset=utf-8"} = headers

    doc = Exml.parse(result.resp_body)
    assert Exml.get(doc, "//services/service[1]//service_code") == "001"
    assert Exml.get(doc, "//services/service[1]//service_name") == "Cans left out"
    assert Exml.get(doc, "//services/service[1]//description") == "Garbage cans left out"
    assert Exml.get(doc, "//services/service[1]//metadata") == "false"
    assert Exml.get(doc, "//services/service[1]//type") == "realtime"
    assert Exml.get(doc, "//services/service[1]//keywords") == nil
    assert Exml.get(doc, "//services/service[1]//group") == "street"

    assert Exml.get(doc, "//services/service[2]//service_code") == "002"
    assert Exml.get(doc, "//services/service[2]//service_name") == "Noise complaint"
    assert Exml.get(doc, "//services/service[2]//description") == "Loud noise after 10pm"
    assert Exml.get(doc, "//services/service[2]//metadata") == "false"
    assert Exml.get(doc, "//services/service[2]//type") == "realtime"
    assert Exml.get(doc, "//services/service[2]//keywords") == nil
    assert Exml.get(doc, "//services/service[2]//group") == "police"
  end

  test "GET /services.json" do
    Server.create_service("001", "Cans left out", "Garbage cans left out", "street")
    Server.create_service("002", "Noise complaint", "Loud noise after 10pm", "police")
    result = request(:get, "/services.json")
    assert result.status == 200
    headers = result.resp_headers |> Enum.into(%{})
    assert %{"content-type" => "application/json; charset=utf-8"} = headers

    [s1, s2] = Poison.decode!(result.resp_body)
    assert s1["service_code"] == "001"
    assert s1["service_name"] == "Cans left out"
    assert s1["description"] == "Garbage cans left out"
    assert s1["metadata"] == false
    assert s1["type"] == "realtime"
    assert s1["keywords"] == ""
    assert s1["group"] == "street"

    assert s2["service_code"] == "002"
    assert s2["service_name"] == "Noise complaint"
    assert s2["description"] == "Loud noise after 10pm"
    assert s2["metadata"] == false
    assert s2["type"] == "realtime"
    assert s2["keywords"] == ""
    assert s2["group"] == "police"
  end

  test "POST /requests using address_string" do
    request = %{
      jurisdiction_id: "city.gov",
      service_code: "001",
      address_string: "1234 5th street",
      description: "A large sinkhole is destroying the street",
    }
    result = request(:post, "/requests.json", request)
    assert result.status == 200
  end

  test "POST /requests using lat / long" do
    request = %{
      jurisdiction_id: "city.gov",
      service_code: "001",
      lat: "37.76524078",
      long: "-122.4212043",
      description: "A large sinkhole is destroying the street",
    }
    result = request(:post, "/requests.json", request)
    assert result.status == 200
  end

  test "POST /requests using address id" do
    request = %{
      jurisdiction_id: "city.gov",
      service_code: "001",
      address_id: "123456",
      description: "A large sinkhole is destroying the street",
    }
    result = request(:post, "/requests.json", request)
    assert result.status == 200
  end

  test "GET /requests" do
    # seed some services
    Server.create_service("001", "Cans left out", "Garbage or recyling cans left out", "street")
    Server.create_service("002", "Noise complaint", "Noises after 10pm", "police")
    Server.create_service("003", "Road damage", "Potholes, trees down", "street")

    # seed some requests
    request = %{
      service_code: "001",
      address_id: "123456",
      description: "A large sinkhole is destroying the street",
      requested_datetime: "2017-01-05T00:00:00Z"
    }
    r1 = Server.create_service_request(request)
    request = %{
      service_code: "002",
      address_id: "123456",
      description: "Loud noise in apartments next door",
      status: "closed",
      requested_datetime: "2017-02-06T00:00:00Z"
    }
    r2 = Server.create_service_request(request)
    request = %{
      service_code: "003",
      address_id: "123456",
      description: "Loud noise in apartments next door",
      status: "wip",
      requested_datetime: "2016-12-05T00:00:00Z"
    }
    r3 = Server.create_service_request(request)

    result = request(:get, "/requests.json")
    assert result.status == 200
    result = json_response(result)
    assert length(result) == 3

    # get by service request id
    result = request(:get, "/requests.json", %{service_request_id: r1["_id"]})
    assert result.status == 200
    assert [result] = json_response(result)
    assert result["service_request_id"] == r1["_id"]

    # find by service code(s)
    result = request(:get, "/requests.json", %{service_code: "001"})
    assert result.status == 200
    assert [result] = json_response(result)
    assert result["service_request_id"] == r1["_id"]
    result = request(:get, "/requests.json", %{service_code: "002, 001"})
    assert result.status == 200
    ids = json_response(result) |> Enum.map(&(&1["service_request_id"]))
    assert length(ids) == 2
    assert r1["_id"] in ids
    assert r2["_id"] in ids

    # find by status
    result = request(:get, "/requests.json", %{status: "open, wip"})
    assert result.status == 200
    ids = json_response(result) |> Enum.map(&(&1["service_request_id"]))
    assert length(ids) == 2
    assert r1["_id"] in ids
    assert r3["_id"] in ids

    # find after start time
    result = request(:get, "/requests.json", %{start_date: "2017-02-01T00:00:00Z"})
    assert result.status == 200
    ids = json_response(result) |> Enum.map(&(&1["service_request_id"]))
    assert ids == [r2["_id"]]
    result = request(:get, "/requests.json", %{start_date: "2017-01-01T00:00:00Z"})
    assert result.status == 200
    ids = json_response(result) |> Enum.map(&(&1["service_request_id"]))
    assert length(ids) == 2
    assert r2["_id"] in ids
    assert r1["_id"] in ids

    # # find before end time
    result = request(:get, "/requests.json", %{end_date: "2017-01-01T00:00:00Z"})
    assert result.status == 200
    ids = json_response(result) |> Enum.map(&(&1["service_request_id"]))
    assert ids == [r3["_id"]]

    # find in time range
    params = %{
      start_date: "2017-01-01T00:00:00Z",
      end_date: "2017-01-30T00:00:00Z"
    }
    result = request(:get, "/requests.json", params)
    assert result.status == 200
    ids = json_response(result) |> Enum.map(&(&1["service_request_id"]))
    assert ids == [r1["_id"]]
  end

  def conn do
    Maru.Test.build_conn
  end

  def request(method, path) do
    request(conn(), method, path, %{})
  end

  def request(method, path, params) do
    request(conn(), method, path, params)
  end

  def request(conn = %Plug.Conn{}, method, path, params) do
    conn
    |> Maru.Test.put_body_or_params(params)
    |> make_response(method, path)
  end
end
