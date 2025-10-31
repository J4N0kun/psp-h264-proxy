# Installation du Proxy H.264 Annex-B pour PSP

Ce proxy convertit les streams Jellyfin MP4/fMP4 en flux H.264 Annex-B pur, directement décodable par la PSP.

## Prérequis

- FFmpeg installé sur le serveur
- Accès root/sudo sur le serveur 10.19.78.73
- Port 9000 disponible (ou modifier `PROXY_PORT` dans le script)

## Installation

### 1. Copier le script sur le serveur

```bash
# Sur votre machine locale (WSL)
scp /home/janokun/git/psp-jellyfin-client/server-proxy/psp-h264-proxy.sh janokun@10.19.78.73:/tmp/

# Se connecter au serveur
ssh janokun@10.19.78.73

# Copier en tant que root
sudo cp /tmp/psp-h264-proxy.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/psp-h264-proxy.sh

# Créer le fichier de log
sudo touch /var/log/psp-h264-proxy.log
sudo chown janokun:janokun /var/log/psp-h264-proxy.log
```

### 2. Installer socat (recommandé pour meilleure stabilité)

```bash
# Debian/Ubuntu
sudo apt-get update
sudo apt-get install -y socat

# OU Alpine (si serveur léger)
sudo apk add socat
```

### 3. Option A : Test manuel (sans systemd)

```bash
# Lancer le proxy manuellement
/usr/local/bin/psp-h264-proxy.sh

# Dans un autre terminal, tester
curl -v http://10.19.78.73:9000/stream/861092161a7537922cac3b45b1c8edff | head -c 1000 | xxd

# Vous devriez voir des start codes 00 00 00 01
```

### 3. Option B : Service systemd (auto-start)

```bash
# Copier le fichier service
sudo cp /home/janokun/git/psp-jellyfin-client/server-proxy/psp-h264-proxy.service /etc/systemd/system/

# Recharger systemd
sudo systemctl daemon-reload

# Activer le service (démarrage auto)
sudo systemctl enable psp-h264-proxy

# Démarrer le service
sudo systemctl start psp-h264-proxy

# Vérifier le statut
sudo systemctl status psp-h264-proxy

# Voir les logs
sudo journalctl -u psp-h264-proxy -f
```

## Utilisation

### URL pour la PSP

Au lieu de :
```
http://10.19.78.73:21409/Videos/{id}/stream.mp4?...
```

Utiliser :
```
http://10.19.78.73:9000/stream/{id}
```

### Exemple avec Aladdin

```
http://10.19.78.73:9000/stream/861092161a7537922cac3b45b1c8edff
```

## Vérification du bon fonctionnement

### Test avec curl + xxd

```bash
curl -s http://10.19.78.73:9000/stream/861092161a7537922cac3b45b1c8edff | head -c 200 | xxd
```

**Sortie attendue (Annex-B) :**
```
00000000: 0000 0001 6742 c01e ...  ← Start code + SPS (type 7)
00000020: 0000 0001 68ce 3c80 ...  ← Start code + PPS (type 8)
00000040: 0000 0001 6588 ...       ← Start code + IDR (type 5)
```

Si vous voyez `00 00 00 01` au début, **le proxy fonctionne correctement** ! ✅

## Désinstallation

```bash
# Arrêter le service
sudo systemctl stop psp-h264-proxy
sudo systemctl disable psp-h264-proxy

# Supprimer les fichiers
sudo rm /etc/systemd/system/psp-h264-proxy.service
sudo rm /usr/local/bin/psp-h264-proxy.sh
sudo rm /var/log/psp-h264-proxy.log

# Recharger systemd
sudo systemctl daemon-reload
```

## Dépannage

### Le service ne démarre pas

```bash
# Vérifier les logs détaillés
sudo journalctl -u psp-h264-proxy -n 50 --no-pager

# Vérifier que le port 9000 n'est pas déjà utilisé
sudo ss -tlnp | grep 9000

# Tester manuellement
sudo -u janokun /usr/local/bin/psp-h264-proxy.sh
```

### FFmpeg ne démarre pas

```bash
# Vérifier que ffmpeg est installé
which ffmpeg
ffmpeg -version

# Si absent, installer
sudo apt-get install -y ffmpeg
```

### Connexion depuis la PSP échoue

```bash
# Vérifier que le port 9000 est bien ouvert
sudo ufw allow 9000/tcp

# Ou si firewalld
sudo firewall-cmd --add-port=9000/tcp --permanent
sudo firewall-cmd --reload

# Tester depuis WSL
curl -v http://10.19.78.73:9000/stream/861092161a7537922cac3b45b1c8edff | head -c 100
```

## Performance

- **Latence ajoutée :** ~100-500ms (temps de démarrage FFmpeg)
- **Charge CPU :** Faible (FFmpeg copie sans réencodage : `-c:v copy`)
- **Mémoire :** ~50-100 MB par stream actif
- **Streaming simultanés :** Limité par le nombre de processus FFmpeg (recommandé max 2-3 PSP simultanées)

