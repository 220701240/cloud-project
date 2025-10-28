#!/usr/bin/env pwsh
# deploy-from-local.ps1 - Deploy the cloud-built image from local machine

param(
    [string]$ImageTag = "latest",
    [string]$ResourceGroup = "placement-tracker-rg",
    [string]$ContainerAppName = "internship-api",
    [string]$AcrName = "cloudprojectacr",
    [string]$ImageName = "internship-api"
)

Write-Output "=== Deploying Cloud-Built Image ==="
Write-Output "Resource Group: $ResourceGroup"
Write-Output "Container App: $ContainerAppName"
Write-Output "Image: $AcrName.azurecr.io/$ImageName`:$ImageTag"
Write-Output ""

try {
    # Check if image exists in ACR
    Write-Output "Checking if image exists in ACR..."
    $tags = az acr repository show-tags --name $AcrName --repository $ImageName --output table
    Write-Output "Available tags:"
    Write-Output $tags
    Write-Output ""
    
    # Deploy the image
    $fullImage = "$AcrName.azurecr.io/$ImageName`:$ImageTag"
    Write-Output "Deploying image: $fullImage"
    
    az containerapp update `
        --name $ContainerAppName `
        --resource-group $ResourceGroup `
        --image $fullImage
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Container app update failed"
        exit 1
    }
    
    Write-Output "✅ Container app updated successfully!"
    Write-Output ""
    Write-Output "Waiting for deployment to stabilize..."
    Start-Sleep -Seconds 60
    
    # Check revision health
    Write-Output "Checking revision health..."
    $latestRevision = az containerapp revision list `
        --name $ContainerAppName `
        --resource-group $ResourceGroup `
        --query "[0].{name:name,health:properties.healthState,running:properties.runningState,image:properties.template.containers[0].image}" `
        -o json | ConvertFrom-Json
    
    Write-Output "Latest revision details:"
    Write-Output "  Name: $($latestRevision.name)"
    Write-Output "  Health: $($latestRevision.health)"
    Write-Output "  Running: $($latestRevision.running)"
    Write-Output "  Image: $($latestRevision.image)"
    Write-Output ""
    
    # Test the app
    $fqdn = az containerapp show --name $ContainerAppName --resource-group $ResourceGroup --query "properties.configuration.ingress.fqdn" -o tsv
    
    if ($fqdn) {
        Write-Output "🌐 App URL: https://$fqdn"
        Write-Output "Testing app health..."
        
        try {
            $response = Invoke-WebRequest -Uri "https://$fqdn/api/health" -UseBasicParsing -TimeoutSec 15
            Write-Output "✅ App is healthy! Status: $($response.StatusCode)"
            Write-Output "🎉 Deployment successful!"
            
            # Test a few more endpoints
            Write-Output ""
            Write-Output "Testing additional endpoints..."
            
            try {
                $loginResponse = Invoke-WebRequest -Uri "https://$fqdn/api/login" -Method POST -Body '{"email":"test","password":"test"}' -ContentType "application/json" -UseBasicParsing -TimeoutSec 10
                Write-Output "✅ /api/login endpoint responding (Status: $($loginResponse.StatusCode))"
            } catch {
                Write-Output "ℹ️ /api/login endpoint test: $($_.Exception.Message)"
            }
            
        } catch {
            Write-Output "⚠️ App health test failed: $($_.Exception.Message)"
            
            Write-Output "Checking recent logs..."
            az containerapp logs show --name $ContainerAppName --resource-group $ResourceGroup --tail 20 --follow false
        }
    } else {
        Write-Output "❌ Could not retrieve app FQDN"
    }
    
} catch {
    Write-Error "Deployment failed: $($_.Exception.Message)"
    exit 1
}

Write-Output ""
Write-Output "=== Deployment Complete ==="