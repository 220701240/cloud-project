# Monitoring & Observability

This document explains how to enable Application Insights for the backend and where to view metrics/alerts.

Steps to enable:

1. Create an Application Insights resource in Azure.
2. Set the `APPINSIGHTS_INSTRUMENTATIONKEY` (or `APPLICATIONINSIGHTS_CONNECTION_STRING`) as an environment variable for the Container App.
3. The backend has lightweight instrumentation added in `internship-api/index.js`.

Azure CLI (optional) to set env var on Container App:

```
az containerapp update \
	--name internship-api \
	--resource-group placement-tracker-rg \
	--set-env-vars APPINSIGHTS_INSTRUMENTATIONKEY=<your-key>
```

Key metrics to monitor (suggested):

- Request rate (requests / minute)
- Server errors (5xx count)
- CPU % (if available from Container Apps)

Create an alert rule example:

- Metric: Server errors (>= 5 within 5 minutes)
- Action: Send email to devops@example.com

Demo artifacts:

- Take screenshots of Application Insights Overview, Metrics explorer, and the configured alert rule and add them here.

Notes:
- If using the connection string instead, set `APPLICATIONINSIGHTS_CONNECTION_STRING` and adjust initialization accordingly.

Generating traffic (optional but recommended):

- Use the provided PowerShell script to create requests so telemetry shows up quickly:

```powershell
# Example (Windows PowerShell)
Set-Location d:\coud
./scripts/smoke-test.ps1 -ApiBaseUrl "https://<your-container-app>.azurecontainerapps.io" -Count 10
```

Verification checklist:

- App Insights → Live Metrics shows requests arriving
- Metrics: Requests (count), Failed requests, CPU % (Container Apps)
- Failures: Exceptions/failed dependencies visible
- One alert rule created (e.g., server exceptions >= 5 in 5 minutes) and active

Create an alert rule (scripted):

You can create a metrics alert for failed requests using the provided script (requires Azure CLI logged in and correct subscription selected):

```powershell
Set-Location d:\coud
./scripts/create-appinsights-alert.ps1 `
	-ResourceGroup "placement-tracker-rg" `
	-AppInsightsName "internship-api-ai" `
	-Email "you@example.com" `
	-AlertName "AppInsights-FailedRequests-High" `
	-Threshold 5 `
	-Window "PT5M" `
	-Frequency "PT1M"
```

If your environment uses a different metric name for failed requests, adjust the script's `--condition` accordingly.
