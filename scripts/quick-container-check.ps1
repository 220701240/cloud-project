#!/usr/bin/env pwsh
# quick-container-check.ps1 - Quick Azure Container App status check

$ResourceGroup = "placement-tracker-rg"
$ContainerAppName = "internship-api"

Write-Output "=== Quick Container App Check ==="

# Get basic app info
Write-Output "1. Container App Status:"
az containerapp show --name $ContainerAppName --resource-group $ResourceGroup --query "{name:name,state:properties.provisioningState}" -o table

# Get FQDN
Write-Output ""
Write-Output "2. Container App FQDN:"
$fqdn = az containerapp show --name $ContainerAppName --resource-group $ResourceGroup --query "properties.configuration.ingress.fqdn" -o tsv
if ($fqdn) { 
    Write-Output "https://$fqdn" 
} else { 
    Write-Output "No FQDN configured" 
}

# Get active revisions with proper escaping
Write-Output ""
Write-Output "3. Active Revisions:"
az containerapp revision list --name $ContainerAppName --resource-group $ResourceGroup --query "[?properties.active==\`true\`].[name,properties.createdTime,properties.template.containers[0].image]" -o table

# Get latest revision health
Write-Output ""
Write-Output "4. Latest Revision Health:"
$latestRevision = az containerapp revision list --name $ContainerAppName --resource-group $ResourceGroup --query "[0].name" -o tsv
if ($latestRevision) {
    Write-Output "Latest revision: $latestRevision"
    az containerapp revision show --name $ContainerAppName --resource-group $ResourceGroup --revision $latestRevision --query "{health:properties.healthState,running:properties.runningState}" -o table
} else {
    Write-Output "No revisions found"
}

Write-Output ""
Write-Output "=== Check completed ==="