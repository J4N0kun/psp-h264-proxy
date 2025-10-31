# Publication manuelle sur GHCR (GitHub Container Registry)

Si vous voulez publier l'image **manuellement** (sans GitHub Actions).

## Prérequis

- Docker installé
- Token GitHub avec permission `write:packages`

## Étapes

### 1. Créer un Personal Access Token (PAT)

1. Aller sur : https://github.com/settings/tokens
2. **Generate new token** → **Classic**
3. **Scopes** : Cocher `write:packages`, `read:packages`, `delete:packages`
4. **Generate token**
5. **Copier le token** (ex: `ghp_xxxxxxxxxxxx`)

### 2. Se connecter à GHCR

```bash
# Remplacer YOUR_TOKEN par votre token
echo "ghp_xxxxxxxxxxxx" | docker login ghcr.io -u j4n0kun --password-stdin
```

**Résultat attendu :**
```
Login Succeeded
```

### 3. Builder et taguer l'image

```bash
cd /home/janokun/git/psp-jellyfin-client/server-proxy

# Build
docker build -t ghcr.io/j4n0kun/psp-h264-proxy:latest .

# Tag avec une version (optionnel)
docker tag ghcr.io/j4n0kun/psp-h264-proxy:latest ghcr.io/j4n0kun/psp-h264-proxy:v1.0.0
```

### 4. Push vers GHCR

```bash
# Push latest
docker push ghcr.io/j4n0kun/psp-h264-proxy:latest

# Push version (si taggée)
docker push ghcr.io/j4n0kun/psp-h264-proxy:v1.0.0
```

### 5. Rendre l'image publique

1. Aller sur : https://github.com/users/j4n0kun/packages/container/psp-h264-proxy
2. **Package settings** → **Change visibility**
3. Sélectionner **Public**
4. Confirmer

---

## 🚀 Script automatisé

```bash
./build-and-push.sh
```

Le script vous guidera automatiquement !

---

## Vérification

Une fois publié, l'image sera disponible sur :

```
https://github.com/users/j4n0kun/packages/container/package/psp-h264-proxy
```

**Pull depuis n'importe où :**
```bash
docker pull ghcr.io/j4n0kun/psp-h264-proxy:latest
```

---

## Note

Si vous préférez utiliser **GitHub Actions** (recommandé pour les mises à jour futures), voir le workflow dans `.github/workflows/docker-publish.yml`.

Le workflow se déclenchera automatiquement à chaque push sur `main` ou `feature/media-engine-h264`.

