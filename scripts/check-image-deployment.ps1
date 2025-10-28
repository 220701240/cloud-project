#!/usr/bin/env pwsh
# check-image-deployment.ps1 - Verify image deployment to Container App

$ResourceGroup = "placement-tracker-rg"
$ContainerAppName = "internship-api"
$AcrName = "$(ACR_NAME)"  # Replace with your actual ACR name
$ExpectedBuildId = "89"   # Current build ID

Write-Output "=== Checking Image Deployment Status ==="
Write-Output ""

# 1. Check what image is currently running in Container App
Write-Output "1. Current Container App Image:"
Write-Output "================================"
try {
    $currentImage = az containerapp show `
        --name $ContainerAppName `
        --resource-group $ResourceGroup `
        --query "properties.template.containers[0].image" -o tsv
    
    Write-Output "Current image: $currentImage"
    
    if ($currentImage -match ":$ExpectedBuildId$") {
        Write-Output "✅ SUCCESS: Container app is using build $ExpectedBuildId"
    } else {
        Write-Output "⚠️  WARNING: Container app may not be using the expected build $ExpectedBuildId"
    }
} catch {
    Write-Error "Failed to get container app image: $($_.Exception.Message)"
}

Write-Output ""

# 2. Check active revisions
Write-Output "2. Active Revisions:"
Write-Output "==================="
try {
    az containerapp revision list `
        --name $ContainerAppName `
        --resource-group $ResourceGroup `
        --query "[?properties.active==``true``].{Name:name,Image:properties.template.containers[0].image,Created:properties.createdTime,State:properties.runningState}" `
        -o table
} catch {
    Write-Error "Failed to get revisions: $($_.Exception.Message)"
}

Write-Output ""

# 3. Check if image exists in ACR
Write-Output "3. Container Registry Images:"
Write-Output "============================="
Write-Output "Checking for build $ExpectedBuildId in ACR..."

try {
    # List recent tags for internship-api repository
    $tags = az acr repository show-tags `
        --name $AcrName `
        --repository "internship-api" `
        --orderby time_desc `
        --output table
    
    Write-Output $tags
    
    # Check if specific build tag exists
    $buildTagExists = az acr repository show-tags `
        --name $AcrName `
        --repository "internship-api" `
        --query "[?contains(@, '$ExpectedBuildId')]" `
        -o tsv
    
    if ($buildTagExists) {
        Write-Output "✅ SUCCESS: Build $ExpectedBuildId found in ACR"
    } else {
        Write-Output "❌ ERROR: Build $ExpectedBuildId not found in ACR"
    }
} catch {
    Write-Warning "Could not check ACR (make sure ACR_NAME variable is set): $($_.Exception.Message)"
}

Write-Output ""

# 4. Check container app health
Write-Output "4. Container App Health:"
Write-Output "======================="
try {
    $healthInfo = az containerapp show `
        --name $ContainerAppName `
        --resource-group $ResourceGroup `
        --query "{provisioningState:properties.provisioningState,runningState:properties.runningState,fqdn:properties.configuration.ingress.fqdn}" `
        -o json | ConvertFrom-Json
    
    Write-Output "Provisioning State: $($healthInfo.provisioningState)"
    Write-Output "Running State: $($healthInfo.runningState)"
    if ($healthInfo.fqdn) {
        Write-Output "App URL: https://$($healthInfo.fqdn)"
        Write-Output ""
        Write-Output "🌐 Test your app: https://$($healthInfo.fqdn)"
    }
} catch {
    Write-Error "Failed to get health info: $($_.Exception.Message)"
}

Write-Output ""
Write-Output "=== Check completed ==="
Write-Output ""
Write-Output "💡 To check in Azure Portal:"
Write-Output "   1. Go to Container Apps → $ContainerAppName → Revisions and replicas"
Write-Output "   2. Go to Container Registries → [Your ACR] → Repositories → internship-api"