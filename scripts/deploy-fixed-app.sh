#!/bin/bash
# deploy-fixed-app.sh - Deploy the newly built image to Container App

echo "=== Deploying Fixed Container App ==="

# Set variables
RESOURCE_GROUP="placement-tracker-rg"
CONTAINER_APP_NAME="internship-api"
ACR_NAME="cloudprojectacr"
IMAGE_NAME="internship-api"

# Get the latest image tag (you can also specify a specific tag)
echo "Available image tags:"
az acr repository show-tags --name $ACR_NAME --repository $IMAGE_NAME --output table

echo ""
echo "Using latest tag for deployment..."
IMAGE_TAG="latest"
FULL_IMAGE="$ACR_NAME.azurecr.io/$IMAGE_NAME:$IMAGE_TAG"

echo "Deploying image: $FULL_IMAGE"

# Update the container app
echo "Updating Container App..."
az containerapp update \
  --name $CONTAINER_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --image $FULL_IMAGE

echo ""
echo "Waiting for deployment to complete..."
sleep 60

# Check the new revision status
echo "Checking deployment status..."
LATEST_REVISION=$(az containerapp revision list \
  --name $CONTAINER_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --query "[0].name" -o tsv)

echo "Latest revision: $LATEST_REVISION"

REVISION_STATUS=$(az containerapp revision show \
  --name $CONTAINER_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --revision $LATEST_REVISION \
  --query "{health:properties.healthState,running:properties.runningState,replicas:properties.replicas}" -o json)

echo "Revision status:"
echo $REVISION_STATUS | jq '.'

# Get the app URL and test it
FQDN=$(az containerapp show \
  --name $CONTAINER_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --query "properties.configuration.ingress.fqdn" -o tsv)

if [ -n "$FQDN" ]; then
  echo ""
  echo "🌐 App URL: https://$FQDN"
  
  echo "Testing app health..."
  HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "https://$FQDN/api/health" || echo "000")
  
  if [ "$HTTP_STATUS" = "200" ]; then
    echo "✅ App is healthy and responding!"
    echo "🎉 Deployment successful!"
  else
    echo "⚠️  App responded with status: $HTTP_STATUS"
    echo "Checking logs for issues..."
    az containerapp logs show --name $CONTAINER_APP_NAME --resource-group $RESOURCE_GROUP --tail 20
  fi
else
  echo "❌ Could not get app FQDN"
fi

echo ""
echo "=== Deployment Complete ==="