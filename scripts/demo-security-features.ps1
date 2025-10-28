#!/usr/bin/env pwsh
# demo-security-features.ps1 - Demonstrate security scanning features

Write-Output "🔒 SECURITY SCANNING DEMONSTRATION"
Write-Output "═══════════════════════════════════════"
Write-Output ""

# 1. Show GitHub Security Workflows
Write-Output "1. 📁 GitHub Security Workflows"
Write-Output ""

if (Test-Path ".github/workflows/codeql-analysis.yml") {
    Write-Output "✅ CodeQL Analysis Workflow:"
    Write-Output "   📍 Location: .github/workflows/codeql-analysis.yml"
    $codeqlContent = Get-Content ".github/workflows/codeql-analysis.yml" | Select-Object -First 15
    Write-Output "   📝 Configuration Preview:"
    $codeqlContent | ForEach-Object { Write-Output "      $_" }
    Write-Output "   ⚡ Triggers: Push to main, PR, Weekly schedule"
    Write-Output "   🔍 Languages: JavaScript"
    Write-Output "   📊 Query Sets: security-extended, security-and-quality"
}

Write-Output ""

if (Test-Path ".github/workflows/owasp-zap-scan.yml") {
    Write-Output "✅ OWASP ZAP Security Scan Workflow:"
    Write-Output "   📍 Location: .github/workflows/owasp-zap-scan.yml"
    Write-Output "   ⚡ Triggers: Push to main, PR, Manual trigger"
    Write-Output "   🎯 Target: Frontend application on localhost:8080"
    Write-Output "   📊 Report: Automatically uploaded as artifact"
}

Write-Output ""
Write-Output "───────────────────────────────────────────────────"
Write-Output ""

# 2. Show Azure Pipeline Security
Write-Output "2. 🏗️ Azure Pipeline Security Integration"
Write-Output ""

$pipelineContent = Get-Content "azure-pipelines.yml" -Raw
if ($pipelineContent -match "OWASP ZAP") {
    Write-Output "✅ OWASP ZAP Baseline Scan in Pipeline:"
    Write-Output "   📍 Location: azure-pipelines.yml"
    Write-Output "   🎯 Target: Frontend on http://localhost:8000"
    Write-Output "   🐳 Container: ghcr.io/zaproxy/zaproxy:stable"
    Write-Output "   📊 Report: zap-report.html (published as artifact)"
    Write-Output "   ⚙️  Mode: Baseline scan with 5-minute timeout"
}

Write-Output ""
Write-Output "───────────────────────────────────────────────────"
Write-Output ""

# 3. Show Security Documentation
Write-Output "3. 📚 Security Documentation & Reports"
Write-Output ""

if (Test-Path "Security_Report.md") {
    Write-Output "✅ Security Report:"
    Write-Output "   📍 Location: Security_Report.md"
    $reportContent = Get-Content "Security_Report.md" | Select-Object -First 10
    Write-Output "   📝 Content Preview:"
    $reportContent | ForEach-Object { Write-Output "      $_" }
}

Write-Output ""
Write-Output "═══════════════════════════════════════════════════"
Write-Output ""

# 4. How to Trigger Scans
Write-Output "🚀 HOW TO TRIGGER SECURITY SCANS:"
Write-Output ""
Write-Output "Method 1 - GitHub (Automatic):"
Write-Output "   1. Push code to main branch"
Write-Output "   2. Create pull request"
Write-Output "   3. View results in GitHub Security tab"
Write-Output ""
Write-Output "Method 2 - Azure Pipeline:"
Write-Output "   1. Run the pipeline manually or via trigger"
Write-Output "   2. Download zap-report artifact"
Write-Output "   3. Review security findings"
Write-Output ""
Write-Output "Method 3 - Manual GitHub Trigger:"
Write-Output "   1. Go to GitHub Actions tab"
Write-Output "   2. Select 'OWASP ZAP Security Scan'"
Write-Output "   3. Click 'Run workflow'"

Write-Output ""
Write-Output "🔍 VIEW RESULTS:"
Write-Output "• GitHub Security Tab: https://github.com/220701240/cloud-project/security"
Write-Output "• GitHub Actions: https://github.com/220701240/cloud-project/actions"
Write-Output "• Azure DevOps Artifacts: In pipeline run results"

Write-Output ""
Write-Output "✅ SECURITY DEMONSTRATION COMPLETE!"