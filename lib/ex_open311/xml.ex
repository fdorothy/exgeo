defmodule ExOpen311.Xml do
  import XmlBuilder

  def services_to_xml(services) do
    xml_list(services, "services", "service", fn {k, v} ->
      element(k, v)
    end)
  end

  def xml_list(list, parent_tag, child_tag, child_mapper) do
    element(parent_tag,
      Enum.map(list, fn child ->
	element(child_tag, child_fun.(child))
      end))
  end
end
