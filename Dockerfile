# ---------- Stage 1: build frontend ----------
FROM node:20-alpine AS fe-builder
WORKDIR /app/frontend

# Copy manifests first for better caching
COPY frontend/package.json frontend/package-lock.json* frontend/yarn.lock* ./

# Use npm or yarn depending on which lockfile exists
RUN set -eux; \
    if [ -f yarn.lock ]; then \
      corepack enable && yarn install --frozen-lockfile; \
    else \
      npm config set fund false && npm config set audit false; \
      if [ -f package-lock.json ]; then npm ci; else npm i; fi; \
    fi

# Copy source & build
COPY frontend/ ./
RUN set -eux; \
    if [ -f yarn.lock ]; then \
      yarn build; \
    else \
      npm run build; \
    fi

# ---------- Stage 2: runtime (nginx + supervisor + node) ----------
FROM node:20-alpine

# Nginx config: remove default site(s) so they can't collide
RUN rm -f /etc/nginx/conf.d/* /etc/nginx/http.d/* || true

# Copy your single, authoritative config
COPY mono/nginx.conf /etc/nginx/nginx.conf

# Install nginx & supervisor (Alpine)
RUN apk add --no-cache nginx supervisor

# Create dirs
RUN mkdir -p /var/www/html /var/log/supervisor

# Workdir for app code
WORKDIR /app

# ---- API ----
COPY api/package.json api/package-lock.json* api/yarn.lock* ./api/
RUN set -eux; \
    cd /app/api; \
    if [ -f yarn.lock ]; then \
      corepack enable && yarn install --frozen-lockfile --production; \
    else \
      npm config set fund false && npm config set audit false; \
      if [ -f package-lock.json ]; then npm ci --omit=dev; else npm i --omit=dev; fi; \
    fi
COPY api/ ./api/

# ---- Static frontend into nginx web root ----
COPY --from=fe-builder /app/frontend/dist/ /var/www/html/

# ---- Config + entrypoint (these files live in mono/) ----
COPY mono/nginx.conf /etc/nginx/nginx.conf
COPY mono/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY mono/entrypoint.sh /entrypoint.sh
RUN sed -i 's/\r$//' /entrypoint.sh && chmod +x /entrypoint.sh

ENV PORT=8080
EXPOSE 8080

CMD ["/entrypoint.sh"] 
