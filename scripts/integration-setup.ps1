# Frontend-Backend Integration Setup
# This script helps you configure your frontend to work with your backend API

Write-Output "================================================="
Write-Output "FRONTEND-BACKEND INTEGRATION CONFIGURATION"
Write-Output "================================================="
Write-Output ""

$frontendUrl = "https://placement-tracker-app-aueydve4dehcf7de.centralindia-01.azurewebsites.net"
$backendUrl = "https://internship-api.gentleforest-68343e46.centralindia.azurecontainerapps.io"

Write-Output "YOUR CURRENT SETUP:"
Write-Output "==================="
Write-Output "Frontend (Azure App Service): $frontendUrl"
Write-Output "Backend (Container App):      $backendUrl"
Write-Output ""

Write-Output "OPTION 1: Use Frontend App Service (RECOMMENDED)"
Write-Output "================================================="
Write-Output ""
Write-Output "Your frontend is now hosted separately from backend."
Write-Output "You need to update your JavaScript to call the backend API URL."
Write-Output ""
Write-Output "Benefits:"
Write-Output "• Professional separation of frontend and backend"
Write-Output "• Better scalability"
Write-Output "• Independent deployments"
Write-Output "• Modern architecture"
Write-Output ""

Write-Output "OPTION 2: Serve Frontend from Backend Container"
Write-Output "==============================================="
Write-Output ""
Write-Output "You can also serve your HTML files directly from the backend."
Write-Output "This is simpler but less scalable."
Write-Output ""

Write-Output "TESTING YOUR CURRENT SETUP:"
Write-Output "==========================="
Write-Output ""

Write-Output "1. Testing Frontend App Service:"
try {
    $frontendResponse = Invoke-WebRequest -Uri $frontendUrl -UseBasicParsing -TimeoutSec 10
    Write-Output "✅ Frontend Status: HTTP $($frontendResponse.StatusCode)"
    Write-Output "✅ Frontend is accessible"
} catch {
    Write-Output "❌ Frontend Error: $($_.Exception.Message)"
}

Write-Output ""
Write-Output "2. Testing Backend API:"
try {
    $backendResponse = Invoke-WebRequest -Uri "$backendUrl/api/students" -UseBasicParsing -TimeoutSec 10
    Write-Output "✅ Backend Status: HTTP $($backendResponse.StatusCode)"
    Write-Output "✅ Backend API is working"
} catch {
    Write-Output "❌ Backend Error: $($_.Exception.Message)"
}

Write-Output ""
Write-Output "3. Testing Backend Root (for serving frontend):"
try {
    $backendRootResponse = Invoke-WebRequest -Uri $backendUrl -UseBasicParsing -TimeoutSec 10
    Write-Output "✅ Backend Root Status: HTTP $($backendRootResponse.StatusCode)"
} catch {
    Write-Output "❌ Backend Root: Cannot serve frontend files"
}

Write-Output ""
Write-Output "CONFIGURATION NEEDED:"
Write-Output "====================="
Write-Output ""
Write-Output "TO USE OPTION 1 (Separate Frontend/Backend):"
Write-Output "---------------------------------------------"
Write-Output ""
Write-Output "Update your frontend JavaScript files to use the backend URL:"
Write-Output ""
Write-Output "OLD CODE (relative URLs):"
Write-Output "  fetch('/api/students')"
Write-Output ""
Write-Output "NEW CODE (absolute URLs):"
Write-Output "  fetch('$backendUrl/api/students')"
Write-Output ""
Write-Output "Files to update:"
Write-Output "• frontend/student.html"
Write-Output "• frontend/admin.html"
Write-Output "• Any other HTML files making API calls"
Write-Output ""

Write-Output "TO USE OPTION 2 (Backend serves frontend):"
Write-Output "--------------------------------------------"
Write-Output ""
Write-Output "Configure your backend to serve static files."
Write-Output "Your Node.js app needs to serve HTML files."
Write-Output ""

Write-Output "DEMONSTRATION URLS:"
Write-Output "=================="
Write-Output ""
Write-Output "Option 1 - Separate Apps:"
Write-Output "Frontend: $frontendUrl"
Write-Output "Backend:  $backendUrl/api/students"
Write-Output ""
Write-Output "Option 2 - Backend serves all:"
Write-Output "Everything: $backendUrl"
Write-Output ""

Write-Output "NEXT STEPS:"
Write-Output "==========="
Write-Output ""
Write-Output "1. Choose your preferred option"
Write-Output "2. Update configuration accordingly"
Write-Output "3. Test the integration"
Write-Output "4. Demo to your mentor"
Write-Output ""
Write-Output "Which option would you like to implement?"