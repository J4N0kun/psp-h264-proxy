# 📦 Guide de déploiement complet

## Phase 1 : Publication sur GHCR

### Étape 1 : Créer un Personal Access Token (PAT)

1. Aller sur : https://github.com/settings/tokens
2. **Generate new token** → **Tokens (classic)**
3. **Note :** `GHCR PSP H.264 Proxy`
4. **Expiration :** `90 days` (ou `No expiration`)
5. **Select scopes :**
   - ✅ `write:packages`
   - ✅ `read:packages`
   - ✅ `delete:packages` (optionnel)
6. **Generate token**
7. **COPIER LE TOKEN** (ex: `ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxx`)
   - ⚠️ Vous ne pourrez plus le voir après !

### Étape 2 : Se connecter à GHCR

```bash
# Depuis WSL
cd /home/janokun/git/psp-jellyfin-client/server-proxy

# Se connecter (remplacer YOUR_TOKEN par votre token)
echo "ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxx" | docker login ghcr.io -u j4n0kun --password-stdin
```

**Résultat attendu :**
```
Login Succeeded
```

### Étape 3 : Builder et pousser l'image

**Option A : Script automatisé (recommandé)**
```bash
./build-and-push.sh v1.0.0
```

**Option B : Commandes manuelles**
```bash
# Build
docker build -t ghcr.io/j4n0kun/psp-h264-proxy:latest .
docker tag ghcr.io/j4n0kun/psp-h264-proxy:latest ghcr.io/j4n0kun/psp-h264-proxy:v1.0.0

# Push
docker push ghcr.io/j4n0kun/psp-h264-proxy:latest
docker push ghcr.io/j4n0kun/psp-h264-proxy:v1.0.0
```

### Étape 4 : Rendre l'image publique

1. Aller sur : https://github.com/users/j4n0kun/packages
2. Cliquer sur **psp-h264-proxy**
3. **Package settings** (en haut à droite)
4. **Change visibility** → **Public**
5. Taper le nom du package pour confirmer : `psp-h264-proxy`
6. **I understand, change package visibility**

---

## Phase 2 : Déploiement sur le serveur via Cosmos

### Étape 1 : Ouvrir Cosmos Server

```
URL: http://10.19.78.73:<port_cosmos>
```

### Étape 2 : Créer le container

**Containers** → **+ Create** :

```
┌─────────────────────────────────────────┐
│ Name: psp-h264-proxy                    │
│ Image: ghcr.io/j4n0kun/psp-h264-proxy:latest │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│ Ports:                                  │
│   9000 (host) → 9000 (container) TCP    │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│ Environment Variables:                  │
│   JELLYFIN_HOST = 10.19.78.73          │
│   JELLYFIN_PORT = 21409                │
│   API_KEY = 8645890e48eb48a99a9eb28a72d30362 │
│   PROXY_PORT = 9000                    │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│ Restart Policy: unless-stopped          │
│ Network: bridge                         │
└─────────────────────────────────────────┘
```

### Étape 3 : Démarrer et vérifier

1. **Create & Start**
2. Attendre 5-10 secondes
3. **Logs** → Vérifier que "Prêt à recevoir des connexions PSP..." apparaît

---

## Phase 3 : Tester le proxy

### Test depuis WSL

```bash
# Test basique (les 100 premiers bytes)
curl http://10.19.78.73:9000/stream/861092161a7537922cac3b45b1c8edff | head -c 100 | xxd

# Devrait afficher
# 00000000: 0000 0001 67... ← Start code ✅
```

**Ou utiliser le script de test :**
```bash
cd /home/janokun/git/psp-jellyfin-client/server-proxy
./test-proxy.sh 861092161a7537922cac3b45b1c8edff
```

---

## Phase 4 : Modifier le client PSP

### Localiser le code à modifier

Fichier : `psp-jellyfin-client/src/ui_simple_fb.c`

Chercher la fonction `ui_show_player` (environ ligne 1100-1150)

### Trouver la ligne qui construit stream_url

```bash
cd /home/janokun/git/psp-jellyfin-client
grep -n "stream.mp4" src/ui_simple_fb.c
```

### Modifier le code

**AVANT :**
```c
snprintf(stream_url, sizeof(stream_url), 
    "%s/Videos/%s/stream.mp4?Static=false&VideoCodec=h264&AudioCodec=aac&MaxWidth=480&MaxHeight=272&VideoBitrate=512000&AudioBitrate=64000&VideoLevel=13&Profile=baseline&api_key=%s",
    server_host_port, item_id, cfg->api_key);
```

**APRÈS :**
```c
// Utiliser le proxy H.264 Annex-B au lieu de Jellyfin direct
snprintf(stream_url, sizeof(stream_url), 
    "http://10.19.78.73:9000/stream/%s", item_id);
```

### Recompiler

```bash
cd /home/janokun/git/psp-jellyfin-client
./scripts/build-and-deploy-fb.sh
```

### Déployer sur PSP

```bash
# Copier EBOOT.PBP depuis
# /mnt/c/Temp/psp-jellyfin-deploy/EBOOT.PBP
# vers la PSP
```

---

## Phase 5 : Test final sur PSP

1. ✅ Lancer le client PSP
2. ✅ Sélectionner Aladdin
3. ✅ Vérifier les logs PSP

**Log attendu :**
```
Player: URL streaming: 10.19.78.73:9000/stream/861092161a7537922cac3b45b1c8edff
Player: Téléchargement démarré
Player: === HEXDUMP DES 128 PREMIERS BYTES ===
[0000] 00 00 00 01 67...  ← Start code Annex-B ✅
Player: Start code 4-byte trouvé à offset 0
Player: NAL config type=7, len=XX  ← SPS ✅
Player: SPS extrait
Player: NAL config type=8, len=XX  ← PPS ✅
MpegDecoder: Initialisation...
MpegDecoder: Frame 1 décodée ! 🎉
```

---

## ✅ Checklist complète

- [ ] Token GHCR créé
- [ ] Image buildée et poussée sur GHCR
- [ ] Image rendue publique
- [ ] Container déployé via Cosmos Server
- [ ] Container running (status vert)
- [ ] Test proxy réussi (start codes visibles)
- [ ] Client PSP modifié
- [ ] Client PSP recompilé
- [ ] EBOOT.PBP copié sur PSP
- [ ] Test lecture vidéo sur PSP

---

## 🎯 Résumé des commandes

```bash
# 1. Publier sur GHCR
cd /home/janokun/git/psp-jellyfin-client/server-proxy
echo "YOUR_TOKEN" | docker login ghcr.io -u j4n0kun --password-stdin
./build-and-push.sh v1.0.0

# 2. Tester localement
docker run -d --name test -p 9001:9000 -e JELLYFIN_HOST="10.19.78.73" -e JELLYFIN_PORT="21409" -e API_KEY="8645890e48eb48a99a9eb28a72d30362" ghcr.io/j4n0kun/psp-h264-proxy:latest
curl http://localhost:9001/stream/861092161a7537922cac3b45b1c8edff | head -c 100 | xxd

# 3. Modifier client PSP
cd /home/janokun/git/psp-jellyfin-client
# Éditer src/ui_simple_fb.c (voir Phase 4)
./scripts/build-and-deploy-fb.sh

# 4. Tester sur PSP
# Copier EBOOT.PBP et tester
```

**Temps estimé : 15-20 minutes** ⏱️

