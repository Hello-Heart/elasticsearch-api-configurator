# Elasticsearch API Configurator

A small Ruby utility for api-requests against elasticsearch/kibana,
used to configure settings, rbac and other api operations, to manage cluster with infrastructure-as-code methodology.  


### Local Development and Usage
The provided docker-compose should support building and running via command line against interface listening on localhost:  
- Build: `docker compose build`
- Run:   `BASIC_AUTH_USERNAME=<api_username> BASIC_AUTH_PASSWORD=<api_pass>  docker compose up`  
