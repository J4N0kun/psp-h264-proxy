#!/bin/bash
# Script de déploiement automatique du proxy sur le serveur
# Usage: ./deploy-to-server.sh

set -e

SERVER="10.19.78.73"
USER="janokun"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================================="
echo "Déploiement du Proxy H.264 Annex-B"
echo "=========================================="
echo "Serveur: $USER@$SERVER"
echo "Source: $SCRIPT_DIR"
echo ""

# Vérifier la connexion SSH
echo "1️⃣ Vérification de la connexion SSH..."
if ssh -o ConnectTimeout=5 -o BatchMode=yes $USER@$SERVER exit 2>/dev/null; then
    echo "   ✅ Connexion SSH OK"
else
    echo "   ⚠️  Connexion SSH nécessite mot de passe ou clé"
    echo "   → Continuer avec authentification interactive"
fi
echo ""

# Copier le script principal
echo "2️⃣ Copie du script proxy..."
scp "$SCRIPT_DIR/psp-h264-proxy.sh" $USER@$SERVER:/tmp/
echo "   ✅ Script copié"
echo ""

# Installer sur le serveur
echo "3️⃣ Installation sur le serveur..."
ssh $USER@$SERVER << 'EOF'
    # Copier en tant que root
    if sudo cp /tmp/psp-h264-proxy.sh /usr/local/bin/; then
        echo "   ✅ Script copié vers /usr/local/bin/"
    else
        echo "   ❌ Échec copie (vérifier les permissions sudo)"
        exit 1
    fi
    
    # Rendre exécutable
    sudo chmod +x /usr/local/bin/psp-h264-proxy.sh
    echo "   ✅ Script exécutable"
    
    # Créer le fichier de log
    sudo touch /var/log/psp-h264-proxy.log
    sudo chown janokun:janokun /var/log/psp-h264-proxy.log
    echo "   ✅ Fichier de log créé"
    
    # Vérifier FFmpeg
    if command -v ffmpeg &> /dev/null; then
        echo "   ✅ FFmpeg installé ($(ffmpeg -version | head -1))"
    else
        echo "   ⚠️  FFmpeg non installé"
        echo "   → Installer avec: sudo apt-get install -y ffmpeg"
    fi
    
    # Vérifier socat
    if command -v socat &> /dev/null; then
        echo "   ✅ socat installé"
    else
        echo "   ⚠️  socat non installé (recommandé)"
        echo "   → Installer avec: sudo apt-get install -y socat"
    fi
EOF

echo ""
echo "4️⃣ Installation du service systemd (optionnel)..."
read -p "   Installer le service systemd pour auto-start ? (y/n) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    scp "$SCRIPT_DIR/psp-h264-proxy.service" $USER@$SERVER:/tmp/
    
    ssh $USER@$SERVER << 'EOF'
        sudo cp /tmp/psp-h264-proxy.service /etc/systemd/system/
        sudo systemctl daemon-reload
        sudo systemctl enable psp-h264-proxy
        echo "   ✅ Service systemd installé et activé"
        
        # Demander si on démarre tout de suite
        read -p "   Démarrer le service maintenant ? (y/n) " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            sudo systemctl start psp-h264-proxy
            sleep 2
            sudo systemctl status psp-h264-proxy --no-pager
        else
            echo "   → Démarrer plus tard avec: sudo systemctl start psp-h264-proxy"
        fi
EOF
else
    echo "   → Service systemd non installé"
    echo "   → Lancer manuellement avec: ssh $USER@$SERVER '/usr/local/bin/psp-h264-proxy.sh'"
fi

echo ""
echo "=========================================="
echo "✅ Déploiement terminé !"
echo "=========================================="
echo ""
echo "Prochaines étapes:"
echo "1. Tester le proxy:"
echo "   ./test-proxy.sh 861092161a7537922cac3b45b1c8edff"
echo ""
echo "2. Modifier le client PSP pour utiliser le proxy:"
echo "   URL: http://10.19.78.73:9000/stream/<video_id>"
echo ""
echo "3. Vérifier les logs:"
echo "   ssh $USER@$SERVER 'tail -f /var/log/psp-h264-proxy.log'"
echo ""

