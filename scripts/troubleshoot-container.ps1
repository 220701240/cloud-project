#!/usr/bin/env pwsh
# troubleshoot-container.ps1 - Comprehensive container app troubleshooting

$ResourceGroup = "placement-tracker-rg"
$ContainerAppName = "internship-api"

Write-Output "=== Container App Troubleshooting ==="
Write-Output ""

# 1. Basic app status
Write-Output "1. Container App Overview:"
az containerapp show --name $ContainerAppName --resource-group $ResourceGroup --query "{name:name,state:properties.provisioningState,location:location,fqdn:properties.configuration.ingress.fqdn}" -o table

Write-Output ""

# 2. All revisions with health status
Write-Output "2. All Revisions (with health):"
az containerapp revision list --name $ContainerAppName --resource-group $ResourceGroup --query "[].[name,properties.healthState,properties.runningState,properties.active,properties.createdTime]" -o table

Write-Output ""

# 3. Active revisions only
Write-Output "3. Active Revisions Only:"
az containerapp revision list --name $ContainerAppName --resource-group $ResourceGroup --query "[?properties.active==``true``].[name,properties.healthState,properties.runningState,properties.template.containers[0].image]" -o table

Write-Output ""

# 4. Get detailed info about latest revision
Write-Output "4. Latest Revision Details:"
$latestRevision = az containerapp revision list --name $ContainerAppName --resource-group $ResourceGroup --query "[0].name" -o tsv
if ($latestRevision) {
    Write-Output "Latest revision: $latestRevision"
    az containerapp revision show --name $ContainerAppName --resource-group $ResourceGroup --revision $latestRevision --query "{name:name,health:properties.healthState,running:properties.runningState,replicas:properties.replicas,image:properties.template.containers[0].image}" -o table
    
    Write-Output ""
    
    # 5. Get container logs for troubleshooting
    Write-Output "5. Recent Container Logs (last 50 lines):"
    Write-Output "----------------------------------------"
    try {
        az containerapp logs show --name $ContainerAppName --resource-group $ResourceGroup --revision $latestRevision --tail 50 --follow false
    } catch {
        Write-Output "Could not retrieve logs for revision $latestRevision"
        Write-Output "Trying to get logs without specific revision..."
        az containerapp logs show --name $ContainerAppName --resource-group $ResourceGroup --tail 50 --follow false
    }
} else {
    Write-Output "No revisions found"
}

Write-Output ""

# 6. Check environment variables
Write-Output "6. Environment Variables Check:"
az containerapp show --name $ContainerAppName --resource-group $ResourceGroup --query "properties.template.containers[0].env[?name=='APPINSIGHTS_INSTRUMENTATIONKEY' || name=='JWT_SECRET' || name=='AZURE_SQL_USER'].[name,value]" -o table

Write-Output ""

# 7. Scale and resource info
Write-Output "7. Scaling Configuration:"
az containerapp show --name $ContainerAppName --resource-group $ResourceGroup --query "{minReplicas:properties.template.scale.minReplicas,maxReplicas:properties.template.scale.maxReplicas,cpu:properties.template.containers[0].resources.cpu,memory:properties.template.containers[0].resources.memory}" -o table

Write-Output ""
Write-Output "=== Troubleshooting Complete ==="

# 8. Suggested next steps
Write-Output ""
Write-Output "Analysis and Next Steps:"
Write-Output "1. Check the logs above for startup errors"
Write-Output "2. If you see missing package errors, update package.json and rebuild"
Write-Output "3. If health is 'Unhealthy', check for port/readiness probe issues"
Write-Output "4. If 'ScaledToZero', the app may have crashed due to errors"
Write-Output ""
Write-Output "Common issues:"
Write-Output "- Missing npm packages (helmet, express-rate-limit, etc.)"
Write-Output "- Wrong port configuration (should be 3000)"
Write-Output "- Missing environment variables"
Write-Output "- Database connection issues"