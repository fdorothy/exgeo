use Mix.Config

config :exgeo, couchdb: [
  server: "http://localhost:5984",
  auth: nil,
  services_db: "exgeo_services",
  service_definitions_db: "exgeo_service_definitions",
  service_requests_db: "exgeo_service_requests",
]
