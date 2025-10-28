#!/usr/bin/env pwsh
# monitor-final-deployment.ps1 - Monitor the final deployment and verify requirements

param(
    [string]$ResourceGroup = "placement-tracker-rg",
    [string]$ContainerAppName = "internship-api"
)

Write-Output "=== Final Deployment Monitoring ==="
Write-Output "Monitoring Container App: $ContainerAppName"
Write-Output "Started at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Output ""

# Function to check requirements
function Test-Requirements {
    Write-Output "🔍 Checking Requirements Compliance..."
    Write-Output ""
    
    # Requirement 1: Security Scanning
    Write-Output "📋 Requirement #1: CI/CD Security & Code Scanning"
    
    $hasOWASP = Test-Path ".github/workflows/owasp-zap-scan.yml"
    $hasCodeQL = Test-Path ".github/workflows/codeql-analysis.yml"
    $hasAzurePipelineOWASP = Select-String -Path "azure-pipelines.yml" -Pattern "OWASP ZAP" -Quiet
    
    if ($hasOWASP -and $hasCodeQL -and $hasAzurePipelineOWASP) {
        Write-Output "  ✅ COMPLETE: OWASP ZAP + CodeQL implemented"
        Write-Output "    - GitHub CodeQL workflow: ✅"
        Write-Output "    - GitHub OWASP ZAP workflow: ✅"  
        Write-Output "    - Azure Pipeline OWASP scan: ✅"
        $req1Status = "✅ COMPLETE"
    } else {
        Write-Output "  🟡 PARTIAL: Some components missing"
        $req1Status = "🟡 PARTIAL"
    }
    
    Write-Output ""
    
    # Requirement 2: Monitoring & Observability
    Write-Output "📋 Requirement #2: Monitoring & Observability"
    
    try {
        $envVars = az containerapp show --name $ContainerAppName -g $ResourceGroup --query "properties.template.containers[0].env[?name=='APPINSIGHTS_INSTRUMENTATIONKEY'].value" -o tsv 2>$null
        $hasAppInsights = $envVars -ne $null -and $envVars.Length -gt 0
        
        $hasAlertScript = Test-Path "scripts/create-appinsights-alert.ps1"
        $hasMonitoringDocs = Test-Path "Monitoring_Dashboard.md"
        
        if ($hasAppInsights -and $hasAlertScript -and $hasMonitoringDocs) {
            Write-Output "  ✅ COMPLETE: App Insights + Alerting + Documentation"
            Write-Output "    - App Insights configured: ✅"
            Write-Output "    - Alert creation script: ✅"
            Write-Output "    - Monitoring documentation: ✅"
            $req2Status = "✅ COMPLETE"
        } else {
            Write-Output "  🟡 PARTIAL: Some components missing"
            $req2Status = "🟡 PARTIAL"
        }
    } catch {
        Write-Output "  ❌ ERROR: Could not check App Insights configuration"
        $req2Status = "❌ ERROR"
    }
    
    Write-Output ""
    Write-Output "📊 REQUIREMENTS SUMMARY:"
    Write-Output "  #1 Security Scanning: $req1Status"
    Write-Output "  #2 Monitoring & Observability: $req2Status"
    Write-Output ""
}

# Monitor deployment
$maxAttempts = 20
$attempt = 1

do {
    Write-Output "[$attempt/$maxAttempts] Checking deployment status..."
    
    try {
        $revision = az containerapp revision list `
            --name $ContainerAppName `
            --resource-group $ResourceGroup `
            --query "[0].{name:name,health:properties.healthState,running:properties.runningState,replicas:properties.replicas,image:properties.template.containers[0].image}" `
            -o json | ConvertFrom-Json
        
        Write-Output "  📦 Revision: $($revision.name)"
        Write-Output "  ❤️ Health: $($revision.health)"
        Write-Output "  🏃 Running: $($revision.running)"
        Write-Output "  📈 Replicas: $($revision.replicas)"
        Write-Output "  🖼️ Image: $($revision.image)"
        
        if ($revision.health -eq "Healthy" -and $revision.running -eq "Running") {
            Write-Output ""
            Write-Output "🎉 DEPLOYMENT SUCCESSFUL!"
            
            # Test the app
            $fqdn = az containerapp show --name $ContainerAppName -g $ResourceGroup --query "properties.configuration.ingress.fqdn" -o tsv
            Write-Output "🌐 App URL: https://$fqdn"
            
            try {
                $response = Invoke-WebRequest -Uri "https://$fqdn/api/health" -UseBasicParsing -TimeoutSec 10
                Write-Output "✅ App Health Check: PASSED (Status: $($response.StatusCode))"
            } catch {
                Write-Output "⚠️ App Health Check: FAILED ($($_.Exception.Message))"
            }
            
            Write-Output ""
            Test-Requirements
            
            Write-Output "🏆 PROJECT STATUS: READY FOR DEMO!"
            exit 0
        }
        
        if ($revision.health -eq "Unhealthy" -or $revision.running -eq "Failed") {
            Write-Output "❌ Deployment failed. Checking logs..."
            az containerapp logs show --name $ContainerAppName -g $ResourceGroup --tail 10 --follow false
            exit 1
        }
        
    } catch {
        Write-Warning "Error checking status: $($_.Exception.Message)"
    }
    
    $attempt++
    if ($attempt -le $maxAttempts) {
        Write-Output "  ⏳ Waiting 30 seconds..."
        Start-Sleep -Seconds 30
        Write-Output ""
    }
    
} while ($attempt -le $maxAttempts)

Write-Output "⏰ Timeout reached. Check status manually."