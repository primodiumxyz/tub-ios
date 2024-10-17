FROM node:21.4.0-bookworm-slim
ENV NODE_ENV=production

# install build dependencies for bigint-buffer (https://solana.stackexchange.com/questions/4077/bigint-failed-to-load-bindings-pure-js-will-be-used-try-npm-run-rebuild-whe)
RUN apt update \
  && apt install --assume-yes --no-install-recommends \
  build-essential \
  python3

ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"

# Set a default port (can be overridden at runtime)
ENV SERVER_PORT=8080

# Build dependencies
RUN corepack enable
WORKDIR /app

# Copy root package.json, pnpm-workspace.yaml, and pnpm-lock.yaml
COPY package.json pnpm-workspace.yaml pnpm-lock.yaml ./
# Copy .tsconfigs/bundler/dom/library-monorepo.json and reproduce correct path
COPY .tsconfigs/bundler/dom/library-monorepo.json /app/.tsconfigs/bundler/dom/library-monorepo.json

# Copy the server app
COPY apps/server ./apps/server

# Copy any shared packages
COPY packages ./packages

# Install dependencies without dev dependencies and skip prepare scripts
RUN pnpm install --frozen-lockfile

# Set working directory to the server app
WORKDIR /app/apps/server

EXPOSE $SERVER_PORT

# Command to run the server
CMD ["pnpm", "start"]
