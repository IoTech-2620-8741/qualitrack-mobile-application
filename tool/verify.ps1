# QualiTrack Mobile - verification script (Windows PowerShell)
# Usage (from the project root):  powershell -ExecutionPolicy Bypass -File tool\verify.ps1
# Writes all output to tool\logs\verify.log so the results can be reviewed.
$ErrorActionPreference = 'Continue'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
$logDir = Join-Path $PSScriptRoot 'logs'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$log = Join-Path $logDir 'verify.log'
"# verify started $(Get-Date -Format o)" | Out-File -Encoding utf8 $log

function Step($title, [scriptblock]$block) {
    "`n===== $title =====" | Tee-Object -FilePath $log -Append
    & $block 2>&1 | ForEach-Object { "$_" } | Tee-Object -FilePath $log -Append
    "exit=$LASTEXITCODE" | Tee-Object -FilePath $log -Append
}

Step 'where flutter' { where.exe flutter }
Step 'flutter --version' { flutter --version }
Step 'dart --version' { dart --version }
if (-not (Test-Path (Join-Path $root 'android'))) {
    Step 'flutter create (platform folders only, existing files kept)' {
        flutter create --org com.iotech --project-name qualitrack_mobile --platforms android,ios .
    }
}
Step 'flutter pub get' { flutter pub get }
Step 'dart format .' { dart format . }
Step 'flutter analyze' { flutter analyze }
Step 'flutter test' { flutter test }
"`n# verify finished $(Get-Date -Format o)" | Tee-Object -FilePath $log -Append
