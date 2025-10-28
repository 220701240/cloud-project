#!/usr/bin/env pwsh
# test-monitoring.ps1 - Test monitoring and observability requirements

param(
    [string]$ResourceGroup = "placement-tracker-rg",
    [string]$ContainerAppName = "internship-api",
    [string]$AppInsightsName = "internship-api-ai"
)

Write-Output "=== Testing Requirement #2: Monitoring & Observability ==="
Write-Output ""

# Test 1: Check App Insights Configuration
Write-Output "1. Testing App Insights Configuration..."
try {
    # Check if App Insights exists
    $appInsights = az monitor app-insights component show --app $AppInsightsName -g $ResourceGroup --query "{name:name,instrumentationKey:instrumentationKey}" -o json 2>$null | ConvertFrom-Json
    
    if ($appInsights) {
        Write-Output "✅ App Insights resource exists: $($appInsights.name)"
        Write-Output "✅ Instrumentation key available: $($appInsights.instrumentationKey.Substring(0,8))..."
    } else {
        Write-Output "⚠️ App Insights resource not found (may use different name)"
    }
} catch {
    Write-Output "⚠️ Could not verify App Insights: $($_.Exception.Message)"
}

Write-Output ""

# Test 2: Check Container App Monitoring Configuration
Write-Output "2. Testing Container App Monitoring Configuration..."
try {
    $envVars = az containerapp show --name $ContainerAppName -g $ResourceGroup --query "properties.template.containers[0].env[?name=='APPINSIGHTS_INSTRUMENTATIONKEY'].value" -o tsv 2>$null
    
    if ($envVars) {
        Write-Output "✅ APPINSIGHTS_INSTRUMENTATIONKEY configured in container app"
        Write-Output "   Key: $($envVars.Substring(0,8))..."
    } else {
        Write-Output "❌ APPINSIGHTS_INSTRUMENTATIONKEY not found in container app"
    }
} catch {
    Write-Output "❌ Error checking container app configuration: $($_.Exception.Message)"
}

Write-Output ""

# Test 3: Check Monitoring Scripts
Write-Output "3. Testing Monitoring Scripts..."
$alertScript = Test-Path "scripts/create-appinsights-alert.ps1"
$monitorScript = Test-Path "scripts/monitor-final-deployment.ps1"

if ($alertScript) {
    Write-Output "✅ Alert creation script found"
}
if ($monitorScript) {
    Write-Output "✅ Monitoring script found"
}

Write-Output ""

# Test 4: Check Documentation
Write-Output "4. Testing Monitoring Documentation..."
$monitoringDocs = Test-Path "Monitoring_Dashboard.md"
if ($monitoringDocs) {
    Write-Output "✅ Monitoring documentation found"
    $docsContent = Get-Content "Monitoring_Dashboard.md" -Raw
    if ($docsContent -match "Application Insights") {
        Write-Output "✅ Documentation covers App Insights"
    }
    if ($docsContent -match "alert") {
        Write-Output "✅ Documentation covers alerting"
    }
}

Write-Output ""

# Test 5: Test App Health and Generate Telemetry
Write-Output "5. Testing Application and Generating Telemetry..."
try {
    $fqdn = az containerapp show --name $ContainerAppName -g $ResourceGroup --query "properties.configuration.ingress.fqdn" -o tsv
    
    if ($fqdn) {
        Write-Output "✅ App FQDN: https://$fqdn"
        
        # Test multiple endpoints to generate telemetry
        Write-Output "Generating test telemetry..."
        for ($i = 1; $i -le 5; $i++) {
            try {
                $response = Invoke-WebRequest -Uri "https://$fqdn/" -UseBasicParsing -TimeoutSec 10 -ErrorAction SilentlyContinue
                Write-Output "   Request $i`: Response received"
            } catch {
                Write-Output "   Request $i`: $($_.Exception.Message)"
            }
            Start-Sleep -Seconds 2
        }
        
        Write-Output "✅ Test requests completed (telemetry should be visible in App Insights)"
    }
} catch {
    Write-Output "⚠️ Could not test app: $($_.Exception.Message)"
}

Write-Output ""

# Test 6: Check for Existing Alerts
Write-Output "6. Testing Monitoring Alerts..."
try {
    $alerts = az monitor metrics alert list -g $ResourceGroup --query "[?contains(name, 'AppInsights') || contains(name, 'internship')].{name:name,enabled:enabled}" -o table 2>$null
    
    if ($alerts -and $alerts.Length -gt 0) {
        Write-Output "✅ Monitoring alerts found:"
        Write-Output $alerts
    } else {
        Write-Output "ℹ️ No monitoring alerts found (can be created using provided scripts)"
    }
} catch {
    Write-Output "ℹ️ Could not check alerts: $($_.Exception.Message)"
}

Write-Output ""
Write-Output "📊 Monitoring & Observability Test Results:"

$hasAppInsights = $appInsights -ne $null
$hasEnvVar = $envVars -ne $null -and $envVars.Length -gt 0
$hasScripts = $alertScript -and $monitorScript
$hasDocs = $monitoringDocs

if ($hasAppInsights -and $hasEnvVar -and $hasScripts -and $hasDocs) {
    Write-Output "✅ REQUIREMENT #2: FULLY SATISFIED"
    Write-Output "   - App Insights: Configured"
    Write-Output "   - Container Integration: Active"
    Write-Output "   - Automation Scripts: Available"
    Write-Output "   - Documentation: Complete"
} else {
    Write-Output "🟡 REQUIREMENT #2: PARTIALLY SATISFIED"
    Write-Output "   - App Insights: $(if ($hasAppInsights) {'✅'} else {'❌'})"
    Write-Output "   - Container Integration: $(if ($hasEnvVar) {'✅'} else {'❌'})"
    Write-Output "   - Scripts: $(if ($hasScripts) {'✅'} else {'❌'})"
    Write-Output "   - Documentation: $(if ($hasDocs) {'✅'} else {'❌'})"
}

Write-Output ""
Write-Output "🔍 To view monitoring data:"
Write-Output "1. Go to Azure Portal → Application Insights → $AppInsightsName"
Write-Output "2. Check 'Live Metrics' for real-time data"
Write-Output "3. View 'Metrics' for historical data"
Write-Output "4. Check 'Logs' for detailed telemetry"

Write-Output ""
Write-Output "=== Monitoring & Observability Test Complete ==="