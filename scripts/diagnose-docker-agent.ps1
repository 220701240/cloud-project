#!/usr/bin/env pwsh
# diagnose-docker-agent.ps1 - Diagnose Docker issues on Azure DevOps agent

Write-Output "=== Docker Agent Diagnostics ==="
Write-Output ""

# Check if Docker is installed
Write-Output "1. Checking Docker installation..."
try {
    $dockerVersion = docker --version
    Write-Output "✅ Docker installed: $dockerVersion"
} catch {
    Write-Output "❌ Docker not found or not accessible"
    Write-Output "   Install Docker Desktop or Docker CE"
    exit 1
}

Write-Output ""

# Check Docker daemon status
Write-Output "2. Checking Docker daemon..."
try {
    $dockerInfo = docker info --format "{{.ServerVersion}}"
    Write-Output "✅ Docker daemon running: Server version $dockerInfo"
} catch {
    Write-Output "❌ Docker daemon not accessible: $($_.Exception.Message)"
    Write-Output "   Try: Start Docker Desktop or restart Docker service"
}

Write-Output ""

# Check Docker connectivity
Write-Output "3. Testing Docker connectivity..."
try {
    docker ps | Out-Null
    Write-Output "✅ Docker connectivity working"
} catch {
    Write-Output "❌ Docker connectivity failed: $($_.Exception.Message)"
}

Write-Output ""

# Check running containers
Write-Output "4. Current Docker containers..."
try {
    docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Image}}"
} catch {
    Write-Output "❌ Cannot list containers"
}

Write-Output ""

# Check Docker disk space
Write-Output "5. Docker system info..."
try {
    docker system df
} catch {
    Write-Output "❌ Cannot get Docker system info"
}

Write-Output ""

# Check Windows services (if Windows)
if ($IsWindows -or $env:OS -eq "Windows_NT") {
    Write-Output "6. Checking Windows Docker services..."
    try {
        $services = Get-Service | Where-Object { $_.Name -like "*docker*" }
        foreach ($service in $services) {
            Write-Output "   $($service.Name): $($service.Status)"
        }
    } catch {
        Write-Output "❌ Cannot check Windows services"
    }
}

Write-Output ""
Write-Output "=== Diagnosis Complete ==="
Write-Output ""
Write-Output "Common Solutions:"
Write-Output "1. Restart Docker Desktop"
Write-Output "2. Restart Docker service: Restart-Service docker"
Write-Output "3. Check if Windows containers/Linux containers are properly configured"
Write-Output "4. Ensure agent user has Docker permissions"
Write-Output "5. Clean Docker cache: docker system prune -f"