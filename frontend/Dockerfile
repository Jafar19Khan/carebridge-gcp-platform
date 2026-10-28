# syntax=docker/dockerfile:1
FROM node:22-alpine AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --no-audit --no-fund
COPY . .
RUN npm run build

FROM nginx:1.31-alpine
# Official nginx image renders /etc/nginx/templates/*.template with env vars at start-up.
# Compose default: API container named "backend". On GCP the web VM sets API_UPSTREAM to the app tier's private IP.
ENV API_UPSTREAM=http://backend:4000 NGINX_RESOLVER=127.0.0.11
COPY default.conf.template /etc/nginx/templates/default.conf.template
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 80
HEALTHCHECK --interval=15s --timeout=3s CMD wget -qO- http://127.0.0.1/ >/dev/null || exit 1
