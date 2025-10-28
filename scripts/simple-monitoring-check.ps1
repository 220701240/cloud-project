#!/usr/bin/env pwsh
# simple-monitoring-check.ps1 - Simple monitoring verification

param(
    [string]$ResourceGroup = "placement-tracker-rg",
    [string]$ContainerAppName = "internship-api"
)

Write-Output "=== Simple Monitoring Check ==="
Write-Output ""

# Check if we're logged into Azure
Write-Output "1. Checking Azure CLI login status..."
try {
    $account = az account show --query "name" -o tsv
    if ($account) {
        Write-Output "✅ Logged in to Azure: $account"
    } else {
        Write-Output "❌ Not logged into Azure"
        Write-Output "Please run: az login"
        exit 1
    }
} catch {
    Write-Output "❌ Azure CLI not available or not logged in"
    exit 1
}

Write-Output ""

# Check container app exists and get environment variables
Write-Output "2. Checking Container App configuration..."
try {
    $appExists = az containerapp show --name $ContainerAppName -g $ResourceGroup --query "name" -o tsv 2>$null
    
    if ($appExists) {
        Write-Output "✅ Container App found: $appExists"
        
        # Check for App Insights environment variable
        $envVars = az containerapp show --name $ContainerAppName -g $ResourceGroup --query "properties.template.containers[0].env" -o json | ConvertFrom-Json
        
        $appInsightsVar = $envVars | Where-Object { $_.name -eq "APPINSIGHTS_INSTRUMENTATIONKEY" }
        
        if ($appInsightsVar) {
            Write-Output "✅ APPINSIGHTS_INSTRUMENTATIONKEY is configured"
            $key = $appInsightsVar.value
            if ($key -and $key.Length -gt 8) {
                Write-Output "   Key: $($key.Substring(0,8))..."
            }
        } else {
            Write-Output "❌ APPINSIGHTS_INSTRUMENTATIONKEY not found"
        }
        
    } else {
        Write-Output "❌ Container App '$ContainerAppName' not found in resource group '$ResourceGroup'"
        exit 1
    }
} catch {
    Write-Output "❌ Failed to check container app: $($_.Exception.Message)"
    exit 1
}

Write-Output ""

# Check for Application Insights resources in the resource group
Write-Output "3. Checking for Application Insights resources..."
try {
    $appInsightsResources = az resource list -g $ResourceGroup --resource-type "Microsoft.Insights/components" --query "[].{name:name,location:location}" -o json | ConvertFrom-Json
    
    if ($appInsightsResources.Count -gt 0) {
        Write-Output "✅ Found Application Insights resources:"
        foreach ($resource in $appInsightsResources) {
            Write-Output "   - $($resource.name) (Location: $($resource.location))"
        }
    } else {
        Write-Output "❌ No Application Insights resources found in resource group"
        Write-Output "   Consider creating one with:"
        Write-Output "   az monitor app-insights component create --app 'internship-api-ai' --location 'Central India' --resource-group '$ResourceGroup'"
    }
} catch {
    Write-Output "❌ Failed to check Application Insights resources: $($_.Exception.Message)"
}

Write-Output ""

# Get container app URL and test basic connectivity
Write-Output "4. Testing application connectivity..."
try {
    $fqdn = az containerapp show --name $ContainerAppName -g $ResourceGroup --query "properties.configuration.ingress.fqdn" -o tsv
    
    if ($fqdn) {
        Write-Output "✅ Container App FQDN: https://$fqdn"
        
        Write-Output "   Testing basic connectivity..."
        try {
            $response = Invoke-WebRequest -Uri "https://$fqdn" -UseBasicParsing -TimeoutSec 10
            Write-Output "   ✅ App is responding (Status: $($response.StatusCode))"
        } catch {
            Write-Output "   ❌ App not responding: $($_.Exception.Message)"
        }
        
    } else {
        Write-Output "❌ No FQDN configured for container app"
    }
} catch {
    Write-Output "❌ Failed to get container app URL: $($_.Exception.Message)"
}

Write-Output ""
Write-Output "=== Check Complete ==="
Write-Output ""
Write-Output "Next steps to complete monitoring setup:"
Write-Output "1. Create Application Insights if missing"
Write-Output "2. Configure instrumentation key in container app"
Write-Output "3. Create monitoring alerts"
Write-Output "4. Set up dashboards in Azure Portal"