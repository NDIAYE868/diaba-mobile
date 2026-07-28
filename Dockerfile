# Multi-stage Dockerfile pour Flutter Web (Diaba Mobile)

# 1. Étape de Build Flutter
FROM debian:latest AS build-env

# Installation des dépendances pour Flutter
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    openjdk-17-jdk \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Cloner le SDK Flutter stable
RUN git clone https://github.com/flutter/flutter.git -b stable /sdks/flutter
ENV PATH="$PATH:/sdks/flutter/bin"

# Exécuter flutter doctor & activer le support web
RUN flutter doctor -v
RUN flutter config --enable-web

# Copier le code de l'application
WORKDIR /app
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .

# Build web release
RUN flutter build web --release

# 2. Étape de Production Nginx
FROM nginx:alpine
COPY --from=build-env /app/build/web /usr/share/nginx/html

# Custom nginx config pour supporter le SPA Routing (GoRouter)
RUN echo 'server { \
    listen 80; \
    location / { \
        root /usr/share/nginx/html; \
        index index.html index.htm; \
        try_files $uri $uri/ /index.html; \
    } \
}' > /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
