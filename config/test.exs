use Mix.Config

config :exgeo, couchdb: [
  server: "http://localhost:5984",
  auth: nil,
  services_db: "exgeo_services_test",
  service_definitions_db: "exgeo_service_definitions_test",
  service_requests_db: "exgeo_service_requests_test",
]
