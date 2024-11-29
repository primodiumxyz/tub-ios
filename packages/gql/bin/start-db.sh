#!/bin/bash

docker-compose up &

# Store the process ID of the background docker-compose up command
COMPOSE_PID=$!

# Define the health check endpoints
HASURA_HEALTH_CHECK_URL="http://localhost:8080/healthz?strict=true"
TIMESCALE_HEALTH_CHECK="docker exec timescaledb pg_isready -U indexer_user -d indexer"

# Define the number of retries and delay between checks
RETRIES=100
DELAY=5

# Function to check Hasura health
check_hasura_health() {
  RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" $HASURA_HEALTH_CHECK_URL)
  if [ "$RESPONSE" -eq 200 ]; then
    return 0  # Success
  else
    return 1  # Failure
  fi
}

# Function to check TimescaleDB health
check_timescale_health() {
  if $TIMESCALE_HEALTH_CHECK > /dev/null 2>&1; then
    return 0  # Success
  else
    return 1  # Failure
  fi
}

# Wait for both services to be healthy
echo "Waiting for services to be healthy..."
for ((i=1; i<=$RETRIES; i++)); do
  HASURA_HEALTHY=false
  TIMESCALE_HEALTHY=false

  if check_hasura_health; then
    HASURA_HEALTHY=true
    echo "Hasura is healthy!"
  fi

  if check_timescale_health; then
    TIMESCALE_HEALTHY=true
    echo "TimescaleDB is healthy!"
  fi

  if [ "$HASURA_HEALTHY" = true ] && [ "$TIMESCALE_HEALTHY" = true ]; then
    echo "All services are healthy!"
    
    # Run migrations for both databases
    echo "Running Hasura migrations..."
    pnpm hasura:local:seed-apply
    pnpm hasura:local:console
    
    echo "Running TimescaleDB migrations..."
    NODE_PATH=./node_modules \
    DATABASE_URL="postgres://indexer_user:${TIMESCALE_DB_PASSWORD}@localhost:5433/indexer" \
      pnpm timescale:local:migrate up
    
    echo "Generating types..."
    TIMESCALE_DB_PASSWORD=${TIMESCALE_DB_PASSWORD} pnpm timescale:generate:types
    
    break
  else
    echo "Health check failed. Retrying in $DELAY seconds..."
    sleep $DELAY
  fi

  # If this is the last retry, print failure message
  if [ "$i" -eq "$RETRIES" ]; then
    echo "Services did not become healthy after $RETRIES attempts. Exiting..."
    docker-compose down --volumes --remove-orphans
    exit 1
  fi
done

# Trap SIGINT (Ctrl+C) and SIGHUP (terminal close)
trap 'echo "Stopping containers..."; docker-compose down --volumes; exit' SIGINT SIGHUP

# Wait for docker-compose up to complete
wait $COMPOSE_PID