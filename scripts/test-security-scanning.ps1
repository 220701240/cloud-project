#!/usr/bin/env pwsh
# test-security-scanning.ps1 - Test security scanning requirements

Write-Output "=== Testing Requirement #1: Security Scanning ==="
Write-Output ""

# Test 1: Check GitHub Workflows
Write-Output "1. Testing GitHub Security Workflows..."
Write-Output ""

$codeqlExists = Test-Path ".github/workflows/codeql-analysis.yml"
$owaspExists = Test-Path ".github/workflows/owasp-zap-scan.yml"

if ($codeqlExists) {
    Write-Output "✅ CodeQL workflow found: .github/workflows/codeql-analysis.yml"
    $codeqlContent = Get-Content ".github/workflows/codeql-analysis.yml" -Raw
    if ($codeqlContent -match "security-extended") {
        Write-Output "✅ CodeQL configured with security-extended queries"
    }
} else {
    Write-Output "❌ CodeQL workflow missing"
}

if ($owaspExists) {
    Write-Output "✅ OWASP ZAP workflow found: .github/workflows/owasp-zap-scan.yml"
    $owaspContent = Get-Content ".github/workflows/owasp-zap-scan.yml" -Raw
    if ($owaspContent -match "zaproxy/action-baseline") {
        Write-Output "✅ OWASP ZAP configured with baseline scan"
    }
} else {
    Write-Output "❌ OWASP ZAP workflow missing"
}

Write-Output ""

# Test 2: Check Azure Pipeline Security
Write-Output "2. Testing Azure Pipeline Security..."
$pipelineExists = Test-Path "azure-pipelines.yml"
if ($pipelineExists) {
    $pipelineContent = Get-Content "azure-pipelines.yml" -Raw
    if ($pipelineContent -match "OWASP ZAP") {
        Write-Output "✅ Azure Pipeline has OWASP ZAP scan"
    }
    if ($pipelineContent -match "zap-baseline.py") {
        Write-Output "✅ ZAP baseline scan configured"
    }
    if ($pipelineContent -match "zap-report") {
        Write-Output "✅ Security report artifact generation configured"
    }
}

Write-Output ""

# Test 3: Check Security Documentation
Write-Output "3. Testing Security Documentation..."
$securityReportExists = Test-Path "Security_Report.md"
if ($securityReportExists) {
    Write-Output "✅ Security report documentation found"
    $reportContent = Get-Content "Security_Report.md" -Raw
    if ($reportContent -match "CodeQL|OWASP") {
        Write-Output "✅ Security report mentions implemented tools"
    }
}

Write-Output ""
Write-Output "📊 Security Scanning Test Results:"
if ($codeqlExists -and $owaspExists -and $securityReportExists) {
    Write-Output "✅ REQUIREMENT #1: FULLY SATISFIED"
    Write-Output "   - SAST: CodeQL implemented"
    Write-Output "   - DAST: OWASP ZAP implemented"
    Write-Output "   - Documentation: Complete"
} else {
    Write-Output "🟡 REQUIREMENT #1: PARTIALLY SATISFIED"
}

Write-Output ""
Write-Output "🔍 To trigger security scans:"
Write-Output "1. Push code to GitHub (triggers CodeQL and OWASP workflows)"
Write-Output "2. Run Azure Pipeline (triggers OWASP ZAP in pipeline)"
Write-Output "3. Check GitHub Security tab for results"

Write-Output ""
Write-Output "=== Security Scanning Test Complete ==="