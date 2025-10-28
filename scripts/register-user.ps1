param(
  [Parameter(Mandatory=$true)][string]$ApiBaseUrl,
  [Parameter(Mandatory=$true)][string]$Username,
  [Parameter(Mandatory=$true)][string]$Password,
  [Parameter(Mandatory=$true)][string]$FullName,
  [Parameter(Mandatory=$true)][ValidateSet('Admin','Faculty','Student')][string]$Role,
  [Parameter(Mandatory=$true)][string]$Email
)

$body = @{ username=$Username; password=$Password; fullName=$FullName; role=$Role; email=$Email } | ConvertTo-Json

try {
  $resp = Invoke-RestMethod -Uri ("$ApiBaseUrl/api/register") -Method Post -ContentType 'application/json' -Body $body -TimeoutSec 60
  Write-Host "Registered user '$Username' as $Role" -ForegroundColor Green
  $resp | ConvertTo-Json -Depth 6
} catch {
  Write-Error $_.Exception.Message
  if ($_.ErrorDetails) { Write-Error $_.ErrorDetails }
  exit 1
}
