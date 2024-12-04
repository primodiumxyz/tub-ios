#!/bin/bash

# Start services first
docker-compose up -d

# Store the process ID of the background docker-compose up command
COMPOSE_PID=$!

# Show logs in background while checking health
docker compose logs -f &
LOGS_PID=$!

# Define the health check endpoints
HASURA_HEALTH_CHECK_URL="http://localhost:8080/healthz?strict=true"
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

# Function to cleanup
cleanup() {
  echo "Stopping containers..."
  # Stop logs
  kill $LOGS_PID 2>/dev/null
  # Then stop all other containers
  docker-compose down --volumes --remove-orphans
  exit 0
}

# Trap SIGINT (Ctrl+C) and SIGHUP (terminal close)
trap cleanup SIGINT SIGHUP

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

    break
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