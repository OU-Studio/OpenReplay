# ---------- Stage 1: Build the frontend ----------
FROM node:20-alpine AS builder
WORKDIR /app

# copy package manifests
COPY package.json package-lock.json* yarn.lock* ./

# install deps (supports npm or yarn)
RUN set -eux; \
  if [ -f yarn.lock ]; then \
    corepack enable && yarn install --frozen-lockfile; \
  else \
    npm config set fund false && npm config set audit false; \
    if [ -f package-lock.json ]; then npm ci; else npm i; fi; \
  fi

# copy source and build
COPY . .
RUN set -eux; \
  if [ -f yarn.lock ]; then yarn build; else npm run build; fi

# ---------- Stage 2: Runtime (Nginx) ----------
FROM nginx:1.27-alpine

# remove default configs so only ours loads
RUN rm -f /etc/nginx/conf.d/* /etc/nginx/http.d/* || true

# copy built frontend to nginx html root
COPY --from=builder /app/dist/ /usr/share/nginx/html/

# copy our nginx.conf
COPY nginx.conf /etc/nginx/nginx.conf

# sanity check config at build time
RUN nginx -t -c /etc/nginx/nginx.conf

EXPOSE 8080
CMD ["nginx","-g","daemon off;"]
