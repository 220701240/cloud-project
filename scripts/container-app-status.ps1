#!/usr/bin/env pwsh
# container-app-status.ps1 - Check Azure Container App status and revisions

param(
    [Parameter(Mandatory=$true)]
    [string]$ContainerAppName,
    
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroup,
    
    [Parameter(Mandatory=$false)]
    [switch]$ShowDetailedRevisions
)

Write-Output "=== Azure Container App Status Check ==="
Write-Output "App: $ContainerAppName"
Write-Output "Resource Group: $ResourceGroup"
Write-Output ""

# Check if the container app exists
try {
    $app = az containerapp show --name $ContainerAppName --resource-group $ResourceGroup --query "{name:name,state:properties.provisioningState,fqdn:properties.configuration.ingress.fqdn}" -o json | ConvertFrom-Json
    
    if (-not $app) {
        Write-Error "Container app '$ContainerAppName' not found in resource group '$ResourceGroup'"
        exit 1
    }
    
    Write-Output "Container App Status: $($app.state)"
    if ($app.fqdn) {
        Write-Output "FQDN: https://$($app.fqdn)"
    }
    Write-Output ""
    
} catch {
    Write-Error "Failed to get container app info: $($_.Exception.Message)"
    exit 1
}

# Get active revisions
Write-Output "=== Active Revisions ==="
try {
    $activeRevisions = az containerapp revision list `
        --name $ContainerAppName `
        --resource-group $ResourceGroup `
        --query "[?properties.active==``true``].{name:name,created:properties.createdTime,image:properties.template.containers[0].image,replicas:properties.replicas}" `
        -o json | ConvertFrom-Json
    
    if ($activeRevisions.Count -eq 0) {
        Write-Warning "No active revisions found"
    } else {
        foreach ($revision in $activeRevisions) {
            Write-Output "Revision: $($revision.name)"
            Write-Output "  Created: $($revision.created)"
            Write-Output "  Image: $($revision.image)"
            Write-Output "  Replicas: $($revision.replicas)"
            Write-Output ""
        }
    }
} catch {
    Write-Warning "Failed to get active revisions: $($_.Exception.Message)"
}

# Get latest revision details
Write-Output "=== Latest Revision Health ==="
try {
    $latestRevision = az containerapp revision list `
        --name $ContainerAppName `
        --resource-group $ResourceGroup `
        --query "max_by([],&properties.createdTime)" `
        -o json | ConvertFrom-Json
    
    if ($latestRevision) {
        Write-Output "Latest Revision: $($latestRevision.name)"
        Write-Output "Health State: $($latestRevision.properties.healthState)"
        Write-Output "Running State: $($latestRevision.properties.runningState)"
        
        if ($ShowDetailedRevisions) {
            Write-Output ""
            Write-Output "=== Detailed Revision Info ==="
            az containerapp revision show `
                --name $ContainerAppName `
                --resource-group $ResourceGroup `
                --revision $latestRevision.name `
                --query "{health:properties.healthState,running:properties.runningState,replicas:properties.replicas,conditions:properties.template.containers[0].env}" `
                -o table
        }
    }
} catch {
    Write-Warning "Failed to get latest revision details: $($_.Exception.Message)"
}

# Get recent logs if available
Write-Output "=== Recent Logs (last 20 lines) ==="
try {
    az containerapp logs show `
        --name $ContainerAppName `
        --resource-group $ResourceGroup `
        --tail 20 `
        --follow false
} catch {
    Write-Warning "Failed to retrieve logs: $($_.Exception.Message)"
}

Write-Output ""
Write-Output "=== Status check completed ==="