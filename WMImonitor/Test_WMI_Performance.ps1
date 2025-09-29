# Test_WMI_Performance.ps1
Write-Host "=== WMI PERFORMANCE TEST ===" -ForegroundColor Green

# Đo thời gian thực hiện các truy vấn WMI
$queries = @(
    @{Name="Win32_ComputerSystem"; Query="SELECT * FROM Win32_ComputerSystem"},
    @{Name="Win32_Processor"; Query="SELECT * FROM Win32_Processor"},
    @{Name="Win32_PhysicalMemory"; Query="SELECT * FROM Win32_PhysicalMemory"},
    @{Name="Win32_LogicalDisk"; Query="SELECT * FROM Win32_LogicalDisk WHERE DriveType=3"},
    @{Name="Win32_Service"; Query="SELECT Name,State FROM Win32_Service"}
)

foreach ($query in $queries) {
    $startTime = Get-Date
    try {
        $result = Get-WmiObject -Query $query.Query
        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalMilliseconds
        Write-Host "✓ $($query.Name): $duration ms ($($result.Count) items)" -ForegroundColor Green
    }
    catch {
        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalMilliseconds
        Write-Host "✗ $($query.Name): $duration ms - ERROR: $($_.Exception.Message)" -ForegroundColor Red
    }
}