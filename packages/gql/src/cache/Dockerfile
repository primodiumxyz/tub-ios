FROM node:21.4.0-bookworm-slim
ENV NODE_ENV=production

# Install Redis
RUN apt update \
  && apt install --assume-yes --no-install-recommends \
  redis-server

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

# Start Redis and the cache server
CMD service redis-server start && pnpm start:cache
