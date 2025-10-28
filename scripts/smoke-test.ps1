param(
  [Parameter(Mandatory=$true)][string]$ApiBaseUrl,
  [int]$Count = 10
)

Write-Host "Hitting API base: $ApiBaseUrl ($Count requests each)"

function Invoke-Endpoint($path) {
  $url = "$ApiBaseUrl$path"
  try {
    $res = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 10
    Write-Host "OK $($res.StatusCode) $path"
  } catch {
    Write-Warning "ERR $path : $($_.Exception.Message)"
  }
}

1..$Count | ForEach-Object {
  Invoke-Endpoint '/api/companies'
}

1..$Count | ForEach-Object {
  Invoke-Endpoint '/api/analytics/placement'
}

Write-Host "Done. Check Application Insights for requests and failures."
