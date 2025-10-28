#!/bin/bash
# build-in-cloud-shell.sh - Build Docker image using Azure Cloud Shell

echo "=== Building Docker Image in Azure Cloud Shell ==="

# Set variables
ACR_NAME="cloudprojectacr"
IMAGE_NAME="internship-api"
BUILD_TAG="cloudshell-$(date +%s)"

echo "ACR: $ACR_NAME"
echo "Image: $IMAGE_NAME"
echo "Tag: $BUILD_TAG"

# Clone the repository (if not already done)
if [ ! -d "cloud-project" ]; then
    echo "Cloning repository..."
    git clone https://github.com/220701240/cloud-project.git
fi

cd cloud-project/internship-api

# Login to ACR
echo "Logging into ACR..."
az acr login --name $ACR_NAME

# Build and push using Docker in Cloud Shell
echo "Building Docker image..."
docker build -t $ACR_NAME.azurecr.io/$IMAGE_NAME:$BUILD_TAG .
docker build -t $ACR_NAME.azurecr.io/$IMAGE_NAME:latest .

echo "Pushing images..."
docker push $ACR_NAME.azurecr.io/$IMAGE_NAME:$BUILD_TAG
docker push $ACR_NAME.azurecr.io/$IMAGE_NAME:latest

echo "✅ Build completed successfully!"
echo "Images available:"
echo "  - $ACR_NAME.azurecr.io/$IMAGE_NAME:$BUILD_TAG"
echo "  - $ACR_NAME.azurecr.io/$IMAGE_NAME:latest"

echo ""
echo "To deploy, run:"
echo "az containerapp update --name internship-api --resource-group placement-tracker-rg --image $ACR_NAME.azurecr.io/$IMAGE_NAME:$BUILD_TAG"