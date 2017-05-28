defmodule ExGeo.Xml do
  import XmlBuilder

  def services_to_xml(services) do
    xml_list(services, "services", "service", fn child ->
      Enum.map(child, fn {k, v} ->
	      element(k, v)
      end)
    end)
  end

  def service_requests_to_xml(service_requests) do
    xml_list(service_requests, "service_requests", "request", fn child ->
      Enum.map(child, fn {k, v} ->
	      element(k, v)
      end)
    end)
  end

  def xml_list(list, parent_tag, child_tag, child_mapper) do
    element(parent_tag,
      Enum.map(list, fn child ->
	      element(child_tag, child_mapper.(child))
      end))
  end
end
