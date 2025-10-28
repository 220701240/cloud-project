#!/usr/bin/env pwsh
# manual-docker-build.ps1 - Manually build and push Docker image

param(
    [string]$AcrName = "cloudprojectacr",
    [string]$ImageName = "internship-api",
    [string]$Tag = "manual-fix"
)

$acrLoginServer = "$AcrName.azurecr.io"

Write-Output "=== Manual Docker Build and Push ==="
Write-Output "ACR: $AcrName"
Write-Output "Image: $ImageName"
Write-Output "Tag: $Tag"
Write-Output ""

try {
    # Login to ACR
    Write-Output "1. Logging into ACR..."
    az acr login --name $AcrName
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "ACR login failed"
        exit 1
    }
    
    # Navigate to internship-api directory
    Write-Output "2. Navigating to internship-api directory..."
    Set-Location internship-api
    
    # Build the image (try basic command first)
    Write-Output "3. Building Docker image..."
    $imageFull = "$acrLoginServer/$ImageName`:$Tag"
    
    Write-Output "Building: $imageFull"
    & docker build -t $imageFull .
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Docker build failed with exit code: $LASTEXITCODE"
        exit 1
    }
    
    Write-Output "✅ Docker build successful!"
    
    # Push the image
    Write-Output "4. Pushing image to ACR..."
    & docker push $imageFull
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Docker push failed with exit code: $LASTEXITCODE"
        exit 1
    }
    
    Write-Output "✅ Docker push successful!"
    Write-Output ""
    Write-Output "Image available at: $imageFull"
    Write-Output ""
    Write-Output "To deploy this image, run:"
    Write-Output "az containerapp update --name internship-api --resource-group placement-tracker-rg --image $imageFull"
    
} catch {
    Write-Error "Build failed: $($_.Exception.Message)"
    exit 1
} finally {
    Set-Location ..
}