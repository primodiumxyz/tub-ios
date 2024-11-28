#!/bin/bash

docker-compose up &

# Store the process ID of the background docker-compose up command
COMPOSE_PID=$!

# Define the health check endpoint
HEALTH_CHECK="docker exec timescaledb pg_isready -U indexer_user"

# Define the number of retries and delay between checks
RETRIES=100
DELAY=5

# Function to check the health
check_health() {
  if $HEALTH_CHECK > /dev/null 2>&1; then
    return 0  # Success
  else
    return 1  # Failure
  fi
}

# Wait for the service to be healthy
echo "Waiting for TimescaleDB to be healthy..."
for ((i=1; i<=$RETRIES; i++)); do
  if check_health; then
    echo "TimescaleDB is healthy!"
    # Run migrations and generate types
    NODE_PATH=./node_modules \
    DATABASE_URL="postgres://indexer_user:${TIMESCALE_DB_PASSWORD}@localhost:5433/indexer" \
      pnpm migrate up
    
    TIMESCALE_DB_PASSWORD=${TIMESCALE_DB_PASSWORD} pnpm generate:types
    break
  else
    echo "Health check failed. Retrying in $DELAY seconds..."
    sleep $DELAY
  fi

  # If this is the last retry, print failure message
  if [ "$i" -eq "$RETRIES" ]; then
    echo "TimescaleDB did not become healthy after $RETRIES attempts. Exiting..."
    docker-compose down --volumes --remove-orphans
    exit 1
  fi
done

# Trap SIGINT (Ctrl+C) and SIGHUP (terminal close)
trap 'echo "Stopping containers..."; docker-compose down --volumes; exit' SIGINT SIGHUP

# Wait for docker-compose up to complete
wait $COMPOSE_PID