$ErrorActionPreference = "SilentlyContinue"

Write-Host "Uninstalling MRP Stickers ..." -ForegroundColor Red

$RootDir = "C:\mrp_stickers"
$InstallDir = "C:\Program Files\MRP-Stickers"
$ServiceName = "PostgreSQL_MRP_Stickers"
$AppName = "MRP Stickers"

# ------------------------------------------------------------
# 1. Close running application processes
# ------------------------------------------------------------

Write-Host "Closing running applications..." -ForegroundColor Cyan

Get-Process -Name "mrp_stickers" -ErrorAction SilentlyContinue |
    Stop-Process -Force -ErrorAction SilentlyContinue

Get-Process -Name "php" -ErrorAction SilentlyContinue |
    Stop-Process -Force -ErrorAction SilentlyContinue


# ------------------------------------------------------------
# 2. Stop and remove PostgreSQL service
# ------------------------------------------------------------

Write-Host "Stopping and removing database service..." -ForegroundColor Cyan

$PgService = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue

if ($null -ne $PgService) {

    if ($PgService.Status -ne "Stopped") {

        Stop-Service `
            -Name $ServiceName `
            -Force `
            -ErrorAction SilentlyContinue

        try {
            $PgService.WaitForStatus(
                "Stopped",
                [TimeSpan]::FromSeconds(10)
            )
        }
        catch {
        }
    }

    sc.exe delete $ServiceName | Out-Null

    Write-Host "[OK] Database service removed." -ForegroundColor Green
}
else {
    Write-Host "[OK] Database service was not installed." -ForegroundColor DarkGray
}


# ------------------------------------------------------------
# 3. Remove PostgreSQL data
# ------------------------------------------------------------

Write-Host "Removing database data..." -ForegroundColor Cyan

$DataPath = Join-Path $RootDir "postgres-data"

if (Test-Path -LiteralPath $DataPath) {

    Remove-Item `
        -LiteralPath $DataPath `
        -Recurse `
        -Force `
        -ErrorAction SilentlyContinue

    Write-Host "[OK] Database data removed." -ForegroundColor Green
}
else {
    Write-Host "[OK] Database data was already removed." -ForegroundColor DarkGray
}


# ------------------------------------------------------------
# 4. Remove bundled dependencies and generated files
# ------------------------------------------------------------

Write-Host "Removing environment dependencies..." -ForegroundColor Cyan

$ItemsToDelete = @(
    "adminer",
    "php",
    "pgsql",
    "connection.txt",
    "postgres.log"
)

foreach ($Item in $ItemsToDelete) {

    $TargetPath = Join-Path $RootDir $Item

    if (Test-Path -LiteralPath $TargetPath) {

        Remove-Item `
            -LiteralPath $TargetPath `
            -Recurse `
            -Force `
            -ErrorAction SilentlyContinue

        Write-Host "[OK] Removed $Item." -ForegroundColor Green
    }
}


# ------------------------------------------------------------
# 5. Remove Windows uninstall registration
# ------------------------------------------------------------

Write-Host "Removing Windows registration..." -ForegroundColor Cyan

$RegistryKeyPath = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\MRP-Stickers"

if (Test-Path -LiteralPath $RegistryKeyPath) {

    Remove-Item `
        -LiteralPath $RegistryKeyPath `
        -Recurse `
        -Force `
        -ErrorAction SilentlyContinue

    Write-Host "[OK] Removed application from Windows Apps list." -ForegroundColor Green
}


# ------------------------------------------------------------
# 6. Remove shortcuts
# ------------------------------------------------------------

Write-Host "Removing shortcuts..." -ForegroundColor Cyan

$DesktopShortcut = Join-Path $env:PUBLIC "Desktop\$AppName.lnk"

$StartMenuShortcut = Join-Path `
    $env:PROGRAMDATA `
    "Microsoft\Windows\Start Menu\Programs\$AppName.lnk"

if (Test-Path -LiteralPath $DesktopShortcut) {

    Remove-Item `
        -LiteralPath $DesktopShortcut `
        -Force `
        -ErrorAction SilentlyContinue

    Write-Host "[OK] Desktop shortcut removed." -ForegroundColor Green
}

if (Test-Path -LiteralPath $StartMenuShortcut) {

    Remove-Item `
        -LiteralPath $StartMenuShortcut `
        -Force `
        -ErrorAction SilentlyContinue

    Write-Host "[OK] Start Menu shortcut removed." -ForegroundColor Green
}


# ------------------------------------------------------------
# 7. Remove installed application binaries
# ------------------------------------------------------------

Write-Host "Removing application files..." -ForegroundColor Cyan

Set-Location -Path "C:\"

if (Test-Path -LiteralPath $InstallDir) {

    Remove-Item `
        -LiteralPath $InstallDir `
        -Recurse `
        -Force `
        -ErrorAction SilentlyContinue

    Write-Host "[OK] Application binaries removed." -ForegroundColor Green
}
else {
    Write-Host "[OK] Application binaries were already removed." -ForegroundColor DarkGray
}


# ------------------------------------------------------------
# 8. Preserve C:\mrp_stickers and sizes.txt
# ------------------------------------------------------------

Write-Host "Preserving user configuration files..." -ForegroundColor Cyan

$SizesFile = Join-Path $RootDir "sizes.txt"

if (Test-Path -LiteralPath $SizesFile) {
    Write-Host "[OK] sizes.txt preserved." -ForegroundColor Green
}
else {
    Write-Host "[INFO] sizes.txt was not found." -ForegroundColor DarkGray
}


# ------------------------------------------------------------
# 9. Self-delete this uninstall script only
# ------------------------------------------------------------

Write-Host "Finishing uninstallation..." -ForegroundColor Cyan

$MyScriptPath = $MyInvocation.MyCommand.Path

Set-Location -Path "C:\"

Write-Host ""
Write-Host "MRP Stickers was uninstalled successfully." -ForegroundColor Green
Write-Host "C:\mrp_stickers was preserved." -ForegroundColor Green
Write-Host "sizes.txt was not deleted." -ForegroundColor Green

if (-not [string]::IsNullOrWhiteSpace($MyScriptPath)) {

    $DeleteCommand = 'timeout /t 2 /nobreak > nul && del /f /q "' + $MyScriptPath + '"'

    Start-Process `
        -FilePath "cmd.exe" `
        -ArgumentList "/c", $DeleteCommand `
        -WindowStyle Hidden
}

exit 0
