defmodule ExGeo.ServerTest do
  use ExUnit.Case, async: false
  alias ExGeo.Server

  @lat_long_service_request %{
    jurisdiction_id: "city.gov",
    service_code: "001",
    lat: "37.76524078",
    long: "-122.4212043",
    address_string: "1234 5th street",
    email: "noone@localhost",
    device_id: "tt222111",
    account_id: "123456",
    first_name: "john",
    last_name: "smith",
    phone: "111111111",
    description: "A large sinkhole is destroying the street",
    media_url: "http://localhost/sinkhole.jpg",
    requested_datetime: "2017-05-05T00:00:00Z",
    updated_datetime: "2017-05-05T00:00:00Z",
    attributes: %{
      "WHISPAWN" => "123456",
      "WHISDORN" => "COISL001"
    }
  }

  setup do
    ExGeo.Server.recreate
    :ok
  end

  def seed_services do
    assert [] = Server.get_services()
    Server.create_service("001", "Cans left out", "Garbage or recyling cans left out", "street")
    Server.create_service("002", "Noise complaint", "Noises after 10pm", "police")
    Server.create_service("003", "Road damage", "Potholes, trees down", "street")
  end

  test "create and get services" do
    assert [] = Server.get_services()
    Server.create_service("001", "Cans left out", "Garbage or recyling cans left out", "street")
    assert [result] = Server.get_services()
    info = result["value"]
    assert info["service_code"] == "001"
    assert info["service_name"] == "Cans left out"
    assert info["description"] == "Garbage or recyling cans left out"
    refute info["metadata"]
    assert info["type"] == "realtime"
    assert info["keywords"] == ""
    assert info["group"] == "street"

    service = Server.get_service("001")
    assert service["_id"] == "001"
  end

  test "get service definitions" do
    Enum.map(~w(100 100 101 102), fn x ->
      Server.create_service_definition(%{data: %{service_code: x}})
    end)
    assert length(Server.get_service_definitions("100")) == 2
    assert length(Server.get_service_definitions("101")) == 1
    assert length(Server.get_service_definitions("102")) == 1
  end

  test "create a service request by latitude / longitude" do
    result = Server.create_service_request(@lat_long_service_request)
    assert Map.has_key?(result, "_id")
  end

  test "get a service request by id" do
    result = Server.create_service_request(@lat_long_service_request)
    [info] = Server.find_service_requests(%{service_request_id: result["_id"]})
    expected = %{
      "_id" => result["_id"],
      "_rev" => result["_rev"],
      "service_request_id" => result["_id"],
      "status" => "open",
      "status_notes" => "",
      "service_code" => "001",
      "description" => "A large sinkhole is destroying the street",
      "agency_responsible" => "",
      "service_notice" => "",
      "requested_datetime" => "2017-05-05T00:00:00Z",
      "updated_datetime" => "2017-05-05T00:00:00Z",
      "expected_datetime" => "",
      "address" => "",
      "address_string" => "1234 5th street",
      "address_id" => "",
      "zipcode" => "",
      "lat" => "37.76524078",
      "long" => "-122.4212043",
      "media_url" => "http://localhost/sinkhole.jpg",
      "account_id" => "123456",
      "jurisdiction_id" => "city.gov",
      "first_name" => "john",
      "last_name" => "smith",
      "email" => "noone@localhost",
      "device_id" => "tt222111",
      "phone" => "111111111",
      "attributes" => %{
        "WHISPAWN" => "123456",
        "WHISDORN" => "COISL001"
      }
    }
    assert info == expected
  end

  test "searching for service requests" do
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

    # get by service request id
    [result] = ExGeo.Server.find_service_requests(service_request_id: r1["_id"])
    assert result["_id"] == r1["_id"]
    [result] = ExGeo.Server.find_service_requests(service_request_id: r3["_id"])
    assert result["_id"] == r3["_id"]

    # find by service code(s)
    [result] = ExGeo.Server.find_service_requests(service_code: "001")
    assert result["_id"] == r1["_id"]
    [result] = ExGeo.Server.find_service_requests(service_code: "002")
    assert result["_id"] == r2["_id"]
    [sr1, sr2] = ExGeo.Server.find_service_requests(service_code: "002, 001")
    ids = [sr1["_id"], sr2["_id"]]
    assert r1["_id"] in ids
    assert r2["_id"] in ids

    # find by status
    [sr1, sr2] = ExGeo.Server.find_service_requests(status: "open, wip")
    ids = [sr1["_id"], sr2["_id"]]
    assert r1["_id"] in ids
    assert r3["_id"] in ids

    # find after start time
    [sr1] = ExGeo.Server.find_service_requests(start_date: "2017-02-01T00:00:00Z")
    assert sr1["_id"] == r2["_id"]
    [sr1, sr2] = ExGeo.Server.find_service_requests(start_date: "2017-01-01T00:00:00Z")
    ids = [sr1["_id"], sr2["_id"]]
    assert r2["_id"] in ids
    assert r1["_id"] in ids

    # find before end time
    [sr1] = ExGeo.Server.find_service_requests(end_date: "2017-01-01T00:00:00Z")
    assert sr1["_id"] == r3["_id"]

    # find in time range
    [sr1] = ExGeo.Server.find_service_requests(%{
      start_date: "2017-01-01T00:00:00Z",
      end_date: "2017-01-30T00:00:00Z"
    })
    assert sr1["_id"] == r1["_id"]
  end

  @doc ~S"""
  Returns a w3 timestamp to the nearest second, i.e.

  2017-05-28T17:28:52Z
  """
  def timestamp(datetime) do
    datetime
    |> Map.put(:microsecond, {0,0})
    |> DateTime.to_iso8601
  end

  def timestamp(), do: timestamp(DateTime.utc_now)
end
