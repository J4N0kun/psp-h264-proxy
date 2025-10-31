FROM alpine:3.19

# Installer FFmpeg et socat
RUN apk add --no-cache \
    ffmpeg \
    socat \
    bash \
    curl

# Créer le répertoire de travail
WORKDIR /app

# Copier le script proxy
COPY psp-h264-proxy.sh /app/

# Rendre exécutable
RUN chmod +x /app/psp-h264-proxy.sh

# Port d'écoute
EXPOSE 9000

# Variables d'environnement par défaut
ENV PROXY_PORT=9000 \
    JELLYFIN_HOST=host.docker.internal \
    JELLYFIN_PORT=8096 \
    API_KEY=""

# Commande par défaut
CMD ["/app/psp-h264-proxy.sh"]

