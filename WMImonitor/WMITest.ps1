<#
.SYNOPSIS
    Sinh hoạt động WMI để test WMITrace.ps1
#>

Write-Host "[+] Thực hiện một số truy vấn và hành động WMI..."

# 1. Query WMI: Lấy danh sách process đang chạy
Write-Host "[*] Query Win32_Process..."
Get-WmiObject -Class Win32_Process | Select-Object -First 5 | Format-Table ProcessId, Name

# 2. Query WMI: Lấy thông tin OS
Write-Host "[*] Query Win32_OperatingSystem..."
Get-WmiObject -Class Win32_OperatingSystem | Select-Object Caption, Version, BuildNumber

# 3. Gọi WMI Method: Tạo notepad.exe bằng WMI
Write-Host "[*] Tạo process notepad.exe bằng WMI..."
(Get-WmiObject -Class Win32_Process).Create("notepad.exe") | Out-Null

# 4. Query WMI: Lấy service đang chạy
Write-Host "[*] Query Win32_Service..."
Get-WmiObject -Class Win32_Service | Select-Object -First 5 | Format-Table Name, State

Write-Host "[+] Hoàn tất. Kiểm tra log bằng WMITrace.ps1 -Stop"
