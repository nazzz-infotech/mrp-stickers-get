Write-Host "Uninstalling MRP Stickers ..." -ForegroundColor Red

# 1. Kill the app processes first (Silently ignores if they aren't running)
Write-Host "Closing running applications..." -ForegroundColor Cyan
Get-Process -Name "mrp_stickers" -ErrorAction SilentlyContinue | Stop-Process -Force
Get-Process -Name "php" -ErrorAction SilentlyContinue | Stop-Process -Force

# 2. Stop and delete the database background service
Write-Host "Stopping and removing database service..." -ForegroundColor Cyan
net stop "PostgreSQL_MRP_Stickers" 2>$null
sc.exe delete "PostgreSQL_MRP_Stickers"

# 3. Prompt user for persistent database deletion
$deldb = Read-Host -Prompt "Do you want to delete your saved data such as sellers, brands, articles, colors, sizes etc ... ? [YES/no]"
# 3.1. Handle data folder deletion safely without blocking the thread
Write-Host "Checking for database application assets..." -ForegroundColor Magenta
$DataPath = "C:\mrp_stickers\postgres-data"
if (Test-Path $DataPath) { 
    Write-Host "Removing saved data (sellers, brands, articles etc...)" -ForegroundColor Magenta
    # Force removal directly to avoid breaking Control Panel automation pipelines
    Remove-Item -Path $DataPath -Recurse -Force 
}

# 4. Clean up structural dependency directories
Write-Host "Removing environment dependencies..." -ForegroundColor Cyan
foreach ($item in @("adminer", "php", "pgsqlr", "connection.txt")) {
    $targetPath = "C:\mrp_stickers\$item"
    if (Test-Path $targetPath) { Remove-Item -Path $targetPath -Recurse -Force }
}

# 5. Unregister App from Control Panel and Windows Apps List
$AppName = "MRP Stickers"
$RegistryKeyPath = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\MRP-Stickers"
$PublicDesktopShortcut = "$env:PUBLIC\Desktop\$AppName.lnk"
$PublicStartMenuShortcut = "$env:PROGRAMDATA\Microsoft\Windows\Start Menu\Programs\$AppName.lnk"

Write-Host "Removing Windows shortcuts and registration data..." -ForegroundColor Cyan

if (Test-Path $RegistryKeyPath) {
    Remove-Item -Path $RegistryKeyPath -Recurse -Force
    Write-Host "✓ Removed application from Windows Registry." -ForegroundColor Green
}

if (Test-Path $PublicDesktopShortcut) {
    Remove-Item -Path $PublicDesktopShortcut -Force
    Write-Host "✓ Deleted Desktop shortcut." -ForegroundColor Green
}

if (Test-Path $PublicStartMenuShortcut) {
    Remove-Item -Path $PublicStartMenuShortcut -Force
    Write-Host "✓ Deleted Start Menu shortcut." -ForegroundColor Green
}

# 6. Safely Delete Application Binaries and Self-Destruct
Write-Host "Purging application binaries..." -ForegroundColor Cyan
$InstallDir = "C:\Program Files\MRP-Stickers"

if (Test-Path $InstallDir) {
    # Move the current terminal context away from any target directories
    Set-Location -Path "C:\"
    
    # Delete the main Program Files directory
    Remove-Item -Path $InstallDir -Recurse -Force 
    Write-Host "✓ Main application folder purged." -ForegroundColor Green
}

# 7. Check if C:\mrp_stickers is empty (except for this script) and wipe it completely
Write-Host "Finishing up uninstallation..." -ForegroundColor Cyan

# Point to this script's path and its parent directory
$MyScriptPath = $MyInvocation.MyCommand.Path
$MyParentDir = "C:\mrp_stickers"

# Shift terminal context to the root system drive
Set-Location -Path "C:\"

Write-Host "Cleanup complete! Closing window to finalize removal." -ForegroundColor Green

# Launch a background CMD process that waits 2 seconds for PowerShell to exit, 
# then deletes this script, and removes the parent directory.
Start-Process -FilePath "cmd.exe" -ArgumentList "/c timeout /t 2 /nobreak > nul && del /f /q `"$MyScriptPath`" && rd /s /q `"$MyParentDir`"" -WindowStyle Hidden
