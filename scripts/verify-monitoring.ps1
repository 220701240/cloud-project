#!/usr/bin/env pwsh
# verify-monitoring.ps1 - Check if monitoring is properly configured

param(
    [string]$ResourceGroup = "placement-tracker-rg",
    [string]$ContainerAppName = "internship-api",
    [string]$AppInsightsName = "internship-api-ai"
)

Write-Output "=== Monitoring & Observability Verification ==="
Write-Output ""

# Check if App Insights resource exists
Write-Output "1. Checking Application Insights resource..."
try {
    $appInsights = az monitor app-insights component show --app $AppInsightsName -g $ResourceGroup --query "{name:name,instrumentationKey:instrumentationKey,connectionString:connectionString}" -o json 2>$null | ConvertFrom-Json
    
    if ($appInsights) {
        Write-Output "✅ Application Insights found: $($appInsights.name)"
        Write-Output "   Instrumentation Key: $($appInsights.instrumentationKey.Substring(0,8))..."
    } else {
        Write-Output "❌ Application Insights resource '$AppInsightsName' not found"
        Write-Output "   Creating Application Insights resource..."
        
        az monitor app-insights component create `
            --app $AppInsightsName `
            --location "Central India" `
            --resource-group $ResourceGroup `
            --kind web `
            --application-type web
        
        $appInsights = az monitor app-insights component show --app $AppInsightsName -g $ResourceGroup --query "{name:name,instrumentationKey:instrumentationKey}" -o json | ConvertFrom-Json
        Write-Output "✅ Created: $($appInsights.name)"
    }
} catch {
    Write-Warning "Failed to check/create App Insights: $($_.Exception.Message)"
}

Write-Output ""

# Check if container app has App Insights configured
Write-Output "2. Checking Container App environment variables..."
try {
    $envVars = az containerapp show --name $ContainerAppName -g $ResourceGroup --query "properties.template.containers[0].env[?name=='APPINSIGHTS_INSTRUMENTATIONKEY'].value" -o tsv
    
    if ($envVars) {
        Write-Output "✅ APPINSIGHTS_INSTRUMENTATIONKEY is configured in container app"
    } else {
        Write-Output "❌ APPINSIGHTS_INSTRUMENTATIONKEY not found in container app"
        
        if ($appInsights.instrumentationKey) {
            Write-Output "   Setting instrumentation key..."
            az containerapp update `
                --name $ContainerAppName `
                --resource-group $ResourceGroup `
                --set-env-vars APPINSIGHTS_INSTRUMENTATIONKEY=$($appInsights.instrumentationKey)
            Write-Output "✅ Instrumentation key added to container app"
        }
    }
} catch {
    Write-Warning "Failed to check container app env vars: $($_.Exception.Message)"
}

Write-Output ""

# Test if app is sending telemetry
Write-Output "3. Testing application telemetry..."
try {
    $fqdn = az containerapp show --name $ContainerAppName -g $ResourceGroup --query "properties.configuration.ingress.fqdn" -o tsv
    
    if ($fqdn) {
        Write-Output "   App URL: https://$fqdn"
        Write-Output "   Making test requests to generate telemetry..."
        
        # Make a few test requests
        for ($i = 1; $i -le 5; $i++) {
            try {
                $response = Invoke-WebRequest -Uri "https://$fqdn/api/health" -UseBasicParsing -TimeoutSec 10
                Write-Output "   Request $i`: Status $($response.StatusCode)"
            } catch {
                Write-Output "   Request $i`: Failed - $($_.Exception.Message)"
            }
        }
        
        Write-Output ""
        Write-Output "Check telemetry in Azure Portal:"
        Write-Output "   1. Go to Application Insights -> $AppInsightsName"
        Write-Output "   2. Click 'Live Metrics' to see real-time data"
        Write-Output "   3. Check 'Metrics' for request counts and response times"
        Write-Output "   4. View 'Logs' for detailed request information"
    }
} catch {
    Write-Warning "Failed to test application: $($_.Exception.Message)"
}
}

Write-Output ""

# Check for existing alerts
Write-Output "4. Checking monitoring alerts..."
try {
    $alerts = az monitor metrics alert list -g $ResourceGroup --query "[?contains(name, 'AppInsights') || contains(name, 'Failed')].{name:name,enabled:enabled,severity:severity}" -o table
    
    if ($alerts) {
        Write-Output "✅ Monitoring alerts found:"
        Write-Output $alerts
    } else {
        Write-Output "❌ No monitoring alerts found"
        Write-Output "   Use create-appinsights-alert.ps1 to create alerts"
    }
} catch {
    Write-Warning "Failed to check alerts: $($_.Exception.Message)"
}

Write-Output ""
Write-Output "=== Verification Complete ==="
Write-Output "Next steps:"
Write-Output "1. Check Azure Portal -> Application Insights -> Live Metrics"
Write-Output "2. Create alerts using: .\scripts\create-appinsights-alert.ps1"
Write-Output "3. Set up dashboard in Azure Portal or Power BI"