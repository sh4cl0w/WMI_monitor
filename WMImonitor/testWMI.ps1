<#
.SYNOPSIS
    Script để test WMI: query, tạo process qua WMI, tạo permanent WMI subscription (Filter + Consumer + Binding), xóa test objects, và test EncodedCommand.


USAGE
    # Run quick tests (queries + create notepad)
    .\WMITest_Full.ps1 -RunQuickTest

    # Create permanent subscription
    .\WMITest_Full.ps1 -CreateTestWmi

    # Remove test subscription
    .\WMITest_Full.ps1 -RemoveTestWmi

    # Run encoded command test
    .\WMITest_Full.ps1 -TestEncodedCommand

NOTE
    Run as Administrator.
#>

param (
    [switch]$RunQuickTest,
    [switch]$CreateTestWmi,
    [switch]$RemoveTestWmi,
    [switch]$TestEncodedCommand,
    [string]$TestName = "WmiTest",        # base name for created objects
    [switch]$Verbose
)

function Require-Admin {
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
    if (-not $isAdmin) {
        Write-Error "Script yêu cầu chạy với quyền Administrator. Hãy mở PowerShell as Administrator."
        exit 1
    }
}

function Run-QuickTests {
    Write-Host "[*] Chay quick WMI queries..."
    try {
        Write-Host "`n-- Top 5 processes (Win32_Process) --"
        Get-WmiObject -Class Win32_Process | Select-Object -First 5 -Property ProcessId,Name | Format-Table

        Write-Host "`n-- Operating System info (Win32_OperatingSystem) --"
        Get-WmiObject -Class Win32_OperatingSystem | Select-Object Caption, Version, BuildNumber | Format-List

        Write-Host "`n-- Top 5 Services (Win32_Service) --"
        Get-WmiObject -Class Win32_Service | Select-Object -First 5 -Property Name, State | Format-Table

        Write-Host "`n[*] Tạo process notepad.exe bằng WMI..."
        $procClass = Get-WmiObject -Class Win32_Process
        $result = $procClass.Create("notepad.exe")
        if ($result.ReturnValue -eq 0) {
            Write-Host "[+] notepad.exe đã được tạo (ProcessId: $($result.ProcessId))"
        } else {
            Write-Warning "[!] tao notepad that bai. ReturnValue = $($result.ReturnValue)"
        }
    }
    catch {
        Write-Error "Lỗi khi chạy quick tests: $_"
    }
}

function Create-PermanentWmiSubscription {
    param(
        [string]$BaseName = "WmiTest"
    )
    Require-Admin

    $namespace = "root\subscription"
    $filterName = "${BaseName}_Filter"
    $consumerName = "${BaseName}_Consumer"
    $bindingName = "${BaseName}_Binding"  # not used directly but for readability

    Write-Host "[*] Tạo permanent WMI subscription trong namespace: $namespace"
    Write-Host "[*] Filter name: $filterName"
    Write-Host "[*] Consumer name: $consumerName"

    try {
        # 1) Tạo __EventFilter
        $filterClass = [wmiclass]"\\.\$namespace:__EventFilter"
        $filter = $filterClass.CreateInstance()
        # Query: bắt sự kiện tạo instance mới của Win32_Process (WITHIN 5s)
        $filter.Name = $filterName
        $filter.Query = "SELECT * FROM __InstanceCreationEvent WITHIN 5 WHERE TargetInstance ISA 'Win32_Process'"
        $filter.QueryLanguage = "WQL"
        $filter.EventNamespace = "root\cimv2"
        $filter.Put() | Out-Null
        Write-Host "[+] __EventFilter tao xong."

        # 2) Tạo CommandLineEventConsumer
        $consumerClass = [wmiclass]"\\.\$namespace:CommandLineEventConsumer"
        $consumer = $consumerClass.CreateInstance()
        $consumer.Name = $consumerName
        # CommandLineTemplate: command sẽ chạy khi event xảy ra
        # Dùng calc.exe làm ví dụ (thân thiện)
        $consumer.CommandLineTemplate = "calc.exe"
        $consumer.Put() | Out-Null
        Write-Host "[+] CommandLineEventConsumer tao xong."

        # 3) Tạo binding __FilterToConsumerBinding
        $bindClass = [wmiclass]"\\.\$namespace:__FilterToConsumerBinding"
        $binding = $bindClass.CreateInstance()
        # Filter và Consumer phải là relative path (Path.RelativePath)
        $binding.Filter = $filter.Path.RelativePath
        $binding.Consumer = $consumer.Path.RelativePath
        $binding.Put() | Out-Null
        Write-Host "[+] __FilterToConsumerBinding tạo xong."

        Write-Host "[+] Permanent subscription da duoc tao thanh cong."
        Write-Host "[!] Moi khi co process duoc tao, consumer se chay calc.exe."
    }
    catch {
        Write-Error "Tạo subscription thất bại: $_"
    }
}

function Remove-PermanentWmiSubscription {
    param(
        [string]$BaseName = "WmiTest"
    )
    Require-Admin

    $namespace = "root\subscription"
    $filterName = "${BaseName}_Filter"
    $consumerName = "${BaseName}_Consumer"

    Write-Host "[*] Xóa các WMI test objects có tên chứa: $BaseName"

    try {
        # Remove bindings that reference our filter/consumer
        $bindings = Get-WmiObject -Namespace $namespace -Class __FilterToConsumerBinding -ErrorAction SilentlyContinue
        if ($bindings) {
            foreach ($b in $bindings) {
                try {
                    if ($b.Filter -and $b.Consumer) {
                        if ($b.Filter -like "*$filterName*" -or $b.Consumer -like "*$consumerName*") {
                            Write-Host "[+] Xóa binding: $($b.Path)"
                            $b.Delete() | Out-Null
                        }
                    }
                } catch { }
            }
        }

        # Remove consumers
        $consumers = Get-WmiObject -Namespace $namespace -Class CommandLineEventConsumer -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq $consumerName }
        foreach ($c in $consumers) {
            Write-Host "[+] Xóa consumer: $($c.Name)"
            $c.Delete() | Out-Null
        }

        # Remove filters
        $filters = Get-WmiObject -Namespace $namespace -Class __EventFilter -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq $filterName }
        foreach ($f in $filters) {
            Write-Host "[+] Xóa filter: $($f.Name)"
            $f.Delete() | Out-Null
        }

        Write-Host "[+] hoan tat xoa. "
    }
    catch {
        Write-Error "Xóa subscription thất bại: $_"
    }
}

function Test-EncodedCommand {
    param(
        [string]$Command = 'Start-Process mspaint; Start-Process calc'
    )
    Write-Host "[*] tao EncodedCommand tu: $Command"
    $bytes = [System.Text.Encoding]::Unicode.GetBytes($Command)
    $encoded = [Convert]::ToBase64String($bytes)
    Write-Host "[+] EncodedCommand:"
    Write-Host $encoded

    Write-Host "[*] Chay EncodedCommand  ..."
    # 注意: sử dụng -WindowStyle Hidden và -NoProfile
    Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -WindowStyle Hidden -EncodedCommand $encoded" -WindowStyle Hidden
    Write-Host "[+] lenh da chay (mspaint + calc)."
}

# ================= main =================
if ($RunQuickTest) {
    Run-QuickTests
}

if ($CreateTestWmi) {
    Create-PermanentWmiSubscription -BaseName $TestName
}

if ($RemoveTestWmi) {
    Remove-PermanentWmiSubscription -BaseName $TestName
}

if ($TestEncodedCommand) {
    Test-EncodedCommand
}

if (-not ($RunQuickTest -or $CreateTestWmi -or $RemoveTestWmi -or $TestEncodedCommand)) {
    Write-Host "Usage examples:"
    Write-Host "  .\WMITest_Full.ps1 -RunQuickTest"
    Write-Host "  .\WMITest_Full.ps1 -CreateTestWmi"
    Write-Host "  .\WMITest_Full.ps1 -RemoveTestWmi"
    Write-Host "  .\WMITest_Full.ps1 -TestEncodedCommand"
}

