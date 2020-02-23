POSTGRES_IMAGE := postgres:12-alpine
POSTGRES_CONTAINER := postgres_db
POSTGRES_DATA := postgres_data
POSTGRES_PORT=5432
POSTGRES_USER=postgres
POSTGRES_PASS=postgres

REDIS_IMAGE := redis:5-alpine
REDIS_CONTAINER := redis_db
REDIS_DATA := redis_data
REDIS_DB_PORT := 6379

.DEFAULT_GOAL := help

.PHONY: db redis start stop help

help: ## This help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-z%A-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

db: db-start ## Run db:start

db%start: ## Run a postgres container on locaohost:5432
	${INFO} 'Running postgres container on localhost:$(POSTGRES_PORT) ...'
	@ docker run --rm -d --name=$(POSTGRES_CONTAINER) -v $(POSTGRES_DATA):/var/lib/postgresql/data -p $(POSTGRES_PORT):5432 -e POSTGRES_USER=$(POSTGRES_USER) -e POSTGRES_PASSWORD=$(POSTGRES_PASSWORD) $(POSTGRES_IMAGE)
	${INFO} "Postgres is running"

db%stop: ## Stop and remove a postgres container
	${INFO} "Stoping db container ..."
	@ docker stop $(POSTGRES_CONTAINER)
	${INFO} "Done"

db%exec: ## Connect to a running postgres container for executing commands; run shell by default
	${INFO} "Connect to running db container ..."
	@ docker exec -it $(POSTGRES_CONTAINER) sh

# https://github.com/petere/homebrew-postgresql/issues/51
db%psql:
	@ psql -h localhost -p $(POSTGRES_PORT) -U postgres

db%pgcli:
	@ PGGSSENCMODE=disable pgcli -h localhost -p $(POSTGRES_PORT) -U postgres

redis: redis-start

redis%start: ## Start a redis container
	${INFO} "Running redis container on localhost:$(REDIS_DB_PORT) ..."
	@ docker run --rm -d --name=$(REDIS_CONTAINER) -v $(REDIS_DATA):/data -p $(REDIS_DB_PORT):6379 $(REDIS_IMAGE) redis-server --appendonly yes
	${INFO} "Redis is running"

redis%stop: ## Stop a redis container
	${INFO} "Stoping redis container ..."
	@ docker stop $(REDIS_CONTAINER)
	${INFO} "Done"

start: db-start redis-start ## Start all services (postgres, redis)
stop: db-stop redis-stop ## Stop all services (postgres, redis)

%:
	@:

# Cosmetic
YELLOW := "\e[1;33m"
NC := "\e[0m"
INFO := @bash -c ' printf $(YELLOW); echo "=> $$1"; printf $(NC)' VALUE
