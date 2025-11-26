# git-rebase-and-push.ps1
# Safe script to stage only intended files, commit, rebase onto origin/main, and push.
# Edit variables below if needed, then run from D:\coud in PowerShell:
#   D:\coud\git-rebase-and-push.ps1

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "Starting git rebase+push helper (will not add node_modules)..."

# Files we intend to stage and commit (relative to repo root)
$filesToAdd = @(
  'internship-api/package.json',
  'internship-api/package-lock.json',
  'internship-api/Dockerfile',
  'internship-api/index.js',
  'rebuild-and-deploy.ps1'
)

# 1) Ensure we're in the repo root
Push-Location
if (-not (Test-Path -Path .git)) {
  Write-Error "This script must be run from the repository root (where .git is located)."
  Pop-Location; exit 1
}

# 2) Untrack common large folders that should not be in git (only from index)
Write-Output "Removing tracked node_modules and terraform state from index if present..."
git rm -r --cached internship-api/node_modules 2>$null || Write-Output "no tracked internship-api/node_modules"
git rm --cached infra/terraform.tfstate 2>$null || Write-Output "no tracked infra/terraform.tfstate"
git rm --cached infra/terraform.tfstate.backup 2>$null || Write-Output "no tracked infra/terraform.tfstate.backup"
git rm -r --cached infra/.terraform 2>$null || Write-Output "no tracked infra/.terraform"

# 3) Stage only the intended files
Write-Output "Staging intended files..."
foreach ($f in $filesToAdd) {
  if (Test-Path $f) {
    git add $f
    Write-Output "Staged: $f"
  } else {
    Write-Output "Warning: file not found, skipping: $f"
  }
}

# 4) Check what's staged
Write-Output "Staged changes:"; git diff --cached --name-only

# 5) Commit staged changes (if any)
try {
  git commit -m "chore: add helmet, update lockfile, include frontend serving changes"
  Write-Output "Committed staged changes."
} catch {
  Write-Output "No staged changes to commit or commit failed: $_"
}

# 6) Fetch and rebase onto remote main
Write-Output "Fetching origin and rebasing onto origin/main..."
git fetch origin
try {
  git rebase origin/main
  Write-Output "Rebase completed successfully."
} catch {
  Write-Error "Rebase encountered conflicts. Resolve conflicts, then run: git add <file>; git rebase --continue. To abort: git rebase --abort"
  Pop-Location; exit 1
}

# 7) Push with force-with-lease to safely update remote
Write-Output "Pushing branch to origin (force-with-lease)..."
try {
  git push --force-with-lease origin main
  Write-Output "Push successful."
} catch {
  Write-Error "Push failed: $_"
  Pop-Location; exit 1
}

Pop-Location
Write-Output "Done. If you see merge conflicts, paste their output here and I'll help resolve them."