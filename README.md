# Proxy H.264 Annex-B pour PSP Jellyfin Client

Convertit automatiquement les streams Jellyfin (MP4/fMP4) en flux H.264 Annex-B pur pour la PSP.

## 🐳 Installation via Docker (recommandé)

### 1. Pull depuis GHCR

```bash
# Authentifier à GHCR
echo $GITHUB_TOKEN | docker login ghcr.io -u janokun --password-stdin

# Pull l'image
docker pull ghcr.io/janokun/psp-h264-proxy:latest
```

**Ou via Cosmos Server :**
- Ouvrir Cosmos Server
- Apps → Docker Images → Pull
- Image: `ghcr.io/janokun/psp-h264-proxy:latest`

### 2. Lancer le container

#### Option A : docker-compose (recommandé)

```bash
# Télécharger docker-compose.yml
curl -O https://raw.githubusercontent.com/janokun/psp-jellyfin-client/main/server-proxy/docker-compose.yml

# Éditer les variables d'environnement
nano docker-compose.yml

# Lancer
docker-compose up -d

# Vérifier les logs
docker-compose logs -f
```

#### Option B : docker run

```bash
docker run -d \
  --name psp-h264-proxy \
  --restart unless-stopped \
  -p 9000:9000 \
  -e JELLYFIN_HOST="10.19.78.73" \
  -e JELLYFIN_PORT="21409" \
  -e API_KEY="8645890e48eb48a99a9eb28a72d30362" \
  --add-host=host.docker.internal:host-gateway \
  ghcr.io/janokun/psp-h264-proxy:latest
```

#### Option C : Cosmos Server UI

**Depuis l'interface Cosmos Server :**

1. **Container** → **Add Container**
   - **Name:** `psp-h264-proxy`
   - **Image:** `ghcr.io/janokun/psp-h264-proxy:latest`

2. **Port Mappings:**
   - **Host:** `9000` → **Container:** `9000`

3. **Environment Variables:**
   - `JELLYFIN_HOST`: `10.19.78.73`
   - `JELLYFIN_PORT`: `21409`
   - `API_KEY`: `8645890e48eb48a99a9eb28a72d30362`

4. **Restart Policy:** `unless-stopped`

5. **Start Container**

---

## 🧪 Test du proxy

```bash
# Test basique
curl http://localhost:9000/stream/861092161a7537922cac3b45b1c8edff | head -c 200 | xxd

# Devrait afficher des start codes 00 00 00 01
```

**Ou utilisez le script de test :**
```bash
./test-proxy.sh 861092161a7537922cac3b45b1c8edff
```

---

## 🔧 Configuration

### Variables d'environnement

| Variable | Défaut | Description |
|----------|--------|-------------|
| `PROXY_PORT` | `9000` | Port d'écoute du proxy |
| `JELLYFIN_HOST` | `localhost` | IP/hostname du serveur Jellyfin |
| `JELLYFIN_PORT` | `21409` | Port Jellyfin |
| `API_KEY` | *(vide)* | API Key Jellyfin |
| `LOG_FILE` | `/app/psp-h264-proxy.log` | Fichier de logs |

### Exemple configuration Cosmos Server

```yaml
Environment Variables:
  JELLYFIN_HOST: "10.19.78.73"
  JELLYFIN_PORT: "21409"
  API_KEY: "8645890e48eb48a99a9eb28a72d30362"
  PROXY_PORT: "9000"
```

---

## 📊 Monitoring

### Logs du container

```bash
# Voir les logs en temps réel
docker logs -f psp-h264-proxy

# Ou via docker-compose
docker-compose logs -f

# Ou via Cosmos Server
# Container → psp-h264-proxy → Logs
```

### Vérifier les connexions

```bash
# Connexions actives
docker exec psp-h264-proxy ss -tnp | grep :9000

# Ou depuis l'hôte
ss -tnp | grep :9000
```

---

## 🏗️ Build depuis les sources

Si vous voulez builder l'image localement :

```bash
# Clone du repo
git clone https://github.com/janokun/psp-jellyfin-client.git
cd psp-jellyfin-client/server-proxy

# Build local
docker build -t psp-h264-proxy:local .

# Ou build + push vers GHCR
./build-and-push.sh
```

### Authentification GHCR

```bash
# Via GitHub Personal Access Token (PAT)
echo "ghp_YOUR_TOKEN_HERE" | docker login ghcr.io -u janokun --password-stdin

# Via GitHub CLI
gh auth login
gh auth configure-docker

# Puis push
docker push ghcr.io/janokun/psp-h264-proxy:latest
```

---

## 🐛 Dépannage

### Le container ne démarre pas

```bash
# Vérifier les logs
docker logs psp-h264-proxy

# Vérifier que FFmpeg est disponible
docker exec psp-h264-proxy ffmpeg -version

# Vérifier que socat est disponible
docker exec psp-h264-proxy socat -V
```

### Connexion Jellyfin échoue

```bash
# Tester depuis le container
docker exec psp-h264-proxy curl -I http://10.19.78.73:21409/System/Info

# Si Jellyfin est sur le même host Docker
# → Utiliser host.docker.internal au lieu de 10.19.78.73
```

### Port 9000 déjà utilisé

```bash
# Changer le port dans docker-compose.yml
ports:
  - "9999:9000"  # Host:Container

# Ou en runtime
docker run -p 9999:9000 ...
```

---

## 🎯 Intégration avec le client PSP

Modifier `src/ui_simple_fb.c` :

```c
// Utiliser le proxy au lieu de l'URL Jellyfin directe
snprintf(stream_url, sizeof(stream_url), 
    "http://10.19.78.73:9000/stream/%s", item_id);
```

Puis recompiler et redéployer sur la PSP.

---

## 📝 Architecture

```
┌─────────┐                  ┌────────────────────────────┐                  ┌─────────┐
│ PSP     │                  │ Docker Container           │                  │         │
│         │                  │ ┌────────────────────────┐ │                  │ JF      │
│         │ ──GET──►:9000───►│ │ psp-h264-proxy.sh     │ │                  │:21409   │
│         │                  │ │   ↓ FFmpeg             │ │                  │         │
│         │                  │ │   -c:v copy            │ │                  │         │
│         │                  │ │   -bsf:v mp4toannexb   │ │                  │         │
│         │◄────H.264────────│ └────────────────────────┘ │                  │         │
│         │   Annex-B        └────────────────────────────┘                  │         │
└─────────┘                                                   ───────────────►│         │
                                                                     GET MP4   └─────────┘
```

---

## 🔐 Sécurité

⚠️ **Important** : Ce proxy n'effectue PAS de validation d'authentification !

**Recommandations :**
- ✅ Utiliser uniquement sur réseau local privé
- ✅ Firewall : Autoriser seulement l'IP de la PSP (10.19.78.213)
- ✅ Ou ajouter un token/mot de passe dans le script
- ⚠️ Ne pas exposer le port 9000 sur Internet

---

## 📈 Performance

- **Latence ajoutée :** ~200-500ms
- **CPU par stream :** <10% (FFmpeg copy mode)
- **RAM par stream :** ~50-100 MB
- **Streams simultanés :** Recommandé 2-3 PSP max

---

## 📦 Images disponibles

```
ghcr.io/janokun/psp-h264-proxy:latest
ghcr.io/janokun/psp-h264-proxy:v1.0.0
```

---

## 🔗 Liens

- **GitHub Repository:** https://github.com/janokun/psp-jellyfin-client
- **Package GHCR:** https://github.com/users/janokun/packages/container/package/psp-h264-proxy
- **Cosmos Server:** https://github.com/Cosmos-UI/Cosmos
