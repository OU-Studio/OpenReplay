# Dockerfile at repo root
FROM node:20-bullseye

RUN apt-get update \
 && apt-get install -y --no-install-recommends nginx supervisor ca-certificates \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# ---- FRONTEND (adjust if your folder is "frontent" — but please rename it to "frontend") ----
# If you already have a built frontend, copy its build output:
# COPY frontend/dist/ /var/www/html/
# If you need to build it:
COPY frontend/package*.json ./frontend/
RUN cd frontend && if [ -f package-lock.json ]; then npm ci; else npm i; fi && npm run build
RUN rm -rf /var/www/html && mkdir -p /var/www/html
COPY --from=0 /app/frontend/dist/ /var/www/html/

# ---- API ----
COPY api/package*.json ./api/
RUN cd api && if [ -f package-lock.json ]; then npm ci --omit=dev; else npm i --omit=dev; fi
COPY api/ ./api/

# ---- (Optional) INGEST ----
# COPY ingest/package*.json ./ingest/
# RUN cd ingest && if [ -f package-lock.json ]; then npm ci --omit=dev; else npm i --omit=dev; fi
# COPY ingest/ ./ingest/

# ---- Config files (they live in mono/) ----
COPY mono/nginx.conf /etc/nginx/nginx.conf
COPY mono/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY mono/entrypoint.sh /entrypoint.sh
RUN sed -i 's/\r$//' /entrypoint.sh && chmod +x /entrypoint.sh

ENV PORT=8080
EXPOSE 8080

CMD ["/entrypoint.sh"]
