# 🚀 COMMENCEZ ICI !

## 📍 Situation actuelle

✅ **Container Docker créé et testé localement**  
❌ **Jellyfin envoie du MP4/fMP4** → PSP ne peut pas parser  
✅ **Solution proxy prête** → Convertit MP4 en H.264 Annex-B  

---

## 🎯 3 étapes simples

### 1️⃣ Publier sur GHCR (5 min)

```bash
# Lire le guide
cat PUBLISH_MANUAL.md

# OU script automatique
./build-and-push.sh
```

**Besoin d'un token GitHub** → https://github.com/settings/tokens

---

### 2️⃣ Déployer via Cosmos Server (5 min)

```bash
# Lire le guide
cat COSMOS_DEPLOY.md
```

**Ou Quick Start :**
- Image: `ghcr.io/j4n0kun/psp-h264-proxy:latest`
- Port: `9000`
- Variables: Voir `cosmos-config.json`

---

### 3️⃣ Modifier client PSP (5 min)

**Fichier:** `psp-jellyfin-client/src/ui_simple_fb.c`

**Chercher:** `stream.mp4`

**Remplacer par:**
```c
snprintf(stream_url, sizeof(stream_url), 
    "http://10.19.78.73:9000/stream/%s", item_id);
```

**Compiler:**
```bash
cd /home/janokun/git/psp-jellyfin-client
./scripts/build-and-deploy-fb.sh
```

**Tester sur PSP !** 🎮

---

## 📚 Documentation

- **`POUR_JANOKUN.md`** ← Guide personnalisé pour vous ⭐
- **`QUICKSTART.md`** ← Démarrage rapide (5 min)
- **`ETAPES_DEPLOYMENT.md`** ← Guide complet pas-à-pas
- **`COSMOS_DEPLOY.md`** ← Déploiement Cosmos Server
- **`STATUS.md`** ← État actuel du projet

---

## ✅ Checklist

- [ ] Token GitHub créé
- [ ] Image publiée sur GHCR
- [ ] Container déployé via Cosmos
- [ ] Proxy testé (curl + xxd)
- [ ] Client PSP modifié
- [ ] Client PSP recompilé
- [ ] Test vidéo sur PSP

---

**Temps total estimé : 15-20 minutes** ⏱️

**Commencer par :** `cat POUR_JANOKUN.md` 📖
