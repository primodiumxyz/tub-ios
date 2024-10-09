#!/bin/bash

# Start the docker-compose up process in detached mode
docker-compose up &

# Store the process ID of the background docker-compose up command
COMPOSE_PID=$!

# Define the health check endpoint
HEALTH_CHECK_URL="http://localhost:8080/healthz?strict=true"

# Define the number of retries and delay between checks
RETRIES=100
DELAY=5

# Function to check the health endpoint
check_health() {
  RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" $HEALTH_CHECK_URL)
  if [ "$RESPONSE" -eq 200 ]; then
    return 0  # Success
  else
    return 1  # Failure
  fi
}

# Wait for the service to be healthy
echo "Waiting for the service to be healthy..."
for ((i=1; i<=$RETRIES; i++)); do
  if check_health; then
    echo "Service is healthy!"
    pnpm db:local:seed-apply
    pnpm db:local:console
    break
  else
    echo "Health check failed. Retrying in $DELAY seconds..."
    sleep $DELAY
  fi

  # If this is the last retry, print failure message
  if [ "$i" -eq "$RETRIES" ]; then
    echo "Service did not become healthy after $RETRIES attempts. Exiting..."
    docker-compose down --volumes --remove-orphans
    exit 1
  fi
done

# Trap SIGINT (Ctrl+C) and SIGHUP (terminal close)
trap 'echo "Stopping containers..."; docker-compose down --volumes; exit' SIGINT SIGHUP

# Wait for docker-compose up to complete
wait $COMPOSE_PID
