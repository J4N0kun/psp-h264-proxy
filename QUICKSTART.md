# 🚀 Quick Start - 5 minutes

## Pour Cosmos Server (recommandé)

### 1. Déployer le container

**Via l'interface Cosmos Server :**

1. **Containers** → **+ Create Container**

2. **Configuration :**
   ```
   Name: psp-h264-proxy
   Image: ghcr.io/j4n0kun/psp-h264-proxy:latest
   ```

3. **Port Mapping :**
   ```
   Host: 9000 → Container: 9000
   ```

4. **Environment Variables :**
   ```
   JELLYFIN_HOST = 10.19.78.73
   JELLYFIN_PORT = 21409
   API_KEY = 8645890e48eb48a99a9eb28a72d30362
   ```

5. **Restart Policy :** `unless-stopped`

6. **Create & Start**

### 2. Vérifier que ça fonctionne

```bash
# Depuis WSL ou un terminal
curl http://10.19.78.73:9000/stream/861092161a7537922cac3b45b1c8edff | head -c 100 | xxd
```

**Résultat attendu :**
```
00000000: 0000 0001 67...  ← Start code Annex-B détecté ✅
```

### 3. Modifier le client PSP

Fichier : `psp-jellyfin-client/src/ui_simple_fb.c`

**Chercher (ligne ~1150) :**
```c
snprintf(stream_url, sizeof(stream_url), 
    "%s/Videos/%s/stream.mp4?Static=false&VideoCodec=h264&AudioCodec=aac&MaxWidth=480&MaxHeight=272&VideoBitrate=512000&AudioBitrate=64000&VideoLevel=13&Profile=baseline&api_key=%s",
    server_host_port, item_id, cfg->api_key);
```

**Remplacer par :**
```c
// Utiliser le proxy H.264 Annex-B au lieu de Jellyfin direct
snprintf(stream_url, sizeof(stream_url), 
    "http://10.19.78.73:9000/stream/%s", item_id);
```

### 4. Recompiler et tester

```bash
cd /home/janokun/git/psp-jellyfin-client
./scripts/build-and-deploy-fb.sh

# Copier EBOOT.PBP sur la PSP
# Tester la lecture vidéo
```

---

## Pour Docker CLI

```bash
docker run -d \
  --name psp-h264-proxy \
  --restart unless-stopped \
  -p 9000:9000 \
  -e JELLYFIN_HOST="10.19.78.73" \
  -e JELLYFIN_PORT="21409" \
  -e API_KEY="8645890e48eb48a99a9eb28a72d30362" \
  ghcr.io/j4n0kun/psp-h264-proxy:latest

# Vérifier
docker logs -f psp-h264-proxy
```

---

## Pour docker-compose

```bash
# Télécharger docker-compose.yml
curl -O https://raw.githubusercontent.com/J4N0kun/psp-jellyfin-client/main/server-proxy/docker-compose.yml

# Éditer JELLYFIN_HOST si nécessaire
nano docker-compose.yml

# Lancer
docker-compose up -d

# Logs
docker-compose logs -f
```

---

## ✅ Checklist de vérification

- [ ] Container démarré : `docker ps | grep psp-h264-proxy`
- [ ] Port 9000 écoute : `curl -I http://10.19.78.73:9000/stream/test`
- [ ] Stream H.264 valide : `curl http://10.19.78.73:9000/stream/861092161a7537922cac3b45b1c8edff | xxd | grep "0000 0001"`
- [ ] Client PSP modifié et recompilé
- [ ] Test lecture vidéo sur PSP

---

## 🐛 Problèmes courants

### "Cannot pull image"
```bash
# Se connecter à GHCR
echo "YOUR_GITHUB_TOKEN" | docker login ghcr.io -u j4n0kun --password-stdin
```

### "Connection refused port 9000"
```bash
# Vérifier que le container tourne
docker ps | grep psp-h264-proxy

# Vérifier les logs
docker logs psp-h264-proxy
```

### "FFmpeg error"
```bash
# Entrer dans le container
docker exec -it psp-h264-proxy sh

# Tester FFmpeg manuellement
ffmpeg -i "http://10.19.78.73:21409/Videos/861092161a7537922cac3b45b1c8edff/stream.mp4?..." \
  -c:v copy -bsf:v h264_mp4toannexb -f h264 - | head -c 100 | xxd
```

---

**Temps total : ~5 minutes** ⏱️

