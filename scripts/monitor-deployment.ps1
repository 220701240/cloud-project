#!/usr/bin/env pwsh
# monitor-deployment.ps1 - Monitor container app deployment progress

param(
    [string]$ContainerAppName = "internship-api",
    [string]$ResourceGroup = "placement-tracker-rg",
    [int]$TimeoutMinutes = 10
)

Write-Output "=== Monitoring Container App Deployment ==="
Write-Output "App: $ContainerAppName"
Write-Output "Resource Group: $ResourceGroup"
Write-Output "Timeout: $TimeoutMinutes minutes"
Write-Output ""

$startTime = Get-Date
$timeoutTime = $startTime.AddMinutes($TimeoutMinutes)

do {
    $currentTime = Get-Date
    Write-Output "[$($currentTime.ToString('HH:mm:ss'))] Checking deployment status..."
    
    try {
        # Get current revision status
        $revisions = az containerapp revision list `
            --name $ContainerAppName `
            --resource-group $ResourceGroup `
            --query "[?properties.active==``true``]" -o json | ConvertFrom-Json
        
        if ($revisions.Count -gt 0) {
            foreach ($revision in $revisions) {
                $status = $revision.properties.runningState
                $health = $revision.properties.healthState
                $replicas = $revision.properties.replicas
                
                Write-Output "  Revision: $($revision.name)"
                Write-Output "  Status: $status"
                Write-Output "  Health: $health" 
                Write-Output "  Replicas: $replicas"
                
                if ($status -eq "Running" -and $health -eq "Healthy") {
                    Write-Output ""
                    Write-Output "✅ Deployment successful! Container is running and healthy."
                    
                    # Get the app URL
                    $fqdn = az containerapp show --name $ContainerAppName --resource-group $ResourceGroup --query "properties.configuration.ingress.fqdn" -o tsv
                    if ($fqdn) {
                        Write-Output "🌐 App URL: https://$fqdn"
                    }
                    
                    exit 0
                }
                
                if ($status -eq "Failed") {
                    Write-Output ""
                    Write-Output "❌ Deployment failed! Revision status: $status"
                    exit 1
                }
            }
        } else {
            Write-Output "  No active revisions found"
        }
        
    } catch {
        Write-Warning "Error checking status: $($_.Exception.Message)"
    }
    
    Write-Output ""
    
    if ($currentTime -lt $timeoutTime) {
        Start-Sleep -Seconds 30
    }
    
} while ($currentTime -lt $timeoutTime)

Write-Output "⏰ Timeout reached. Deployment may still be in progress."
Write-Output "Check status manually with: az containerapp show --name $ContainerAppName --resource-group $ResourceGroup"