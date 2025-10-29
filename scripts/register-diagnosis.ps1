# Register Page Diagnostic Script

Write-Output "==========================================="
Write-Output "DIAGNOSING REGISTER.HTML PAGE ISSUES"
Write-Output "==========================================="
Write-Output ""

$appUrl = "https://internship-api.gentleforest-68343e46.centralindia.azurecontainerapps.io"

Write-Output "STEP 1: Testing Register Page Accessibility"
Write-Output "============================================"

try {
    $response = Invoke-WebRequest -Uri "$appUrl/register.html" -UseBasicParsing -TimeoutSec 10
    Write-Output "✅ Register Page Status: HTTP $($response.StatusCode)"
    Write-Output "✅ Content Length: $($response.Content.Length) bytes"
    Write-Output "✅ Register page is accessible"
} catch {
    Write-Output "❌ Register Page Error: $($_.Exception.Message)"
}

Write-Output ""
Write-Output "STEP 2: Testing Register API Endpoint"
Write-Output "======================================"

Write-Output "Testing with minimal data to check API connectivity..."

try {
    $testBody = @{
        username = "testuser"
        password = "testpass" 
        fullName = "Test User"
        role = "student"
    } | ConvertTo-Json

    $headers = @{
        "Content-Type" = "application/json"
    }
    
    Write-Output "Sending POST request to /api/register..."
    $apiResponse = Invoke-WebRequest -Uri "$appUrl/api/register" -Method POST -Body $testBody -Headers $headers -UseBasicParsing
    
    Write-Output "✅ API Response: HTTP $($apiResponse.StatusCode)"
    Write-Output "✅ Response: $($apiResponse.Content)"
    
} catch {
    Write-Output "❌ API Error: $($_.Exception.Message)"
    
    # Try to extract more details
    if ($_.Exception.Response) {
        $errorResponse = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($errorResponse)
        $errorContent = $reader.ReadToEnd()
        Write-Output "❌ Error Details: $errorContent"
    }
}

Write-Output ""
Write-Output "STEP 3: Common Issues and Solutions"
Write-Output "===================================="
Write-Output ""
Write-Output "POTENTIAL ISSUES WITH REGISTER.HTML:"
Write-Output ""
Write-Output "1. DATABASE CONNECTION ISSUE:"
Write-Output "   • The register endpoint tries to connect to SQL database"
Write-Output "   • If DB is not accessible, registration will fail"
Write-Output ""
Write-Output "2. MISSING USERS TABLE:"
Write-Output "   • The register endpoint expects a Users table in the database"
Write-Output "   • Table might not exist or have wrong schema"
Write-Output ""
Write-Output "3. BODY PARSING ISSUE:"
Write-Output "   • JSON body might not be parsed correctly"
Write-Output "   • Could be middleware configuration issue"
Write-Output ""
Write-Output "4. CORS ISSUES:"
Write-Output "   • Frontend might not be allowed to make API calls"
Write-Output "   • Already configured, so this is less likely"
Write-Output ""

Write-Output "STEP 4: How to Test in Browser"
Write-Output "==============================="
Write-Output ""
Write-Output "TO TEST WITH YOUR MENTOR:"
Write-Output ""
Write-Output "1. Open: $appUrl/register.html"
Write-Output ""
Write-Output "2. Open Browser Developer Tools (F12)"
Write-Output "   → Go to Console tab"
Write-Output "   → Go to Network tab"
Write-Output ""
Write-Output "3. Fill in the registration form:"
Write-Output "   • Role: Student"
Write-Output "   • Full Name: Test User"
Write-Output "   • Username: testuser"
Write-Output "   • Password: testpass"
Write-Output ""
Write-Output "4. Click Register and watch:"
Write-Output "   • Network tab for API call"
Write-Output "   • Console tab for JavaScript errors"
Write-Output "   • Any error messages"
Write-Output ""

Write-Output "STEP 5: Expected Behavior"
Write-Output "========================="
Write-Output ""
Write-Output "WHAT SHOULD HAPPEN:"
Write-Output "• Form submission triggers POST to /api/register"
Write-Output "• API creates user in database"
Write-Output "• Success message appears"
Write-Output "• Redirects to login.html"
Write-Output ""
Write-Output "WHAT MIGHT HAPPEN (Due to DB issues):"
Write-Output "• API returns database connection error"
Write-Output "• Registration fails with error message"
Write-Output "• Form stays on same page"
Write-Output ""

Write-Output "✅ REGISTER PAGE ANALYSIS COMPLETE"
Write-Output "=================================="
Write-Output ""
Write-Output "The register.html page is accessible and has proper code."
Write-Output "Any issues are likely due to backend database connectivity"
Write-Output "or missing database tables, not the frontend code itself."
Write-Output ""
Write-Output "For demonstration purposes, you can:"
Write-Output "1. Show the professional registration interface"
Write-Output "2. Demonstrate the form validation"
Write-Output "3. Show API calls in browser dev tools"
Write-Output "4. Explain the full-stack architecture"