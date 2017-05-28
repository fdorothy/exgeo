use Mix.Config

config :ex_open311, couchdb: [
  server: "http://localhost:5984",
  auth: nil,
  services_db: "open311_services_test",
  service_requests_db: "open311_service_requests_test",
]
