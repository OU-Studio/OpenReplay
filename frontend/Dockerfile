# ---------- Stage 1: Build ----------
FROM node:20-alpine AS builder
WORKDIR /work

# 1) Copy manifests first for proper caching
COPY package.json package-lock.json* yarn.lock* ./

# 2) Install deps (Yarn if yarn.lock exists, else npm). Print logs if it fails.
RUN set -eux; \
  if [ -f yarn.lock ]; then \
    corepack enable && yarn install --frozen-lockfile || (ls -la && cat /work/yarn-error.log 2>/dev/null || true && exit 1); \
  else \
    npm config set fund false && npm config set audit false; \
    if [ -f package-lock.json ]; then npm ci || (cat /root/.npm/_logs/*-debug-*.log || true; exit 1); \
    else npm i || (cat /root/.npm/_logs/*-debug-*.log || true; exit 1); fi; \
  fi

# 3) Bring in source
COPY . .

# 4) If .env doesn’t exist but .env.sample does, copy it
RUN [ -f .env ] || { [ -f .env.sample ] && cp .env.sample .env || true; }

# 5) Build (Yarn if available)
RUN set -eux; \
  if [ -f yarn.lock ]; then yarn build; else npm run build; fi

# 6) Normalize build output into /out (supports dist/ or public/)
RUN set -eux; \
  mkdir -p /out; \
  if [ -d dist ]; then cp -a dist/. /out/; \
  elif [ -d public ]; then cp -a public/. /out/; \
  else echo "❌ No build output: expected dist/ or public/"; exit 1; fi

# ---------- Stage 2: Nginx ----------
FROM nginx:1.27-alpine

# Remove default site configs so only ours loads
RUN rm -f /etc/nginx/conf.d/* /etc/nginx/http.d/* || true

# Copy built assets
COPY --from=builder /out/ /usr/share/nginx/html/

# Copy our nginx.conf (provided below)
COPY nginx.conf /etc/nginx/nginx.conf

# Validate config at build time (helps catch mistakes early)
RUN nginx -t -c /etc/nginx/nginx.conf

EXPOSE 8080
CMD ["nginx","-g","daemon off;"]
