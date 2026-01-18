#!/bin/bash
# Build and push AutoCoder Docker image to Docker Hub
# Supports multi-architecture builds (amd64 + arm64)

set -e  # Exit on error

# Configuration - CHANGE THESE VALUES
DOCKER_USERNAME="johnreijmer"  # Your Docker Hub username
IMAGE_NAME="autocoder"          # Image name on Docker Hub
VERSION="0.0.2"                 # Version tag (update for new releases)

# Derived variables
FULL_IMAGE="${DOCKER_USERNAME}/${IMAGE_NAME}"

echo "============================================"
echo "  AutoCoder Docker Build & Push"
echo "============================================"
echo ""
echo "Image: ${FULL_IMAGE}"
echo "Tags:  latest, ${VERSION}"
echo ""

# Check if logged in to Docker Hub
if ! docker info | grep -q "Username: ${DOCKER_USERNAME}"; then
    echo "⚠️  Not logged in to Docker Hub"
    echo "Please run: docker login"
    exit 1
fi

echo "✓ Logged in to Docker Hub as ${DOCKER_USERNAME}"
echo ""

# Prompt for build type
echo "Choose build type:"
echo "1) Single architecture (current platform - faster)"
echo "2) Multi-architecture (amd64 + arm64 - recommended for Unraid)"
echo ""
read -p "Enter choice [1-2]: " choice

if [ "$choice" = "2" ]; then
    echo ""
    echo "Building multi-architecture image..."
    echo "This may take 10-20 minutes depending on your system."
    echo ""

    # Create builder if it doesn't exist
    if ! docker buildx ls | grep -q "multiarch"; then
        echo "Creating buildx builder 'multiarch'..."
        docker buildx create --name multiarch --use
        docker buildx inspect --bootstrap
    else
        echo "Using existing buildx builder 'multiarch'..."
        docker buildx use multiarch
    fi

    # Build and push for multiple platforms
    docker buildx build \
        --platform linux/amd64,linux/arm64 \
        -t "${FULL_IMAGE}:latest" \
        -t "${FULL_IMAGE}:${VERSION}" \
        --push \
        .

    echo ""
    echo "✓ Multi-architecture build complete!"

else
    echo ""
    echo "Building single-architecture image..."
    echo ""

    # Build for current platform
    docker build -t "${FULL_IMAGE}:latest" -t "${FULL_IMAGE}:${VERSION}" .

    echo ""
    echo "Pushing to Docker Hub..."
    docker push "${FULL_IMAGE}:latest"
    docker push "${FULL_IMAGE}:${VERSION}"

    echo ""
    echo "✓ Single-architecture build complete!"
fi

echo ""
echo "============================================"
echo "  Image Published Successfully!"
echo "============================================"
echo ""
echo "Your image is now available at:"
echo "  docker pull ${FULL_IMAGE}:latest"
echo "  docker pull ${FULL_IMAGE}:${VERSION}"
echo ""
echo "View on Docker Hub:"
echo "  https://hub.docker.com/r/${FULL_IMAGE}"
echo ""
echo "Next steps:"
echo "1. Test the image: docker run -d -p 8888:8888 -e ANTHROPIC_API_KEY=sk-ant-... ${FULL_IMAGE}:latest"
echo "2. Update your docker-compose.yml to use: ${FULL_IMAGE}:latest"
echo "3. Share with others!"
echo ""
