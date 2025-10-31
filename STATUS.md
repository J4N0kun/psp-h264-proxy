# 📊 Status du Proxy H.264 Annex-B

**Date :** 31 octobre 2025  
**Branche :** `feature/media-engine-h264`

---

## ✅ Terminé

- [x] Dockerfile créé et testé
- [x] Script proxy fonctionnel (`psp-h264-proxy.sh`)
- [x] docker-compose.yml configuré
- [x] GitHub Actions workflow créé
- [x] Documentation complète (README, INSTALL, QUICKSTART, COSMOS_DEPLOY)
- [x] Build local testé avec succès
- [x] Container démarre correctement (logs OK)
- [x] Configuration pour Cosmos Server (JSON)

---

## ⏳ En attente

- [ ] **Publication sur GHCR** (nécessite token GitHub PAT)
- [ ] **Déploiement sur serveur via Cosmos Server**
- [ ] **Modification du client PSP pour utiliser le proxy**
- [ ] **Test de décodage vidéo sur PSP**

---

## 📂 Fichiers créés

```
server-proxy/
├── Dockerfile                    ✅ Alpine + FFmpeg + socat
├── psp-h264-proxy.sh            ✅ Script proxy principal
├── docker-compose.yml           ✅ Configuration Docker Compose
├── cosmos-config.json           ✅ Configuration Cosmos Server
├── .dockerignore                ✅ Exclusions build
├── .gitignore                   ✅ Exclusions Git
├── .github/
│   └── workflows/
│       └── docker-publish.yml   ✅ CI/CD automatique
├── README.md                    ✅ Documentation principale
├── QUICKSTART.md                ✅ Guide 5 minutes
├── INSTALL.md                   ✅ Installation détaillée
├── COSMOS_DEPLOY.md             ✅ Guide Cosmos Server
├── PUBLISH_MANUAL.md            ✅ Publication GHCR manuelle
├── ETAPES_DEPLOYMENT.md         ✅ Guide pas-à-pas complet
├── STATUS.md                    ✅ Ce fichier
├── build-and-push.sh            ✅ Script build & push
├── deploy-to-server.sh          ✅ Script déploiement serveur
├── test-proxy.sh                ✅ Script de test
└── psp-h264-proxy.service       ✅ Service systemd (si besoin)
```

---

## 🎯 Prochaines actions

### Action 1 : Publier sur GHCR

```bash
cd /home/janokun/git/psp-jellyfin-client/server-proxy

# Se connecter à GHCR (avec votre PAT)
echo "ghp_YOUR_TOKEN" | docker login ghcr.io -u j4n0kun --password-stdin

# Build et push
docker build -t ghcr.io/j4n0kun/psp-h264-proxy:latest .
docker push ghcr.io/j4n0kun/psp-h264-proxy:latest

# Rendre publique (via interface GitHub)
# → https://github.com/users/j4n0kun/packages
```

### Action 2 : Déployer sur Cosmos Server

**Via UI Cosmos Server :**
- Image : `ghcr.io/j4n0kun/psp-h264-proxy:latest`
- Port : `9000`
- Variables : Voir `cosmos-config.json`

### Action 3 : Modifier client PSP

**Fichier :** `psp-jellyfin-client/src/ui_simple_fb.c`

**Chercher :**
```c
snprintf(stream_url, sizeof(stream_url), 
    "%s/Videos/%s/stream.mp4?...
```

**Remplacer par :**
```c
snprintf(stream_url, sizeof(stream_url), 
    "http://10.19.78.73:9000/stream/%s", item_id);
```

**Compiler :**
```bash
cd /home/janokun/git/psp-jellyfin-client
./scripts/build-and-deploy-fb.sh
```

### Action 4 : Tester sur PSP

1. Copier `EBOOT.PBP` sur PSP
2. Lancer le client
3. Lire Aladdin
4. Vérifier les logs

---

## 🔗 URLs importantes

- **Repo GitHub :** https://github.com/J4N0kun/
- **GHCR Package :** https://github.com/users/j4n0kun/packages (après publication)
- **Image Docker :** `ghcr.io/j4n0kun/psp-h264-proxy:latest`
- **Proxy URL :** `http://10.19.78.73:9000/stream/{video_id}`

---

## 📊 Architecture finale

```
┌────────────┐          ┌──────────────────────┐          ┌──────────┐
│            │          │ Docker Container     │          │          │
│  PSP       │  :9000   │  psp-h264-proxy     │  :21409  │ Jellyfin │
│            ├─────────►│                      ├─────────►│          │
│            │          │  FFmpeg              │          │          │
│            │◄─────────┤  mp4toannexb        │◄─────────┤          │
│            │  H.264   │                      │  MP4     │          │
│            │  Annex-B │                      │          │          │
└────────────┘          └──────────────────────┘          └──────────┘
  10.19.78.213                                              10.19.78.73
```

---

**Build local réussi ✅**  
**Prêt pour publication sur GHCR ! 🚀**

