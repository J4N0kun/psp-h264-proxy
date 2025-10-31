FROM alpine:3.19

# Installer FFmpeg et Python
RUN apk add --no-cache \
    ffmpeg \
    python3 \
    bash \
    curl

# Créer le répertoire de travail
WORKDIR /app

# Copier le serveur Python (plus fiable que socat/bash)
COPY proxy-server.py /app/

# Rendre exécutable
RUN chmod +x /app/proxy-server.py

# Port d'écoute
EXPOSE 9000

# Variables d'environnement par défaut
ENV PROXY_PORT=9000 \
    JELLYFIN_HOST=host.docker.internal \
    JELLYFIN_PORT=8096 \
    API_KEY=""

# Commande par défaut (Python au lieu de bash)
CMD ["python3", "/app/proxy-server.py"]

