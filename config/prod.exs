use Mix.Config

config :ex_open311, couchdb: [
  server: "http://localhost:5984",
  auth: nil,
  services_db: "open311_services",
  service_requests_db: "open311_service_requests",
]
