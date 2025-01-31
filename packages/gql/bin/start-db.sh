#!/bin/bash

# Parse command line arguments
CI_MODE=false
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --ci) CI_MODE=true ;;
    *) echo "Unknown parameter: $1"; exit 1 ;;
  esac
  shift
done

# Start services first
if [ "$CI_MODE" = true ]; then
  docker-compose up -d &
else
  docker-compose up &
fi

# Store the process ID of the background docker-compose up command
COMPOSE_PID=$!

# Define the health check endpoints
# This url reaches Hasura through the cache server so it verifies both health
HASURA_HEALTH_CHECK_URL="http://localhost:8090/healthz?strict=true"
TIMESCALE_HEALTH_CHECK="docker exec timescaledb pg_isready -U tsdbadmin -d indexer"

# Define the number of retries and delay between checks
RETRIES=100
DELAY=5

# Function to check Hasura health
check_hasura_health() {
  RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" $HASURA_HEALTH_CHECK_URL)
  [ "$RESPONSE" -eq 200 ]
}
# Function to check TimescaleDB health
check_timescale_health() {
  $TIMESCALE_HEALTH_CHECK > /dev/null 2>&1
}

# Wait for TimescaleDB to be healthy
echo "Waiting for TimescaleDB & Hasura to be healthy..."
for ((i=1; i<=$RETRIES; i++)); do
  TIMESCALE_HEALTHY=false
  HASURA_HEALTHY=false

  if check_timescale_health; then
    TIMESCALE_HEALTHY=true
    echo "TimescaleDB is healthy!"
  fi

  if check_hasura_health; then
    HASURA_HEALTHY=true
    echo "Hasura is healthy!"
  fi

  if [ "$TIMESCALE_HEALTHY" = true ] && [ "$HASURA_HEALTHY" = true ]; then
    echo "All services are healthy!"

    echo "Applying Hasura metadata..."
    pnpm db:local:seed-apply

    # Start console only in non-CI mode
    if [ "$CI_MODE" = false ]; then
      echo "Starting Hasura console..."
      pnpm db:local:console &
    fi

    break
  else
    echo "Health check failed. Retrying in $DELAY seconds..."
    sleep $DELAY
  fi

  # If this is the last retry, print failure message and cleanup
  if [ "$i" -eq "$RETRIES" ]; then
    echo "Services did not become healthy after $RETRIES attempts. Exiting..."
    docker-compose down --volumes --remove-orphans
    exit 1
  fi
done

# Trap SIGINT (Ctrl+C) and SIGHUP (terminal close)
trap 'echo "Stopping containers..."; docker-compose down --volumes --remove-orphans; exit' SIGINT SIGHUP

# Wait for docker-compose
wait $COMPOSE_PID