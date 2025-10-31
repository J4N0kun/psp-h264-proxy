# 🌌 Déploiement via Cosmos Server

Guide pas-à-pas pour déployer le proxy H.264 via Cosmos Server.

---

## 📋 Prérequis

- ✅ Cosmos Server installé et accessible
- ✅ Image publiée sur GHCR : `ghcr.io/j4n0kun/psp-h264-proxy:latest`
- ✅ Port 9000 disponible

---

## 🚀 Déploiement rapide

### Méthode 1 : Via l'interface Cosmos Server

#### 1. Créer le container

1. **Ouvrir Cosmos Server** (http://votre-serveur:cosmos-port)
2. **Containers** → **+ Create**
3. Remplir les champs :

**Informations de base :**
```
Name: psp-h264-proxy
Image: ghcr.io/j4n0kun/psp-h264-proxy:latest
```

**Réseau :**
```
Network Mode: bridge
```

**Ports :**
```
Type: Port Mapping
Container Port: 9000
Host Port: 9000
Protocol: TCP
```

**Variables d'environnement :**
```
JELLYFIN_HOST = 10.19.78.73
JELLYFIN_PORT = 21409
API_KEY = 8645890e48eb48a99a9eb28a72d30362
PROXY_PORT = 9000
```

**Restart Policy :**
```
Restart: unless-stopped
```

#### 2. Lancer le container

- Cliquer sur **Create**
- Attendre que le statut passe à **Running** (vert)
- Vérifier les logs : **Container** → **psp-h264-proxy** → **Logs**

---

### Méthode 2 : Import depuis fichier JSON

1. **Télécharger** `cosmos-config.json` depuis ce repo
2. **Cosmos Server** → **Containers** → **Import**
3. **Sélectionner** le fichier `cosmos-config.json`
4. **Vérifier** la configuration
5. **Import & Start**

---

### Méthode 3 : Via docker-compose (si Cosmos supporte)

```bash
# Upload docker-compose.yml sur le serveur
scp docker-compose.yml janokun@10.19.78.73:/tmp/

# SSH au serveur
ssh janokun@10.19.78.73

# Lancer via Cosmos
cosmos-cli compose up -f /tmp/docker-compose.yml
```

---

## ✅ Vérification

### 1. Vérifier que le container tourne

**Via Cosmos Server UI :**
- **Containers** → Chercher `psp-h264-proxy`
- Status : **🟢 Running**

**Via SSH :**
```bash
ssh janokun@10.19.78.73
docker ps | grep psp-h264-proxy
```

### 2. Tester le proxy

```bash
# Depuis WSL ou votre PC
curl http://10.19.78.73:9000/stream/861092161a7537922cac3b45b1c8edff | head -c 100 | xxd
```

**Résultat attendu :**
```
00000000: 0000 0001 67...  ← Start code Annex-B ✅
```

### 3. Vérifier les logs

**Via Cosmos Server UI :**
- **Container** → **psp-h264-proxy** → **Logs**

**Via SSH :**
```bash
docker logs -f psp-h264-proxy
```

---

## 🔧 Configuration avancée

### Changer le port d'écoute

**Via Cosmos Server :**
- **Container Settings** → **Ports**
- Modifier `Host Port` (ex: `9999` au lieu de `9000`)
- **Redémarrer** le container

### Connecter au réseau Jellyfin existant

Si Jellyfin tourne dans un réseau Docker dédié :

**Via Cosmos Server :**
- **Container Settings** → **Network**
- **Join Network** : Sélectionner le réseau de Jellyfin
- **Environment** : Changer `JELLYFIN_HOST` → `jellyfin` (nom du container)

**Via docker-compose :**
```yaml
networks:
  - jellyfin_network

environment:
  JELLYFIN_HOST: "jellyfin"  # Nom du container Jellyfin
```

---

## 🐛 Dépannage Cosmos Server

### Container ne démarre pas

**Vérifier les logs :**
- Cosmos UI → Logs
- Chercher les erreurs FFmpeg ou socat

**Solutions courantes :**
- Port 9000 déjà utilisé → Changer le port
- `JELLYFIN_HOST` incorrect → Vérifier l'IP/hostname
- `API_KEY` manquant → Ajouter la variable d'environnement

### Connexion Jellyfin échoue

**Tester depuis le container :**
```bash
# Via Cosmos Server UI → Console
# Ou via SSH
docker exec -it psp-h264-proxy sh

# Test connexion Jellyfin
curl -I http://10.19.78.73:21409/System/Info
```

**Si échec :**
- Vérifier firewall
- Si Jellyfin est dans Docker, utiliser `host.docker.internal`
- Ou connecter au même réseau Docker

### Port 9000 non accessible depuis la PSP

**Vérifier le firewall :**
```bash
# Autoriser le port 9000
sudo ufw allow 9000/tcp

# Ou
sudo iptables -A INPUT -p tcp --dport 9000 -j ACCEPT
```

---

## 🔄 Mise à jour

### Via Cosmos Server UI

1. **Containers** → **psp-h264-proxy** → **Update**
2. **Pull latest image**
3. **Restart container**

### Via SSH

```bash
docker pull ghcr.io/j4n0kun/psp-h264-proxy:latest
docker restart psp-h264-proxy
```

---

## 🗑️ Désinstallation

### Via Cosmos Server UI

1. **Containers** → **psp-h264-proxy**
2. **Stop**
3. **Delete**

### Via SSH

```bash
docker stop psp-h264-proxy
docker rm psp-h264-proxy
docker rmi ghcr.io/j4n0kun/psp-h264-proxy:latest
```

---

## 📞 Support

- **GitHub Issues :** https://github.com/J4N0kun/psp-jellyfin-client/issues
- **Cosmos Server Docs :** https://cosmos-cloud.io/doc/

