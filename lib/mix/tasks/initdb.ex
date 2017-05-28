defmodule Mix.Tasks.InitDb do
  use Mix.Task

  @shortdoc "creates and initializes couchdb for exgeo"

  def run(_) do
    Mix.Tasks.App.Start.run([])
    ExGeo.Server.recreate
  end
end
