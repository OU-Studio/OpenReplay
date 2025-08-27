# -------- Stage 1: build frontend --------
FROM node:20-alpine AS fe-builder
WORKDIR /app/frontend
COPY frontend/package*.json ./
RUN if [ -f package-lock.json ]; then npm ci; else npm i; fi
COPY frontend/ ./
RUN npm run build

# -------- Stage 2: runtime (nginx + supervisor + node apps) --------
FROM node:20-bullseye

# OS deps: nginx + supervisor
RUN apt-get update \
 && apt-get install -y --no-install-recommends nginx supervisor ca-certificates \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# ---- API ----
COPY api/package*.json ./api/
RUN cd api && if [ -f package-lock.json ]; then npm ci --omit=dev; else npm i --omit=dev; fi
COPY api/ ./api/

# ---- Static frontend into nginx web root ----
RUN rm -rf /var/www/html && mkdir -p /var/www/html
COPY --from=fe-builder /app/frontend/dist/ /var/www/html/

# ---- Config + entrypoint ----
# (these live in mono/ per your last messages)
COPY mono/nginx.conf /etc/nginx/nginx.conf
COPY mono/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY mono/entrypoint.sh /entrypoint.sh
RUN sed -i 's/\r$//' /entrypoint.sh && chmod +x /entrypoint.sh

# Env/ports
ENV PORT=8080
EXPOSE 8080

# Start nginx + API (and ingest if you add it) via supervisor
CMD ["/entrypoint.sh"]
