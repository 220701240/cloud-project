param(
  [Parameter(Mandatory=$true)][string]$ApiBaseUrl,
  [string]$Path = "/api/me",
  [string]$Token = "",
  [string]$TokenFile = "",
  [ValidateSet('GET','POST','PUT','PATCH','DELETE')][string]$Method = 'GET',
  [string]$BodyJson = ""
)

if (-not $Token) {
  if ($env:JWT_TOKEN) { $Token = $env:JWT_TOKEN }
}
if (-not $Token -and $TokenFile -and (Test-Path $TokenFile)) {
  $Token = Get-Content -Path $TokenFile -Raw
}
if (-not $Token) {
  Write-Error "No JWT token provided. Pass -Token, set $env:JWT_TOKEN, or provide -TokenFile."
  exit 1
}

$uri = "$ApiBaseUrl$Path"
$headers = @{ Authorization = "Bearer $Token" }

try {
  if ($BodyJson -and ($Method -in 'POST','PUT','PATCH')) {
    $res = Invoke-RestMethod -Uri $uri -Headers $headers -Method $Method -ContentType 'application/json' -Body $BodyJson -TimeoutSec 60
  } else {
    $res = Invoke-RestMethod -Uri $uri -Headers $headers -Method $Method -TimeoutSec 60
  }
  Write-Host "Status: OK" -ForegroundColor Green
  $res | ConvertTo-Json -Depth 8
} catch {
  Write-Host "Status: ERROR" -ForegroundColor Red
  if ($_.Exception.Response -and $_.Exception.Response.StatusCode) {
    Write-Host ("HTTP {0}" -f [int]$_.Exception.Response.StatusCode)
  }
  Write-Error $_.Exception.Message
  if ($_.ErrorDetails) { Write-Error $_.ErrorDetails }
  exit 1
}
