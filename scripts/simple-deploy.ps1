#!/usr/bin/env pwsh
# simple-deploy.ps1 - Simple deployment script without complex error handling

param(
    [string]$ImageTag = "latest"
)

$ResourceGroup = "placement-tracker-rg"
$ContainerAppName = "internship-api"
$AcrName = "cloudprojectacr"
$ImageName = "internship-api"

Write-Output "=== Simple Container App Deploy ==="
Write-Output "Deploying image: $AcrName.azurecr.io/$ImageName`:$ImageTag"
Write-Output ""

# Update container app
$fullImage = "$AcrName.azurecr.io/$ImageName`:$ImageTag"
Write-Output "Updating container app..."
az containerapp update --name $ContainerAppName --resource-group $ResourceGroup --image $fullImage

Write-Output ""
Write-Output "Waiting 60 seconds for deployment..."
Start-Sleep -Seconds 60

# Check status
Write-Output "Checking status..."
az containerapp revision list --name $ContainerAppName -g $ResourceGroup --query "[0].{name:name,health:properties.healthState,running:properties.runningState}" -o table

# Get app URL
$fqdn = az containerapp show --name $ContainerAppName -g $ResourceGroup --query "properties.configuration.ingress.fqdn" -o tsv
Write-Output ""
Write-Output "App URL: https://$fqdn"

Write-Output ""
Write-Output "Testing app..."
try {
    $response = Invoke-WebRequest -Uri "https://$fqdn/api/health" -UseBasicParsing -TimeoutSec 10
    Write-Output "✅ App responds with status: $($response.StatusCode)"
} catch {
    Write-Output "⚠️ App test failed: $($_.Exception.Message)"
    Write-Output "Checking logs..."
    az containerapp logs show --name $ContainerAppName -g $ResourceGroup --tail 10
}

Write-Output ""
Write-Output "=== Deploy Complete ==="