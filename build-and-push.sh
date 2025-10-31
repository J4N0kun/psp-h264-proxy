#!/bin/bash
# Script pour builder et pousser l'image Docker vers GHCR
# Usage: ./build-and-push.sh [version]

set -e

VERSION="${1:-latest}"
IMAGE_NAME="ghcr.io/j4n0kun/psp-h264-proxy"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================================="
echo "Build et Push Docker Image vers GHCR"
echo "=========================================="
echo "Image: $IMAGE_NAME:$VERSION"
echo ""

# Vérifier que nous sommes dans le bon répertoire
if [ ! -f "$SCRIPT_DIR/Dockerfile" ]; then
    echo "❌ Dockerfile non trouvé dans $SCRIPT_DIR"
    exit 1
fi

# Build l'image
echo "1️⃣ Build de l'image Docker..."
docker build -t "$IMAGE_NAME:$VERSION" "$SCRIPT_DIR"
echo "   ✅ Build terminé"
echo ""

# Tag latest si version spécifique
if [ "$VERSION" != "latest" ]; then
    docker tag "$IMAGE_NAME:$VERSION" "$IMAGE_NAME:latest"
    echo "   ✅ Tag 'latest' ajouté"
    echo ""
fi

# Vérifier que nous sommes connectés à GitHub Container Registry
echo "2️⃣ Vérification de l'authentification GHCR..."
if ! docker info | grep -q "Username:"; then
    echo "   ⚠️  Non authentifié à GHCR"
    echo "   → Authentification requise..."
    echo ""
    echo "   Option 1: Via GitHub Personal Access Token (PAT)"
    echo "   $ echo \$GITHUB_TOKEN | docker login ghcr.io -u janokun --password-stdin"
    echo ""
    echo "   Option 2: Via GitHub CLI"
    echo "   $ gh auth login"
    echo ""
    read -p "   Continuer quand même et tenter de pousser ? (y/n) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi
else
    echo "   ✅ Authentifié"
fi
echo ""

# Push vers GHCR
echo "3️⃣ Push vers GHCR..."
docker push "$IMAGE_NAME:$VERSION"

if [ "$VERSION" != "latest" ]; then
    docker push "$IMAGE_NAME:latest"
fi

echo ""
echo "=========================================="
echo "✅ Image poussée avec succès !"
echo "=========================================="
echo ""
echo "Image disponible sur:"
echo "  https://github.com/users/janokun/packages/container/package/psp-h264-proxy"
echo ""
echo "Pour utiliser l'image:"
echo "  docker pull $IMAGE_NAME:$VERSION"
echo ""
echo "Ou via docker-compose:"
echo "  docker-compose up -d"
echo ""

