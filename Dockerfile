# --- build ---
# SDK: pubspec.yaml ile uyumlu stable kanal
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

COPY pubspec.yaml pubspec.lock* ./
RUN flutter pub get

COPY . .

RUN touch .env

# Build-time: canlı API adresinizi Coolify/GitHub Actions build arg ile verin
ARG API_BASE_URL
ARG API_CONNECT_TIMEOUT_MS=10000
ARG API_RECEIVE_TIMEOUT_MS=8000

RUN test -n "$API_BASE_URL" || (echo "ERROR: Docker build icin --build-arg API_BASE_URL=https://api.ornek.com gerekli" && exit 1)

RUN flutter build web --release \
    --dart-define=API_BASE_URL=${API_BASE_URL} \
    --dart-define=API_CONNECT_TIMEOUT_MS=${API_CONNECT_TIMEOUT_MS} \
    --dart-define=API_RECEIVE_TIMEOUT_MS=${API_RECEIVE_TIMEOUT_MS}

# --- serve ---
FROM nginx:1.27-alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80
