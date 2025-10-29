# Deploy Frontend+Backend Integration
# This script rebuilds your container to include frontend files

Write-Output "================================================"
Write-Output "DEPLOYING INTEGRATED FRONTEND+BACKEND SOLUTION"
Write-Output "================================================"
Write-Output ""

Write-Output "WHAT WE'RE DOING:"
Write-Output "=================="
Write-Output "1. ✅ Updated Dockerfile to include frontend files"
Write-Output "2. ✅ Fixed static file serving path in backend"
Write-Output "3. 🔄 Now rebuilding container with frontend included"
Write-Output "4. 🚀 Redeploying to Azure Container Apps"
Write-Output ""

Write-Output "After this deployment, you'll have:"
Write-Output "• Frontend: https://internship-api.gentleforest-68343e46.centralindia.azurecontainerapps.io/student.html"
Write-Output "• API: https://internship-api.gentleforest-68343e46.centralindia.azurecontainerapps.io/api/students"
Write-Output "• All from ONE URL! 🎯"
Write-Output ""

Write-Output "STEP 1: Building new container image..."
Write-Output "========================================"

try {
    Set-Location "c:\Users\Anish\OneDrive\Documents\cloud-project\internship-api"
    
    Write-Output "Building Docker image with frontend files..."
    $buildResult = docker build -t cloudprojectacr.azurecr.io/internship-api:integrated-frontend .
    
    if ($LASTEXITCODE -eq 0) {
        Write-Output "✅ Docker build successful!"
    } else {
        Write-Output "❌ Docker build failed!"
        exit 1
    }
} catch {
    Write-Output "❌ Build error: $($_.Exception.Message)"
    exit 1
}

Write-Output ""
Write-Output "STEP 2: Pushing to Azure Container Registry..."
Write-Output "=============================================="

try {
    $pushResult = docker push cloudprojectacr.azurecr.io/internship-api:integrated-frontend
    
    if ($LASTEXITCODE -eq 0) {
        Write-Output "✅ Push to ACR successful!"
    } else {
        Write-Output "❌ Push failed!"
        exit 1
    }
} catch {
    Write-Output "❌ Push error: $($_.Exception.Message)"
    exit 1
}

Write-Output ""
Write-Output "STEP 3: Updating Container App..."
Write-Output "=================================="

try {
    Set-Location "c:\Users\Anish\OneDrive\Documents\cloud-project"
    
    $updateResult = az containerapp update --name internship-api -g placement-tracker-rg --image cloudprojectacr.azurecr.io/internship-api:integrated-frontend
    
    if ($LASTEXITCODE -eq 0) {
        Write-Output "✅ Container App updated successfully!"
    } else {
        Write-Output "❌ Container App update failed!"
        exit 1
    }
} catch {
    Write-Output "❌ Update error: $($_.Exception.Message)"
    exit 1
}

Write-Output ""
Write-Output "STEP 4: Waiting for deployment to complete..."
Write-Output "=============================================="

Start-Sleep -Seconds 30
Write-Output "Checking deployment status..."

try {
    $status = az containerapp show --name internship-api -g placement-tracker-rg --query "properties.runningStatus" -o tsv
    Write-Output "Container App Status: $status"
} catch {
    Write-Output "Status check failed, but deployment may still be in progress..."
}

Write-Output ""
Write-Output "🎉 DEPLOYMENT COMPLETE!"
Write-Output "======================="
Write-Output ""
Write-Output "Your integrated application is now available at:"
Write-Output "https://internship-api.gentleforest-68343e46.centralindia.azurecontainerapps.io"
Write-Output ""
Write-Output "Test these URLs:"
Write-Output "• Landing Page: /index.html"
Write-Output "• Student Page: /student.html"
Write-Output "• Admin Page: /admin.html"
Write-Output "• API Endpoint: /api/students"
Write-Output ""
Write-Output "Perfect for your mentor demonstration! 🚀"