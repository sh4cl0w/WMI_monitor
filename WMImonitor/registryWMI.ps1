# Monitor specific registry keys (requires appropriate permissions)
$RegistryQuery = @"
SELECT * FROM RegistryKeyChangeEvent WHERE 
Hive='HKEY_LOCAL_MACHINE' AND 
KeyPath='SOFTWARE\\\\Microsoft\\\\Windows\\\\CurrentVersion\\\\Run'
"@

try {
    $RegistryWatcher = New-Object System.Management.ManagementEventWatcher($RegistryQuery)
    
    Register-ObjectEvent -InputObject $RegistryWatcher -EventName "EventArrived" -Action {
        Write-Host "Registry changed in Run key - Possible startup program modification!" -ForegroundColor Red
    }
    
    $RegistryWatcher.Start()
    Write-Host "Registry monitoring started..." -ForegroundColor Green
}
catch {
    Write-Host "Registry monitoring requires elevated privileges: $($_.Exception.Message)" -ForegroundColor Yellow
}