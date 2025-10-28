#!/usr/bin/env pwsh
# demo-monitoring-features.ps1 - Demonstrate monitoring features

Write-Output "📊 MONITORING & OBSERVABILITY DEMONSTRATION"
Write-Output "══════════════════════════════════════════════════"
Write-Output ""

# 1. Show Azure Application Insights
Write-Output "1. 🔍 Azure Application Insights Configuration"
Write-Output ""

Write-Output "✅ Container App with App Insights:"
Write-Output "   📍 App Name: internship-api"
Write-Output "   🌐 Resource Group: placement-tracker-rg"
Write-Output "   📊 Instrumentation Key: APPINSIGHTS_INSTRUMENTATIONKEY"
Write-Output "   🎯 Connection String: APPLICATIONINSIGHTS_CONNECTION_STRING"

# Get container app info
Write-Output ""
Write-Output "🔄 Checking current container app status..."

$appStatus = az containerapp show --name internship-api --resource-group placement-tracker-rg --query "{status:properties.runningStatus,fqdn:properties.configuration.ingress.fqdn,traffic:properties.configuration.ingress.traffic[0].weight}" -o json 2>$null

if ($appStatus) {
    $appInfo = $appStatus | ConvertFrom-Json
    Write-Output "   📈 Status: $($appInfo.status)"
    Write-Output "   🌐 Endpoint: https://$($appInfo.fqdn)"
    Write-Output "   🚦 Traffic: $($appInfo.traffic)%"
} else {
    Write-Output "   ⚠️  Run 'az login' first to view live status"
}

Write-Output ""
Write-Output "───────────────────────────────────────────────────"
Write-Output ""

# 2. Show Docker Configuration
Write-Output "2. 🐳 Docker Monitoring Configuration"
Write-Output ""

if (Test-Path "docker-compose.yml") {
    Write-Output "✅ Docker Compose Monitoring Stack:"
    Write-Output "   📍 Location: docker-compose.yml"
    
    $dockerContent = Get-Content "docker-compose.yml" -Raw
    if ($dockerContent -match "app_insights") {
        Write-Output "   📊 Includes Application Insights integration"
    }
    
    # Show monitoring services
    $services = (Get-Content "docker-compose.yml" | Select-String "^\s*[a-z].*:" | ForEach-Object { $_.Line.Trim().Replace(":", "") })
    Write-Output "   🎯 Services configured:"
    $services | ForEach-Object { Write-Output "      • $_" }
}

Write-Output ""
Write-Output "───────────────────────────────────────────────────"
Write-Output ""

# 3. Show Monitoring Documentation
Write-Output "3. 📚 Monitoring Documentation"
Write-Output ""

if (Test-Path "Monitoring_Dashboard.md") {
    Write-Output "✅ Monitoring Dashboard Guide:"
    Write-Output "   📍 Location: Monitoring_Dashboard.md"
    $monitoringContent = Get-Content "Monitoring_Dashboard.md" | Select-Object -First 10
    Write-Output "   📝 Content Preview:"
    $monitoringContent | ForEach-Object { Write-Output "      $_" }
}

Write-Output ""
Write-Output "───────────────────────────────────────────────────"
Write-Output ""

# 4. Show Alert Configuration
Write-Output "4. 🚨 Alert Configuration"
Write-Output ""

if (Test-Path "scripts/create-appinsights-alert.ps1") {
    Write-Output "✅ Application Insights Alert Script:"
    Write-Output "   📍 Location: scripts/create-appinsights-alert.ps1"
    Write-Output "   🎯 Creates alerts for:"
    Write-Output "      • High response times"
    Write-Output "      • Error rates"
    Write-Output "      • Availability issues"
    Write-Output "   📧 Notification: Email alerts configured"
}

Write-Output ""
Write-Output "═══════════════════════════════════════════════════"
Write-Output ""

# 5. How to Access Monitoring
Write-Output "🚀 HOW TO ACCESS MONITORING DATA:"
Write-Output ""
Write-Output "Method 1 - Azure Portal:"
Write-Output "   1. Open Azure Portal (portal.azure.com)"
Write-Output "   2. Navigate to placement-tracker-rg resource group"
Write-Output "   3. Open Application Insights resource"
Write-Output "   4. View metrics, logs, and performance data"
Write-Output ""
Write-Output "Method 2 - Container App Logs:"
Write-Output "   1. Azure Portal → Container Apps"
Write-Output "   2. Select internship-api"
Write-Output "   3. Go to Monitoring → Log stream"
Write-Output ""
Write-Output "Method 3 - Application Performance:"
Write-Output "   1. Application Insights → Performance"
Write-Output "   2. View response times and dependencies"
Write-Output "   3. Analyze user sessions and page views"

Write-Output ""
Write-Output "📊 LIVE MONITORING ENDPOINTS:"
Write-Output "• Application: https://internship-api.gentleforest-68343e46.centralindia.azurecontainerapps.io"
Write-Output "• Health Check: https://internship-api.gentleforest-68343e46.centralindia.azurecontainerapps.io/health"
Write-Output "• Azure Portal: https://portal.azure.com/#@/resource/subscriptions/.../resourceGroups/placement-tracker-rg"

Write-Output ""
Write-Output "🔧 DEMO COMMANDS:"
Write-Output ""
Write-Output "Test application health:"
Write-Output "   curl https://internship-api.gentleforest-68343e46.centralindia.azurecontainerapps.io/health"
Write-Output ""
Write-Output "Generate monitoring data:"
Write-Output "   .\scripts\smoke-test.ps1"
Write-Output ""
Write-Output "Create alerts:"
Write-Output "   .\scripts\create-appinsights-alert.ps1"

Write-Output ""
Write-Output "✅ MONITORING DEMONSTRATION COMPLETE!"