#!/usr/bin/env pwsh
# quick-image-check.ps1 - Quick check of current container image

Write-Output "=== Quick Image Check ==="

# Replace with your actual ACR name if needed
$ResourceGroup = "placement-tracker-rg"
$ContainerAppName = "internship-api"

Write-Output "Checking current container image..."
az containerapp show --name $ContainerAppName --resource-group $ResourceGroup --query "properties.template.containers[0].image" -o tsv

Write-Output ""
Write-Output "Checking active revisions..."
az containerapp revision list --name $ContainerAppName --resource-group $ResourceGroup --query "[?properties.active==``true``].[name,properties.template.containers[0].image]" -o table

Write-Output ""
Write-Output "Container app status:"
az containerapp show --name $ContainerAppName --resource-group $ResourceGroup --query "{state:properties.provisioningState,running:properties.runningState}" -o table