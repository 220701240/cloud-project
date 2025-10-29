# live-demo-script.ps1 - Interactive demonstration script

Write-Output "🎬 LIVE FRONTEND-BACKEND DEMO SCRIPT"
Write-Output "===================================="
Write-Output ""

$baseUrl = "https://internship-api.gentleforest-68343e46.centralindia.azurecontainerapps.io"

Write-Output "📱 QUICK DEMO FOR YOUR MENTOR"
Write-Output "=============================="
Write-Output ""
Write-Output "1. 🌐 Open this URL in browser:"
Write-Output "   $baseUrl/student.html"
Write-Output ""
Write-Output "2. 🔍 Open Browser Developer Tools (F12)"
Write-Output "   → Go to 'Network' tab"
Write-Output "   → Refresh the page"
Write-Output ""

Write-Output "3. 👀 POINT OUT TO MENTOR:"
Write-Output "   ✅ See the API call: GET /api/students"
Write-Output "   ✅ Response shows JSON data from database"
Write-Output "   ✅ Students list populates automatically"
Write-Output ""

Write-Output "4. 📝 ADD A NEW STUDENT:"
Write-Output "   → Fill in form: Roll Number, Name, Email"
Write-Output "   → Upload any file as resume"
Write-Output "   → Click 'Add Student'"
Write-Output ""

Write-Output "5. 🔄 SHOW THE INTEGRATION:"
Write-Output "   ✅ Watch Network tab: POST /api/students"
Write-Output "   ✅ See the JSON request with student data"
Write-Output "   ✅ Student appears in list immediately"
Write-Output "   ✅ No page refresh needed!"
Write-Output ""

Write-Output "💡 WHAT TO EXPLAIN:"
Write-Output "=================="
Write-Output ""
Write-Output "'This demonstrates our full-stack integration:'"
Write-Output ""
Write-Output "🔹 Frontend (HTML/JavaScript) sends data to Backend (Node.js API)"
Write-Output "🔹 Backend processes and stores in Azure SQL Database"
Write-Output "🔹 Frontend fetches updated data and displays it"
Write-Output "🔹 All communication uses REST APIs with JSON"
Write-Output "🔹 Real-time updates without page refreshes"
Write-Output ""

Write-Output "🎯 TECHNICAL HIGHLIGHTS:"
Write-Output "========================"
Write-Output ""
Write-Output "• Separation of Concerns: Frontend ↔ API ↔ Database"
Write-Output "• RESTful API design with proper HTTP methods"
Write-Output "• JSON data exchange format"
Write-Output "• Asynchronous JavaScript (async/await)"
Write-Output "• File upload handling with Base64 encoding"
Write-Output "• Error handling and user feedback"
Write-Output "• Cloud-native architecture on Azure"
Write-Output ""

Write-Output "🌟 LIVE TESTING COMMANDS"
Write-Output "========================"

Write-Output ""
Write-Output "Testing API directly (show this first):"
try {
    $response = Invoke-WebRequest -Uri "$baseUrl/api/students" -UseBasicParsing -TimeoutSec 10
    Write-Output "✅ API Status: HTTP $($response.StatusCode)"
    Write-Output "✅ Data Length: $($response.Content.Length) bytes"
    
    $data = $response.Content | ConvertFrom-Json
    $count = if ($data -is [array]) { $data.Count } else { 1 }
    Write-Output "✅ Records Found: $count students"
    
    Write-Output ""
    Write-Output "Sample API Response:"
    Write-Output ($response.Content | ConvertFrom-Json | Select-Object -First 1 | ConvertTo-Json -Depth 2)
} catch {
    Write-Output "❌ API Test Failed: $($_.Exception.Message)"
}

Write-Output ""
Write-Output "🎭 DEMONSTRATION SCRIPT READY!"
Write-Output ""
Write-Output "Follow the steps above to show your mentor"
Write-Output "how your frontend beautifully integrates"
Write-Output "with your backend API! 🚀"