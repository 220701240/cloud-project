# Quick Solution: Make Backend Serve Frontend
# This will enable your single URL to show both frontend and API

Write-Output "============================================="
Write-Output "QUICK SOLUTION: SINGLE URL FOR EVERYTHING"
Write-Output "============================================="
Write-Output ""

$backendUrl = "https://internship-api.gentleforest-68343e46.centralindia.azurecontainerapps.io"

Write-Output "CURRENT SITUATION:"
Write-Output "=================="
Write-Output "✅ Backend API working: $backendUrl/api/students"
Write-Output "❌ Frontend files not accessible: $backendUrl/student.html"
Write-Output ""

Write-Output "SOLUTION:"
Write-Output "========="
Write-Output "Your backend is already configured to serve frontend files,"
Write-Output "but the frontend folder isn't included in the Docker container."
Write-Output ""

Write-Output "Let's fix this by updating the Dockerfile:"
Write-Output ""

Write-Output "STEP 1: Update Dockerfile to include frontend files"
Write-Output "STEP 2: Rebuild and redeploy"
Write-Output "STEP 3: Test the integration"
Write-Output ""

Write-Output "After this fix, you'll access everything from one URL:"
Write-Output "• Frontend: $backendUrl/student.html"
Write-Output "• API: $backendUrl/api/students"
Write-Output ""

Write-Output "BENEFITS OF THIS APPROACH:"
Write-Output "=========================="
Write-Output "✅ Single URL for everything"
Write-Output "✅ No CORS issues"
Write-Output "✅ Simpler deployment"
Write-Output "✅ Perfect for demonstration"
Write-Output ""

Write-Output "Ready to implement this solution? (y/n)"