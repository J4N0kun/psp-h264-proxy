#!/bin/bash
# PSP H.264 Annex-B Proxy pour Jellyfin
# Serveur: 10.19.78.73:21409
# Usage: ./psp-h264-proxy.sh

set -e

# Configuration (peut être overridée par variables d'environnement)
PROXY_PORT="${PROXY_PORT:-9000}"
JELLYFIN_HOST="${JELLYFIN_HOST:-localhost}"
JELLYFIN_PORT="${JELLYFIN_PORT:-21409}"
API_KEY="${API_KEY:-8645890e48eb48a99a9eb28a72d30362}"
LOG_FILE="${LOG_FILE:-/app/psp-h264-proxy.log}"

echo "========================================" | tee -a "$LOG_FILE"
echo "PSP H.264 Annex-B Proxy for Jellyfin" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"
echo "Port d'écoute: $PROXY_PORT" | tee -a "$LOG_FILE"
echo "Jellyfin: $JELLYFIN_HOST:$JELLYFIN_PORT" | tee -a "$LOG_FILE"
echo "Log: $LOG_FILE" | tee -a "$LOG_FILE"
echo "Prêt à recevoir des connexions PSP..." | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Fonction de gestion d'une requête
handle_request() {
    # Lire la requête HTTP (première ligne)
    read -r REQUEST_LINE
    
    # Extraire l'ID vidéo (format: GET /stream/<video_id> HTTP/1.1)
    VIDEO_ID=$(echo "$REQUEST_LINE" | grep -oP 'GET /stream/\K[a-f0-9]+' || echo "")
    
    # Lire le reste des headers (jusqu'à ligne vide)
    while read -r HEADER; do
        # Ligne vide = fin des headers
        [ -z "$HEADER" ] && break
        # Supprimer le \r si présent
        HEADER=$(echo "$HEADER" | tr -d '\r')
    done
    
    if [ -z "$VIDEO_ID" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERREUR: ID vidéo manquant dans requête" | tee -a "$LOG_FILE"
        
        # Réponse 400 Bad Request
        echo "HTTP/1.1 400 Bad Request"
        echo "Content-Type: text/plain"
        echo "Connection: close"
        echo ""
        echo "Erreur: ID vidéo requis (format: /stream/<video_id>)"
        return
    fi
    
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Stream demandé: $VIDEO_ID" | tee -a "$LOG_FILE"
    
    # Construire l'URL Jellyfin
    JELLYFIN_URL="http://$JELLYFIN_HOST:$JELLYFIN_PORT/Videos/$VIDEO_ID/stream.mp4"
    PARAMS="Static=false&VideoCodec=h264&AudioCodec=aac&MaxWidth=480&MaxHeight=272&VideoBitrate=512000&AudioBitrate=64000&VideoLevel=13&Profile=baseline&api_key=$API_KEY"
    
    # Headers HTTP de réponse
    echo "HTTP/1.1 200 OK"
    echo "Content-Type: video/h264"
    echo "Connection: close"
    echo "Cache-Control: no-cache"
    echo ""
    
    # Stream H.264 Annex-B via FFmpeg
    ffmpeg -loglevel error \
        -i "$JELLYFIN_URL?$PARAMS" \
        -map 0:v:0 \
        -c:v copy \
        -bsf:v h264_mp4toannexb \
        -f h264 \
        - 2>>"$LOG_FILE"
    
    FFMPEG_EXIT=$?
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Stream terminé: $VIDEO_ID (exit code: $FFMPEG_EXIT)" | tee -a "$LOG_FILE"
}

# Boucle principale avec socat (plus robuste que nc)
if command -v socat &> /dev/null; then
    echo "Utilisation de socat pour le serveur HTTP..." | tee -a "$LOG_FILE"
    socat TCP-LISTEN:$PROXY_PORT,fork,reuseaddr SYSTEM:"bash -c 'source $(readlink -f $0); handle_request'"
else
    echo "socat non trouvé, utilisation de netcat (moins robuste)..." | tee -a "$LOG_FILE"
    # Fallback sur nc (netcat)
    while true; do
        handle_request | nc -l -p $PROXY_PORT -q 1
        sleep 0.5
    done
fi

