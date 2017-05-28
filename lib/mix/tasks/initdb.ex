defmodule Mix.Tasks.InitDb do
  use Mix.Task

  @shortdoc "creates and initializes couchdb for ex_open311"

  def run(_) do
    Mix.Tasks.App.Start.run([])
    ExOpen311.Server.recreate
  end
end
