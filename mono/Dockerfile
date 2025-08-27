# Monolith: nginx (frontend) + node (api, ingest) + supervisord
FROM node:20-bullseye

# Install nginx & supervisor
RUN apt-get update \
 && apt-get install -y --no-install-recommends nginx supervisor ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# App files
WORKDIR /app

# --- FRONTEND BUILD (adjust path if your frontend is elsewhere) ---
# If your frontend is already built (static), skip to copying the build output.
# Otherwise build it here:
# COPY frontend/package*.json ./frontend/
# RUN cd frontend && \
#     if [ -f package-lock.json ]; then npm ci; else npm i; fi && \
#     npm run build
# For now, assume you already have a static build in /frontend/dist:
COPY frontend/dist/ /var/www/html/

# --- API + INGEST (adjust paths to your api/ingest sources) ---
# Copy API
COPY api/package*.json ./api/
RUN cd api && \
    if [ -f package-lock.json ]; then npm ci --omit=dev; else npm i --omit=dev; fi
COPY api/ ./api/

# Copy INGEST
COPY ingest/package*.json ./ingest/
RUN cd ingest && \
    if [ -f package-lock.json ]; then npm ci --omit=dev; else npm i --omit=dev; fi
COPY ingest/ ./ingest/

# Nginx config & Supervisor config
COPY mono/nginx.conf /etc/nginx/nginx.conf
COPY mono/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY mono/entrypoint.sh /entrypoint.sh

# Normalize line endings & perms
RUN sed -i 's/\r$//' /entrypoint.sh && chmod +x /entrypoint.sh

# Env + ports
ENV PORT=8080
EXPOSE 8080

# Start all processes
CMD ["/entrypoint.sh"]
