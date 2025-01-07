FROM redis/redis-stack-server:latest as redis
FROM node:21.4.0-bookworm-slim
ENV NODE_ENV=production

# Install SSL dependencies
RUN apt-get update && \
    apt-get install -y openssl libssl3 && \
    rm -rf /var/lib/apt/lists/*

# Copy Redis configuration and modules from Redis Stack image
COPY --from=redis /opt/redis-stack /opt/redis-stack
COPY --from=redis /usr/local/bin/redis* /usr/local/bin/

# Add Redis Stack to PATH
ENV PATH="/opt/redis-stack/bin:$PATH"

ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"

# Build dependencies
RUN corepack enable
WORKDIR /app

# Copy root package.json, pnpm-workspace.yaml, and pnpm-lock.yaml
COPY package.json pnpm-workspace.yaml pnpm-lock.yaml ./
COPY .tsconfigs/bundler/dom/library-monorepo.json /app/.tsconfigs/bundler/dom/library-monorepo.json

# Copy the gql package
COPY packages/gql ./packages/gql

# Install dependencies without dev dependencies
RUN pnpm install --frozen-lockfile --filter @tub/gql

WORKDIR /app/packages/gql

ENV REDIS_PORT=8091

# Create a script to wait for Redis to be ready
RUN echo '#!/bin/sh\n\
MAX_RETRIES=30\n\
RETRY_INTERVAL=1\n\
\n\
for i in $(seq 1 $MAX_RETRIES); do\n\
    if redis-cli ping > /dev/null 2>&1; then\n\
        echo "Redis is ready!"\n\
        exit 0\n\
    fi\n\
    echo "Waiting for Redis... (attempt $i/$MAX_RETRIES)"\n\
    sleep $RETRY_INTERVAL\n\
done\n\
\n\
echo "Redis failed to start after $MAX_RETRIES attempts"\n\
exit 1' > /wait-for-redis.sh && chmod +x /wait-for-redis.sh

# Create startup script
RUN echo '#!/bin/sh\n\
/opt/redis-stack/bin/redis-stack-server --port $REDIS_PORT & \n\
/wait-for-redis.sh\n\
if [ $? -eq 0 ]; then\n\
    exec pnpm start:cache\n\
else\n\
    echo "Failed to start Redis"\n\
    exit 1\n\
fi' > /start.sh && chmod +x /start.sh

# Use the startup script as the entry point
CMD ["/start.sh"]
