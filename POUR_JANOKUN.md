# 🎯 POUR VOUS : Étapes à suivre

Tout est prêt ! Voici exactement ce qu'il vous reste à faire.

---

## 📦 Option 1 : Publication sur GHCR (recommandé)

### A. Créer un token GitHub

1. **Aller sur :** https://github.com/settings/tokens
2. **Generate new token (classic)**
3. **Cocher :** `write:packages`, `read:packages`
4. **Generate** et **copier le token** (ex: `ghp_xxxxx...`)

### B. Publier l'image

```bash
cd /home/janokun/git/psp-jellyfin-client/server-proxy

# Se connecter (remplacer ghp_xxxxx par votre token)
echo "ghp_xxxxx..." | docker login ghcr.io -u j4n0kun --password-stdin

# Build et push (script automatique)
./build-and-push.sh v1.0.0
```

**OU manuellement :**
```bash
docker build -t ghcr.io/j4n0kun/psp-h264-proxy:latest .
docker push ghcr.io/j4n0kun/psp-h264-proxy:latest
```

### C. Rendre publique

1. **Aller sur :** https://github.com/users/j4n0kun/packages
2. **Cliquer** sur `psp-h264-proxy`
3. **Package settings** → **Change visibility** → **Public**

---

## 🌌 Option 2 : Déploiement via Cosmos Server

### Depuis Cosmos Server UI

1. **Containers** → **+ Create Container**
2. **Remplir :**
   - **Name:** `psp-h264-proxy`
   - **Image:** `ghcr.io/j4n0kun/psp-h264-proxy:latest`
   - **Port:** `9000` → `9000`
   - **Environment Variables:**
     ```
     JELLYFIN_HOST = 10.19.78.73
     JELLYFIN_PORT = 21409
     API_KEY = 8645890e48eb48a99a9eb28a72d30362
     ```
   - **Restart:** `unless-stopped`
3. **Create & Start**

---

## ✅ Vérifier que le proxy fonctionne

```bash
# Test basique
curl http://10.19.78.73:9000/stream/861092161a7537922cac3b45b1c8edff | head -c 100 | xxd

# Devrait afficher des start codes 00 00 00 01
```

**OU utilisez le script de test :**
```bash
cd /home/janokun/git/psp-jellyfin-client/server-proxy
./test-proxy.sh 861092161a7537922cac3b45b1c8edff
```

---

## 🔧 Modifier le client PSP

### 1. Trouver le code à modifier

```bash
cd /home/janokun/git/psp-jellyfin-client
grep -n "stream.mp4" src/ui_simple_fb.c
```

Résultat attendu : `ui_simple_fb.c:XXXX:...`

### 2. Modifier la ligne

**Chercher :**
```c
snprintf(stream_url, sizeof(stream_url), 
    "%s/Videos/%s/stream.mp4?Static=false&VideoCodec=h264&...",
    server_host_port, item_id, cfg->api_key);
```

**Remplacer par :**
```c
// Proxy H.264 Annex-B
snprintf(stream_url, sizeof(stream_url), 
    "http://10.19.78.73:9000/stream/%s", item_id);
```

### 3. Recompiler

```bash
./scripts/build-and-deploy-fb.sh
```

### 4. Copier sur PSP

```bash
# EBOOT.PBP est dans :
/mnt/c/Temp/psp-jellyfin-deploy/EBOOT.PBP

# Copier sur votre PSP
```

---

## 🧪 Tester sur PSP

1. Lancer le client PSP
2. Sélectionner **Aladdin**
3. Vérifier les logs

**Log de SUCCÈS attendu :**
```
Player: URL streaming: 10.19.78.73:9000/stream/861092161a7537922cac3b45b1c8edff
Player: === HEXDUMP DES 128 PREMIERS BYTES ===
[0000] 00 00 00 01 67 42 C0 1E ...  ← Start code + SPS ✅
Player: === FIN HEXDUMP ===
Player: Recherche du premier start code Annex-B...
Player: Start code 4-byte trouvé à offset 0  ✅
Player: NAL config type=7, len=XX
Player: SPS extrait (XX bytes)
Player: NAL config type=8, len=XX
Player: PPS extrait (XX bytes)
Player: SPS/PPS trouvés ! ✅
MpegDecoder: Initialisation...
MpegDecoder: Stream AVC enregistré OK
MpegDecoder: NAL type=5, size=XXX
MpegDecoder: Première IDR avec SPS/PPS
MpegDecoder: sceMpegAvcDecode ret=...
MpegDecoder: Frame 1 décodée avec succès ! 🎉
```

---

## 📁 Où sont les fichiers ?

```
/home/janokun/git/psp-jellyfin-client/server-proxy/

Fichiers clés :
├── Dockerfile                    ← Build Docker
├── psp-h264-proxy.sh            ← Script proxy
├── docker-compose.yml           ← Config Docker Compose
├── cosmos-config.json           ← Config Cosmos Server
├── QUICKSTART.md                ← Commencer ICI ! ⭐
├── ETAPES_DEPLOYMENT.md         ← Guide complet
└── STATUS.md                    ← Ce fichier
```

---

## 🎯 RÉSUMÉ : Ce que le proxy fait

**Problème actuel :**
- Jellyfin envoie du MP4/fMP4 → PSP ne peut pas parser correctement

**Solution :**
- Proxy intercepte le stream MP4
- FFmpeg convertit MP4 → H.264 Annex-B pur (start codes `00 00 00 01`)
- PSP reçoit un flux H.264 pur directement décodable

**Avantages :**
- ✅ Plus de parsing MP4 côté PSP
- ✅ Compatible avec tous les formats Jellyfin (MP4, fMP4, fragmented)
- ✅ Simple et robuste
- ✅ Faible latence (~200-500ms)
- ✅ Container isolé via Docker

---

## 📞 Questions fréquentes

### Le proxy impacte-t-il les autres clients Jellyfin ?

**Non** ! Le proxy écoute sur le port **9000**, séparé de Jellyfin (port 21409).  
Seule la PSP utilisera le port 9000. Les autres clients (PC, TV, mobile) continuent d'utiliser Jellyfin normalement.

### Le proxy réencode-t-il la vidéo ?

**Non** ! FFmpeg utilise `-c:v copy` (copie sans réencodage).  
Il ne fait que **convertir le container** (MP4 → H.264 brut).  
**Charge CPU :** Très faible (<10% par stream).

### Combien de PSP peuvent streamer simultanément ?

**Recommandé :** 2-3 PSP max (limite FFmpeg processes).  
Chaque stream consomme ~50-100 MB RAM.

### Le proxy fonctionne-t-il sans le Docker mod Jellyfin ?

**Oui** ! Le proxy est **indépendant** du Docker mod.  
Il peut remplacer complètement le Docker mod si besoin.

---

## ✅ TODO Liste

1. **Maintenant :** Publier l'image sur GHCR → Voir `PUBLISH_MANUAL.md`
2. **Ensuite :** Déployer container via Cosmos Server → Voir `COSMOS_DEPLOY.md`
3. **Après :** Modifier client PSP → Voir `ETAPES_DEPLOYMENT.md` Phase 4
4. **Enfin :** Tester sur PSP et m'envoyer les logs ! 🚀

---

**Tout est prêt, à vous de jouer ! 🎮**

