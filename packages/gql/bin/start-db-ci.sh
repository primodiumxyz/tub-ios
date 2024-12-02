#!/bin/bash

docker-compose up &

# Store the process ID of the background docker-compose up command
COMPOSE_PID=$!

# Define the health check endpoints
HASURA_HEALTH_CHECK_URL="http://localhost:8080/healthz?strict=true"
TIMESCALE_HEALTH_CHECK="docker exec timescaledb pg_isready -U tsdbadmin -d indexer"
PGADMIN_HEALTH_CHECK="curl -s http://localhost:5050/misc/ping"

# Define the number of retries and delay between checks
RETRIES=100
DELAY=5

# Start pgAdmin console
echo "Starting pgAdmin console..."
docker run -d \
  -p 5050:80 \
  -e PGADMIN_DEFAULT_EMAIL=admin@admin.com \
  -e PGADMIN_DEFAULT_PASSWORD=admin \
  -e PGADMIN_CONFIG_SERVER_MODE=False \
  -e PGADMIN_CONFIG_MASTER_PASSWORD_REQUIRED=False \
  -e PGADMIN_CONFIG_ENHANCED_COOKIE_PROTECTION=False \
  -v "$(pwd)/pgadmin-servers.json:/pgadmin4/servers.json" \
  --name pgadmin \
  dpage/pgadmin4

# Function to check Hasura health
check_hasura_health() {
  RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" $HASURA_HEALTH_CHECK_URL)
  [ "$RESPONSE" -eq 200 ]
}

# Function to check TimescaleDB health
check_timescale_health() {
  $TIMESCALE_HEALTH_CHECK > /dev/null 2>&1
}

# Function to check pgAdmin health
check_pgadmin_health() {
  $PGADMIN_HEALTH_CHECK > /dev/null 2>&1
}

# Function to cleanup
cleanup() {
  echo "Stopping containers..."
  # Stop pgAdmin first
  docker stop pgadmin 2>/dev/null
  docker rm pgadmin 2>/dev/null
  # Then stop all other containers
  docker-compose down --volumes --remove-orphans
  exit 0
}

# Trap SIGINT (Ctrl+C) and SIGHUP (terminal close)
trap cleanup SIGINT SIGHUP

# Wait for TimescaleDB and pgAdmin to be healthy
echo "Waiting for TimescaleDB and pgAdmin to be healthy..."
for ((i=1; i<=$RETRIES; i++)); do
  TIMESCALE_HEALTHY=false
  PGADMIN_HEALTHY=false

  if check_timescale_health; then
    TIMESCALE_HEALTHY=true
    echo "TimescaleDB is healthy!"
  fi

  if check_pgadmin_health; then
    PGADMIN_HEALTHY=true
    echo "pgAdmin is healthy!"
  fi

  if [ "$TIMESCALE_HEALTHY" = true ] && [ "$PGADMIN_HEALTHY" = true ]; then
    echo "Running TimescaleDB migrations..."
    NODE_PATH=./node_modules \
    DATABASE_URL="postgres://tsdbadmin:password@localhost:5433/indexer" \
      pnpm timescale:local:migrate

    echo "Syncing TimescaleDB schema..."
    pnpm timescale:local:sync

    echo "Generating types..."
    pnpm timescale:generate:types

    # Start Hasura after TimescaleDB setup
    docker-compose up -d graphql-engine

    # Wait for Hasura to be healthy
    for ((j=1; j<=$RETRIES; j++)); do
      if check_hasura_health; then
        echo "Hasura is healthy!"

        echo "Applying Hasura metadata..."
        pnpm hasura:local:seed-apply
        
        echo "All services are healthy!"
        break 2
      else
        echo "Waiting for Hasura to be healthy..."
        sleep $DELAY
      fi
    done
  else
    echo "Health check failed. Retrying in $DELAY seconds..."
    sleep $DELAY
  fi

  # If this is the last retry, print failure message and cleanup
  if [ "$i" -eq "$RETRIES" ]; then
    echo "Services did not become healthy after $RETRIES attempts. Exiting..."
    cleanup
  fi
done

# Wait for docker-compose
wait $COMPOSE_PID