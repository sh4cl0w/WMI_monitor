
Write-Host "=== KIỂM TRA WMI CƠ BẢN ===" -ForegroundColor Green

try {
    # Kiểm tra kết nối WMI
    $computer = $env:COMPUTERNAME
    Write-Host "Testing WMI on: $computer"
    
    # Lấy thông tin hệ thống
    $os = Get-WmiObject -Class Win32_OperatingSystem -ErrorAction Stop
    Write-Host "OS: $($os.Caption)" -ForegroundColor Green
    Write-Host "Version: $($os.Version)" -ForegroundColor Green
    
    # Lấy thông tin CPU
    $cpu = Get-WmiObject -Class Win32_Processor
    Write-Host "CPU: $($cpu.Name)" -ForegroundColor Green
    
    # Lấy thông tin RAM
    $memory = Get-WmiObject -Class Win32_ComputerSystem
    $totalMemory = [math]::Round($memory.TotalPhysicalMemory / 1GB, 2)
    Write-Host "Total RAM: $totalMemory GB" -ForegroundColor Green
    
    Write-Host "WMI test PASSED!" -ForegroundColor Green
}
catch {
    Write-Host "WMI test FAILED: $($_.Exception.Message)" -ForegroundColor Red
}