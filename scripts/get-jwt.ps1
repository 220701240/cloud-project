param(
  [Parameter(Mandatory=$true)][string]$ApiBaseUrl,
  [Parameter(Mandatory=$true)][string]$Username,
  [Parameter(Mandatory=$true)][string]$Password,
  [string]$OutFile = ""
)

try {
  $body = @{ username = $Username; password = $Password } | ConvertTo-Json
  $resp = Invoke-RestMethod -Uri ("$ApiBaseUrl/api/login") -Method Post -ContentType 'application/json' -Body $body -TimeoutSec 30
  if (-not $resp.token) { throw "Login response did not contain a token. Response: $($resp | ConvertTo-Json -Depth 5)" }

  $token = $resp.token
  Write-Output "JWT token:" 
  Write-Output $token

  if ($OutFile -and $OutFile.Trim().Length -gt 0) {
    $dir = Split-Path -Parent $OutFile
    if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
    Set-Content -Path $OutFile -Value $token -Encoding ASCII
    Write-Host "Saved token to $OutFile"
  }

  # Convenience: set an env var for this session
  $env:JWT_TOKEN = $token
  Write-Host "JWT_TOKEN environment variable set for this session."
}
catch {
  Write-Error $_.Exception.Message
  if ($_.ErrorDetails) { Write-Error $_.ErrorDetails }
  exit 1
}
