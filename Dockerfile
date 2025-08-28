# ---------- Stage 1: Build the frontend ----------
FROM node:20-alpine AS builder
WORKDIR /app

# Copy manifests first for better cache
COPY package.json package-lock.json* yarn.lock* ./
# Install deps (supports npm or yarn)
RUN set -eux; \
  if [ -f yarn.lock ]; then \
    corepack enable && yarn install --frozen-lockfile; \
  else \
    npm config set fund false && npm config set audit false; \
    if [ -f package-lock.json ]; then npm ci; else npm i; fi; \
  fi

# Copy source and build
COPY . .
# If Vite/CRA/etc. outputs to 'dist' (default Vite) change if needed
RUN set -eux; \
  if [ -f yarn.lock ]; then yarn build; else npm run build; fi

# ---------- Stage 2: Serve via Nginx ----------
FROM nginx:1.27-alpine

# Clean default site(s) to avoid conflicts
RUN rm -f /etc/nginx/conf.d/* /etc/nginx/http.d/* || true

# Copy built assets (adjust if your build dir isn't 'dist')
COPY --from=builder /app/dist/ /usr/share/nginx/html/

# Copy your Nginx config
# (You’ll provide one of the configs below and name it nginx.conf)
COPY nginx.conf /etc/nginx/nginx.conf

# Railway maps external $PORT to this internal port; keep 8080 here
EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]
