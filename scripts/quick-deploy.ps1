# Quick Deploy - Integrated Frontend+Backend
# This builds from the root directory to include both frontend and backend

Write-Output "==============================================="
Write-Output "QUICK DEPLOY: INTEGRATED FRONTEND+BACKEND"
Write-Output "==============================================="
Write-Output ""

Write-Output "Building from project root to include both frontend and backend..."
Write-Output ""

try {
    # Make sure we're in the project root
    Set-Location "c:\Users\Anish\OneDrive\Documents\cloud-project"
    
    Write-Output "Building integrated container..."
    $buildResult = docker build -f Dockerfile.integrated -t cloudprojectacr.azurecr.io/internship-api:integrated .
    
    if ($LASTEXITCODE -eq 0) {
        Write-Output "✅ Build successful!"
    } else {
        Write-Output "❌ Build failed!"
        exit 1
    }
    
    Write-Output ""
    Write-Output "Pushing to registry..."
    $pushResult = docker push cloudprojectacr.azurecr.io/internship-api:integrated
    
    if ($LASTEXITCODE -eq 0) {
        Write-Output "✅ Push successful!"
    } else {
        Write-Output "❌ Push failed!"
        exit 1
    }
    
    Write-Output ""
    Write-Output "Updating Container App..."
    $updateResult = az containerapp update --name internship-api -g placement-tracker-rg --image cloudprojectacr.azurecr.io/internship-api:integrated
    
    if ($LASTEXITCODE -eq 0) {
        Write-Output "✅ Container App updated!"
    } else {
        Write-Output "❌ Update failed!"
        exit 1
    }
    
    Write-Output ""
    Write-Output "🎉 SUCCESS! Your integrated app is deploying..."
    Write-Output ""
    Write-Output "In 1-2 minutes, you can access:"
    Write-Output "• Frontend: https://internship-api.gentleforest-68343e46.centralindia.azurecontainerapps.io/student.html"
    Write-Output "• API: https://internship-api.gentleforest-68343e46.centralindia.azurecontainerapps.io/api/students"
    Write-Output ""
    Write-Output "Perfect single URL for your demonstration! 🚀"
    
} catch {
    Write-Output "❌ Error: $($_.Exception.Message)"
    exit 1
}