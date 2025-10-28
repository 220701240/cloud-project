param(
  [Parameter(Mandatory=$true)][string]$ResourceGroup,
  [Parameter(Mandatory=$true)][string]$AppInsightsName,
  [Parameter(Mandatory=$true)][string]$Email,
  [string]$ActionGroupName = "appinsights-alert-ag",
  [string]$AlertName = "AppInsights-FailedRequests-High",
  [int]$Threshold = 5,
  [string]$Window = "PT5M",
  [string]$Frequency = "PT1M"
)

Write-Host "Creating/using action group '$ActionGroupName' for email '$Email'..."
$ag = az monitor action-group show -g $ResourceGroup -n $ActionGroupName --query id -o tsv 2>$null
if (-not $ag) {
  $agCreate = az monitor action-group create -g $ResourceGroup -n $ActionGroupName `
    --short-name ag `
    --action email DevEmail $Email | Out-String
}
$agId = az monitor action-group show -g $ResourceGroup -n $ActionGroupName --query id -o tsv

Write-Host "Resolving Application Insights resource ID..."
$aiId = az resource show -g $ResourceGroup -n $AppInsightsName --resource-type "microsoft.insights/components" --query id -o tsv
if (-not $aiId) {
  Write-Error "Could not find Application Insights resource '$AppInsightsName' in RG '$ResourceGroup'"
  exit 1
}

Write-Host "Creating metrics alert '$AlertName' on failed requests (> $Threshold over $Window)"
# Note: 'requests/failed' is a standard metric for App Insights components.
# If your environment uses different metric naming, adjust accordingly.
az monitor metrics alert create `
  --name $AlertName `
  --resource-group $ResourceGroup `
  --scopes $aiId `
  --condition "total requests/failed > $Threshold" `
  --window-size $Window `
  --evaluation-frequency $Frequency `
  --action $agId | Out-Null

Write-Host "Alert created. You will receive emails at $Email when the threshold is breached."
