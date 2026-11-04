#Requires -Version 5.1
[CmdletBinding()]
param(
    [string]$InstallDir = (Join-Path $env:USERPROFILE 'qqbot-napcat'),
    [string]$Repository = 'cjz-wr/qqbot-napcat-docker-deploy',
    [string]$Ref = 'main',
    [switch]$Update,
    [switch]$NoOpen
)

$ErrorActionPreference = 'Stop'
if ($Repository -notmatch '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$' -or
    $Ref -notmatch '^[A-Za-z0-9][A-Za-z0-9._/-]*$' -or $Ref.Contains('..')) {
    throw 'Invalid repository or ref.'
}
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) { throw 'Install and start Docker Desktop first.' }
& docker compose version | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'Docker Compose V2 is required.' }
$dockerOs = & docker info --format '{{.OSType}}'
if ($LASTEXITCODE -ne 0 -or $dockerOs -ne 'linux') { throw 'Start Docker Desktop in Linux container mode.' }

[void](New-Item -ItemType Directory -Force -Path $InstallDir)
$InstallDir = (Resolve-Path -LiteralPath $InstallDir).Path
$stagePath = Join-Path $InstallDir ('.qqbot-install.' + [guid]::NewGuid().ToString('N'))
[void](New-Item -ItemType Directory -Path $stagePath)
$files = @('docker-compose.yml', '.env.example', 'scripts/install.sh', 'scripts/install.ps1', 'README.md', 'LICENSE')

try {
    $localSource = $null
    if (-not $Update -and $PSScriptRoot) {
        $candidate = Split-Path -Parent $PSScriptRoot
        if ((Test-Path -LiteralPath (Join-Path $candidate 'docker-compose.yml')) -and
            (Test-Path -LiteralPath (Join-Path $candidate '.env.example'))) {
            $localSource = $candidate
        }
    }
    foreach ($file in $files) {
        $destination = Join-Path $stagePath $file
        [void](New-Item -ItemType Directory -Force -Path (Split-Path -Parent $destination))
        if ($localSource) {
            Copy-Item -LiteralPath (Join-Path $localSource $file) -Destination $destination
        } else {
            Invoke-WebRequest -UseBasicParsing -TimeoutSec 180 `
                -Uri "https://raw.githubusercontent.com/$Repository/$Ref/$file" -OutFile $destination
        }
    }

    $composePath = Join-Path $InstallDir 'docker-compose.yml'
    if (Test-Path -LiteralPath $composePath) {
        if ($Update) {
            $backupDir = Join-Path $InstallDir '.backups'
            [void](New-Item -ItemType Directory -Force -Path $backupDir)
            $backupName = 'docker-compose.' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.' + [guid]::NewGuid().ToString('N') + '.yml'
            Copy-Item -LiteralPath $composePath -Destination (Join-Path $backupDir $backupName)
        } else {
            Write-Host 'Keeping existing docker-compose.yml (use -Update to replace it).'
            Remove-Item -LiteralPath (Join-Path $stagePath 'docker-compose.yml')
        }
    }
    foreach ($file in $files) {
        $source = Join-Path $stagePath $file
        if (Test-Path -LiteralPath $source) {
            $destination = Join-Path $InstallDir $file
            [void](New-Item -ItemType Directory -Force -Path (Split-Path -Parent $destination))
            Move-Item -LiteralPath $source -Destination $destination -Force
        }
    }
    $envPath = Join-Path $InstallDir '.env'
    if (-not (Test-Path -LiteralPath $envPath)) {
        Copy-Item -LiteralPath (Join-Path $InstallDir '.env.example') -Destination $envPath
    }
} finally {
    # Resolve and verify the generated staging directory before recursive cleanup.
    if (Test-Path -LiteralPath $stagePath) {
        $resolvedStage = [IO.Path]::GetFullPath($stagePath)
        $resolvedInstall = [IO.Path]::GetFullPath($InstallDir).TrimEnd('\') + '\'
        if (-not $resolvedStage.StartsWith($resolvedInstall, [StringComparison]::OrdinalIgnoreCase) -or
            -not ([IO.Path]::GetFileName($resolvedStage)).StartsWith('.qqbot-install.')) {
            throw 'Refusing to clean a staging directory outside the installation.'
        }
        Remove-Item -LiteralPath $resolvedStage -Recurse -Force
    }
}

$composeArgs = @('compose', '--project-directory', $InstallDir, '-f', (Join-Path $InstallDir 'docker-compose.yml'))
Write-Host "Pulling images and starting services in $InstallDir ..." -ForegroundColor Cyan
& docker @composeArgs pull
if ($LASTEXITCODE -ne 0) { throw 'Image download failed; services were not started.' }
& docker @composeArgs up -d
if ($LASTEXITCODE -ne 0) { throw 'Service startup failed. Inspect docker compose logs in the installation directory.' }

function Get-ServiceUrl([string]$Service, [int]$Port) {
    $endpoint = & docker @composeArgs port $Service $Port 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $endpoint) { return $null }
    $endpoint = ([string]$endpoint).Trim() -replace '^(0\.0\.0\.0|\[::\]):', '127.0.0.1:'
    return "http://$endpoint"
}
$botUrl = Get-ServiceUrl 'bot' 8881
$napcatUrl = Get-ServiceUrl 'napcat' 6099
Write-Host "Bot console: $botUrl"
Write-Host "NapCat login: $napcatUrl/webui"
Write-Host 'Login details may take a moment to appear; run docker compose logs bot napcat again if needed.'
& docker @composeArgs logs --no-color --tail=80 bot napcat |
    Select-String -Pattern 'WebUi Token:|WebUi User Panel Url:|Web 控制台初始口令:'
Write-Host "Manage this deployment from: $InstallDir"
if (-not $NoOpen -and $napcatUrl) { Start-Process -FilePath "$napcatUrl/webui" }
