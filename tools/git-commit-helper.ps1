<#
git-commit-helper.ps1

Safe helper to stage, commit and push changes from Windows PowerShell.

Usage:
  .\tools\git-commit-helper.ps1 -Message "Your commit message"

This script will:
- verify git is available and we're in a git repo
- check user.name and user.email are configured
- stage all changes, create a commit with the provided message
- push to the current branch

It does NOT auto-bypass hooks or branch protection. If push fails, it prints the error and exits.
#>

param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$Message
)

function Write-ErrAndExit([string]$msg, [int]$code=1) {
    Write-Error $msg
    exit $code
}

# Check git available
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-ErrAndExit "git not found in PATH. Install Git for Windows: https://git-scm.com/download/win"
}

# Verify inside a git repo
$isGit = git rev-parse --is-inside-work-tree 2>$null
if ($LASTEXITCODE -ne 0 -or $isGit -ne 'true') {
    Write-ErrAndExit "Not inside a git repository. Run this script from your repo root."
}

# Check user config
$userName = git config user.name
$userEmail = git config user.email
if ([string]::IsNullOrWhiteSpace($userName) -or [string]::IsNullOrWhiteSpace($userEmail)) {
    Write-Host "git user.name or user.email is not set. Configure them globally and re-run:" -ForegroundColor Yellow
    Write-Host "  git config --global user.name \"Your Name\"" -ForegroundColor Cyan
    Write-Host "  git config --global user.email \"you@example.com\"" -ForegroundColor Cyan
    Write-ErrAndExit "Missing git identity configuration."
}

Write-Host "Git user: $userName <$userEmail>"

# Show status
Write-Host "Checking working tree..."
$status = git status --porcelain
if ([string]::IsNullOrWhiteSpace($status)) {
    Write-Host "No changes to commit." -ForegroundColor Green
    exit 0
}

Write-Host "Staging all changes..."
git add -A
if ($LASTEXITCODE -ne 0) { Write-ErrAndExit "Failed to stage changes." }

Write-Host "Committing with message: $Message"
git commit -m $Message
if ($LASTEXITCODE -ne 0) { Write-ErrAndExit "git commit failed. If pre-commit hooks are installed, fix their issues or run 'git commit --no-verify' (not recommended)." }

# Determine current branch
$branch = git branch --show-current
if ([string]::IsNullOrWhiteSpace($branch)) { $branch = 'HEAD' }
Write-Host "Pushing to origin/$branch..."
git push origin $branch
if ($LASTEXITCODE -ne 0) {
    Write-ErrAndExit "git push failed. Common causes: authentication, branch protection, or remote is ahead. See COMMIT_GUIDE.md for fixes." 
}

Write-Host "Push succeeded to origin/$branch" -ForegroundColor Green
