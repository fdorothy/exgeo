defmodule ExOpen311.ApiTest do
  use ExUnit.Case, async: false
  use Maru.Test, for: ExOpen311.API
  alias ExOpen311.Server

  setup do
    ExOpen311.Server.recreate
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
