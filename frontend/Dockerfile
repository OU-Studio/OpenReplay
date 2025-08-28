# ---------- Stage 1: Build ----------
FROM node:20-bullseye-slim AS builder
WORKDIR /work

# Tools for native builds + git deps
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      git python3 build-essential ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# Copy manifests first
COPY package.json package-lock.json* yarn.lock* ./

# If using private registry, uncomment and pass --build-arg NPM_TOKEN=xxxxx
# ARG NPM_TOKEN
# RUN if [ -n "$NPM_TOKEN" ]; then printf "//registry.npmjs.org/:_authToken=${NPM_TOKEN}\n" > .npmrc; fi

# Detect Yarn lockfile type and install deps
# - If yarn.lock starts with "yarn lockfile v1", use Yarn classic (1.x)
# - Else use Corepack default (Berry)
RUN set -eux; \
  if [ -f yarn.lock ]; then \
    head -n 1 yarn.lock || true; \
    corepack enable; \
    if head -n 1 yarn.lock | grep -qi "yarn lockfile v1"; then \
      echo "Using Yarn classic (1.x)"; \
      corepack prepare yarn@1.22.22 --activate; \
      yarn --version; \
      yarn install --frozen-lockfile; \
    else \
      echo "Using Yarn Berry"; \
      yarn --version; \
      yarn install --immutable; \
    fi; \
  else \
    echo "No yarn.lock, using npm"; \
    npm config set fund false; \
    npm config set audit false; \
    if [ -f package-lock.json ]; then npm ci; else npm i; fi; \
  fi

# Copy source and build
COPY . .

# If .env doesn’t exist but .env.sample does, copy it
RUN [ -f .env ] || { [ -f .env.sample ] && cp .env.sample .env || true; }

# Build (supports Yarn or npm)
RUN set -eux; \
  if [ -f yarn.lock ]; then yarn build; else npm run build; fi

# Normalize build output into /out (supports dist/ or public/)
RUN set -eux; \
  mkdir -p /out; \
  if [ -d dist ]; then cp -a dist/. /out/; \
  elif [ -d public ]; then cp -a public/. /out/; \
  else echo "❌ No build output found (expected dist/ or public/)"; ls -la; exit 1; fi

# ---------- Stage 2: Runtime (Nginx) ----------
FROM nginx:1.27-alpine

# Remove default configs so only ours loads
RUN rm -f /etc/nginx/conf.d/* /etc/nginx/http.d/* || true

# Static files
COPY --from=builder /out/ /usr/share/nginx/html/

# Your nginx.conf must live next to this Dockerfile (see below)
COPY nginx.conf /etc/nginx/nginx.conf

# Validate nginx config at build time
RUN nginx -t -c /etc/nginx/nginx.conf

EXPOSE 8080
CMD ["nginx","-g","daemon off;"]
