#!/bin/bash
# Script de test du proxy H.264 Annex-B
# Usage: ./test-proxy.sh [video_id]

PROXY_HOST="10.19.78.73"
PROXY_PORT="9000"
VIDEO_ID="${1:-861092161a7537922cac3b45b1c8edff}"  # Aladdin par défaut

echo "=========================================="
echo "Test du Proxy H.264 Annex-B"
echo "=========================================="
echo "Serveur: $PROXY_HOST:$PROXY_PORT"
echo "Video ID: $VIDEO_ID"
echo ""

# Test 1: Vérifier que le port écoute
echo "1️⃣ Vérification du port $PROXY_PORT..."
if nc -zv $PROXY_HOST $PROXY_PORT 2>&1 | grep -q "succeeded"; then
    echo "   ✅ Port $PROXY_PORT accessible"
else
    echo "   ❌ Port $PROXY_PORT non accessible"
    echo "   → Vérifier que le proxy est démarré : sudo systemctl status psp-h264-proxy"
    exit 1
fi
echo ""

# Test 2: Requête HTTP basique
echo "2️⃣ Test requête HTTP..."
HTTP_RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" -m 5 "http://$PROXY_HOST:$PROXY_PORT/stream/$VIDEO_ID" | head -c 1000)
HTTP_CODE=$(echo "$HTTP_RESPONSE" | grep "HTTP_CODE:" | cut -d: -f2)

if [ "$HTTP_CODE" = "200" ]; then
    echo "   ✅ Réponse HTTP 200 OK"
else
    echo "   ❌ Réponse HTTP: $HTTP_CODE"
    echo "   → Vérifier les logs : tail -f /var/log/psp-h264-proxy.log"
    exit 1
fi
echo ""

# Test 3: Vérification format Annex-B
echo "3️⃣ Vérification format H.264 Annex-B..."
STREAM_DATA=$(curl -s -m 10 "http://$PROXY_HOST:$PROXY_PORT/stream/$VIDEO_ID" | head -c 200)

# Sauvegarder dans un fichier temporaire pour xxd
echo -n "$STREAM_DATA" > /tmp/psp_stream_test.bin

echo "   Hexdump des 128 premiers bytes:"
xxd -l 128 /tmp/psp_stream_test.bin

# Chercher les start codes
if xxd -l 200 /tmp/psp_stream_test.bin | grep -q "0000 0001"; then
    echo ""
    echo "   ✅ Start codes Annex-B détectés (00 00 00 01)"
    
    # Extraire les types NAL
    echo ""
    echo "4️⃣ Analyse des NAL units..."
    
    # Première NAL (après premier start code)
    FIRST_NAL_BYTE=$(xxd -l 200 /tmp/psp_stream_test.bin | grep "0000 0001" | head -1 | awk '{print $6}')
    if [ ! -z "$FIRST_NAL_BYTE" ]; then
        NAL_TYPE=$((0x$FIRST_NAL_BYTE & 0x1F))
        echo "   Premier NAL type: $NAL_TYPE"
        
        case $NAL_TYPE in
            7) echo "   → SPS (Sequence Parameter Set) ✅" ;;
            8) echo "   → PPS (Picture Parameter Set) ✅" ;;
            5) echo "   → IDR Frame (Keyframe) ✅" ;;
            1) echo "   → Non-IDR Frame (P/B-frame)" ;;
            *) echo "   → Type $NAL_TYPE" ;;
        esac
    fi
    
    echo ""
    echo "=========================================="
    echo "✅ SUCCÈS : Le proxy fonctionne correctement !"
    echo "=========================================="
    echo "URL pour la PSP:"
    echo "  http://$PROXY_HOST:$PROXY_PORT/stream/$VIDEO_ID"
    echo ""
    
else
    echo ""
    echo "   ❌ Aucun start code Annex-B détecté"
    echo "   → Le flux n'est pas en format Annex-B"
    echo "   → Vérifier que FFmpeg est installé et fonctionne"
    exit 1
fi

# Nettoyage
rm -f /tmp/psp_stream_test.bin

exit 0

