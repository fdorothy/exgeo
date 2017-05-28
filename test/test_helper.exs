if Mix.env == :test do
  Mix.Task.run "init_db"
else
  raise "tests must be run in test mode"
end

ExUnit.start()
Maru.Test.start()
