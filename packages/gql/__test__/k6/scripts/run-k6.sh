#!/bin/bash

# Parse command line arguments
SKIP_SEED=false
ENV="local"
while getopts "se:" opt; do
  case $opt in
    s) SKIP_SEED=true ;;
    e) ENV="$OPTARG" ;;
    *) echo "Usage: $0 [-s] [-e env]" >&2
       echo "  -s: Skip seeding" >&2
       echo "  -e: Environment (local or remote)" >&2
       exit 1 ;;
  esac
done

# Get the absolute path to the project root
PROJECT_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"

# Start services first
cd "$(dirname "$0")/.." && docker-compose -f docker-compose.k6.yml up -d &

# Store the process ID of the background docker-compose up command
COMPOSE_PID=$!

# Define health check endpoints
PROMETHEUS_HEALTH_CHECK_URL="http://localhost:9090/-/healthy"
INFLUXDB_HEALTH_CHECK_URL="http://localhost:8086/ping"
GRAFANA_HEALTH_CHECK_URL="http://localhost:3001/api/health"

# Define retries and delay
RETRIES=30
DELAY=5

# Function to check Prometheus health
check_prometheus_health() {
  RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" $PROMETHEUS_HEALTH_CHECK_URL)
  [ "$RESPONSE" -eq 200 ]
}

# Function to check InfluxDB health
check_influxdb_health() {
  RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" $INFLUXDB_HEALTH_CHECK_URL)
  [ "$RESPONSE" -eq 204 ]
}

# Function to check Grafana health
check_grafana_health() {
  RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" $GRAFANA_HEALTH_CHECK_URL)
  [ "$RESPONSE" -eq 200 ]
}

# Create metrics directory
mkdir -p metrics

# Wait for services to be healthy
echo "Waiting for services to be healthy..."
for ((i=1; i<=$RETRIES; i++)); do
  PROMETHEUS_HEALTHY=false
  INFLUXDB_HEALTHY=false
  GRAFANA_HEALTHY=false

  if check_prometheus_health; then
    PROMETHEUS_HEALTHY=true
    echo "Prometheus is healthy!"
  fi

  if check_influxdb_health; then
    INFLUXDB_HEALTHY=true
    echo "InfluxDB is healthy!"
  fi

  if check_grafana_health; then
    GRAFANA_HEALTHY=true
    echo "Grafana is healthy!"
  fi

  if [ "$PROMETHEUS_HEALTHY" = true ] && [ "$INFLUXDB_HEALTHY" = true ] && [ "$GRAFANA_HEALTHY" = true ]; then
    echo "All services are healthy!"

    if [ "$SKIP_SEED" = false ]; then
      echo "Seeding database..."
      cd "$PROJECT_ROOT"
      # Run seed script with output
      pnpm tsx __test__/k6/scripts/seed.ts 2>&1
      SEED_EXIT_CODE=$?
      if [ $SEED_EXIT_CODE -ne 0 ]; then
        echo "Seeding failed with exit code $SEED_EXIT_CODE!"
        exit 1
      fi
      echo "Seeding completed successfully!"
    else
      echo "Skipping database seed..."
    fi

    # Run k6 tests based on environment
    echo "Running k6 tests for $ENV environment..."
    if [ "$ENV" = "local" ]; then
      HASURA_URL=http://localhost:8090/v1/graphql HASURA_ADMIN_SECRET=password k6 run --compatibility-mode=experimental_enhanced --out influxdb=http://localhost:8086/k6 __test__/k6/scripts/load-test.ts | tee metrics/k6-output.txt
    else
      dotenvx run -f ./.env --quiet -- k6 run --compatibility-mode=experimental_enhanced --out influxdb=http://localhost:8086/k6 __test__/k6/scripts/load-test.ts | tee metrics/k6-output.txt
    fi

    # Open Grafana dashboard
    echo "Opening Grafana dashboard..."
    open "http://localhost:3001/d/k6-performance/k6-performance-dashboard?orgId=1&from=now-5m&to=now&timezone=browser"

    break
  else
    echo "Health check failed. Retrying in $DELAY seconds..."
    sleep $DELAY
  fi

  # If this is the last retry, print failure message and cleanup
  if [ "$i" -eq "$RETRIES" ]; then
    echo "Services did not become healthy after $RETRIES attempts. Exiting..."
    cd "$(dirname "$0")/.." && docker-compose -f docker-compose.k6.yml down --volumes --remove-orphans
    exit 1
  fi
done

# Trap SIGINT (Ctrl+C) and SIGHUP (terminal close)
trap 'echo "Stopping containers..."; cd "$(dirname "$0")/.." && docker-compose -f docker-compose.k6.yml down --volumes --remove-orphans && rm -rf output/tokens.json; exit' SIGINT SIGHUP

# Wait for docker-compose
wait $COMPOSE_PID 