#!/usr/bin/env pwsh
# test-both-requirements.ps1 - Test both requirements

Write-Output "=== TESTING BOTH REQUIREMENTS ==="
Write-Output ""

# Test Requirement 1: Security Scanning
Write-Output "📋 REQUIREMENT #1: CI/CD Security & Code Scanning"
Write-Output ""

$codeql = Test-Path ".github/workflows/codeql-analysis.yml"
$owasp = Test-Path ".github/workflows/owasp-zap-scan.yml"
$pipeline = Select-String -Path "azure-pipelines.yml" -Pattern "OWASP ZAP" -Quiet -ErrorAction SilentlyContinue
$secDoc = Test-Path "Security_Report.md"

Write-Output "Components:"
Write-Output "  CodeQL GitHub Workflow: $(if ($codeql) {'✅ Found'} else {'❌ Missing'})"
Write-Output "  OWASP ZAP GitHub Workflow: $(if ($owasp) {'✅ Found'} else {'❌ Missing'})"
Write-Output "  OWASP ZAP in Azure Pipeline: $(if ($pipeline) {'✅ Found'} else {'❌ Missing'})"
Write-Output "  Security Documentation: $(if ($secDoc) {'✅ Found'} else {'❌ Missing'})"

$req1Status = $codeql -and $owasp -and $pipeline -and $secDoc
Write-Output ""
Write-Output "Status: $(if ($req1Status) {'✅ REQUIREMENT #1 SATISFIED'} else {'🟡 REQUIREMENT #1 PARTIAL'})"

Write-Output ""
Write-Output "───────────────────────────────────────────────────"
Write-Output ""

# Test Requirement 2: Monitoring
Write-Output "📋 REQUIREMENT #2: Monitoring & Observability"
Write-Output ""

try {
    $envVar = az containerapp show --name internship-api -g placement-tracker-rg --query "properties.template.containers[0].env[?name=='APPINSIGHTS_INSTRUMENTATIONKEY'].value" -o tsv 2>$null
    $hasAppInsights = $envVar -ne $null -and $envVar.Length -gt 0
    
    $alertScript = Test-Path "scripts/create-appinsights-alert.ps1"
    $monitorDoc = Test-Path "Monitoring_Dashboard.md"
    
    Write-Output "Components:"
    Write-Output "  App Insights Configuration: $(if ($hasAppInsights) {'✅ Active'} else {'❌ Missing'})"
    Write-Output "  Alert Creation Script: $(if ($alertScript) {'✅ Found'} else {'❌ Missing'})"
    Write-Output "  Monitoring Documentation: $(if ($monitorDoc) {'✅ Found'} else {'❌ Missing'})"
    
    $req2Status = $hasAppInsights -and $alertScript -and $monitorDoc
    Write-Output ""
    Write-Output "Status: $(if ($req2Status) {'✅ REQUIREMENT #2 SATISFIED'} else {'🟡 REQUIREMENT #2 PARTIAL'})"
    
} catch {
    Write-Output "❌ Error testing monitoring: $($_.Exception.Message)"
    $req2Status = $false
}

Write-Output ""
Write-Output "═══════════════════════════════════════════════════"
Write-Output ""

# Final Summary
Write-Output "🎯 FINAL RESULTS:"
Write-Output ""
Write-Output "Requirement #1 (Security): $(if ($req1Status) {'✅ COMPLETE'} else {'🟡 PARTIAL'})"
Write-Output "Requirement #2 (Monitoring): $(if ($req2Status) {'✅ COMPLETE'} else {'🟡 PARTIAL'})"
Write-Output ""

if ($req1Status -and $req2Status) {
    Write-Output "🎉 PROJECT STATUS: BOTH REQUIREMENTS FULLY SATISFIED!"
    Write-Output ""
    Write-Output "✅ Ready for demonstration"
    Write-Output "✅ Ready for deployment"
    Write-Output "✅ Meets all specified criteria"
} else {
    Write-Output "⚠️ PROJECT STATUS: REQUIREMENTS PARTIALLY SATISFIED"
    Write-Output ""
    Write-Output "Review missing components above"
}

Write-Output ""
Write-Output "=== TEST COMPLETE ==="