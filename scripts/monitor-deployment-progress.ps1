#!/usr/bin/env pwsh
# monitor-deployment-progress.ps1 - Watch deployment progress in real-time

param(
    [string]$ContainerAppName = "internship-api",
    [string]$ResourceGroup = "placement-tracker-rg",
    [int]$TimeoutMinutes = 15
)

Write-Output "=== Monitoring New Deployment Progress ==="
Write-Output "⏰ Started at: $(Get-Date -Format 'HH:mm:ss')"
Write-Output ""

$startTime = Get-Date
$timeoutTime = $startTime.AddMinutes($TimeoutMinutes)
$lastRevisionCount = 0

do {
    $currentTime = Get-Date
    Write-Output "[$($currentTime.ToString('HH:mm:ss'))] Checking deployment status..."
    
    try {
        # Get revision count and latest revision
        $revisions = az containerapp revision list --name $ContainerAppName -g $ResourceGroup --query "[].{name:name,active:properties.active,health:properties.healthState,running:properties.runningState,image:properties.template.containers[0].image,created:properties.createdTime}" -o json | ConvertFrom-Json
        
        if ($revisions.Count -gt $lastRevisionCount) {
            Write-Output "🆕 New revision detected!"
            $lastRevisionCount = $revisions.Count
        }
        
        # Show latest revision status
        $latest = $revisions | Sort-Object created -Descending | Select-Object -First 1
        Write-Output "   📦 Latest: $($latest.name)"
        Write-Output "   🖼️  Image: $($latest.image)"
        Write-Output "   ❤️  Health: $($latest.health)"
        Write-Output "   🏃 Running: $($latest.running)"
        Write-Output "   ✅ Active: $($latest.active)"
        
        # Check if healthy and running
        if ($latest.health -eq "Healthy" -and $latest.running -eq "Running") {
            Write-Output ""
            Write-Output "🎉 SUCCESS! Container is healthy and running!"
            
            # Test the app
            $fqdn = az containerapp show --name $ContainerAppName -g $ResourceGroup --query "properties.configuration.ingress.fqdn" -o tsv
            if ($fqdn) {
                Write-Output "🌐 Testing app at: https://$fqdn"
                try {
                    $response = Invoke-WebRequest -Uri "https://$fqdn/api/health" -UseBasicParsing -TimeoutSec 10
                    Write-Output "✅ App responds with status: $($response.StatusCode)"
                } catch {
                    Write-Output "⚠️  App test failed: $($_.Exception.Message)"
                }
            }
            
            exit 0
        }
        
        if ($latest.health -eq "Unhealthy" -or $latest.running -eq "Failed") {
            Write-Output "❌ Deployment failed. Checking logs..."
            az containerapp logs show --name $ContainerAppName -g $ResourceGroup --tail 10 --follow false
            exit 1
        }
        
    } catch {
        Write-Warning "Error checking status: $($_.Exception.Message)"
    }
    
    Write-Output ""
    
    if ($currentTime -lt $timeoutTime) {
        Start-Sleep -Seconds 30
    }
    
} while ($currentTime -lt $timeoutTime)

Write-Output "⏰ Timeout reached after $TimeoutMinutes minutes"
Write-Output "💡 Check manually: az containerapp show --name $ContainerAppName -g $ResourceGroup"