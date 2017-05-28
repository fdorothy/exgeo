# ExGeo

**NOTE THAT THIS IS A WORK IN PROGRESS AND NOT FUNCTIONAL**

This is an elixir implementation of open311 (http://open311.org)'s GeoReport v2.

You can read the full specification here: http://wiki.open311.org/GeoReport_v2

This project uses couchdb.

## Installation

```
git clone https://github.com/fdorothy/exgeo.git exgeo
cd exgeo
mix deps.get
```

Danger: only do the next steps if you want to create new databases on couchdb. This will blow away
any database in your installation called exgeo_service_test and exgeo_service_requests_test.

```
# create the databases used for unit tests
export MIX_ENV=test
mix init_db

# create the databases used for production
export MIX_ENV=prod
mix init_db
```

## Running tests

There are several unit tests that by default use the exgeo_services_test and exgeo_service_requests_test
couchdb databases. You can change this in config/test.exs, as well as picking which couchdb host to
connect to. You should have admin access, as these tests *will* recreate the databases in the process
of testing.

```
export MIX_ENV=test
mix test
```

## Using the API

By default the GeoReport v2 API is run at http://127.0.0.1:8880/. Some simple tests can be done with curl to make sure everything is running properly:

```
# get available services for service requests
curl -X GET http://127.0.0.1:8880/services.json
```