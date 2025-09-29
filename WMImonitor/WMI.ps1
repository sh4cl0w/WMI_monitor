# Simple_WMI_Subscription.ps1

$Name = "MyMonitor"
$Namespace = "root\subscription"

# Sửa lỗi: Tạo encoded command đúng cách
$Command = "Start-Process mspaint.exe; Start-Process calc.exe"
$Bytes = [System.Text.Encoding]::Unicode.GetBytes($Command)
$EncodedCommand = [Convert]::ToBase64String($Bytes)

# Sửa lỗi: CommandLineTemplate đúng format
$PowerShellCommand = "powershell.exe -ExecutionPolicy Bypass -EncodedCommand $EncodedCommand"

Write-Host "Encoded Command: $EncodedCommand" -ForegroundColor Yellow
Write-Host "Full Command: $PowerShellCommand" -ForegroundColor Cyan

# Cleanup existing
Write-Host "Cleaning up existing subscriptions..." -ForegroundColor Yellow
Get-WmiObject -Namespace $Namespace -Class __FilterToConsumerBinding | 
Where-Object { $_.Filter -like "*$Name*" -or $_.Consumer -like "*$Name*" } | 
ForEach-Object { 
    Write-Host "Removing binding: $($_.__PATH)" -ForegroundColor Gray
    $_.Delete() 
}

Get-WmiObject -Namespace $Namespace -Class __EventFilter | 
Where-Object { $_.Name -like "*$Name*" } | 
ForEach-Object { 
    Write-Host "Removing filter: $($_.Name)" -ForegroundColor Gray
    $_.Delete() 
}

Get-WmiObject -Namespace $Namespace -Class CommandLineEventConsumer | 
Where-Object { $_.Name -like "*$Name*" } | 
ForEach-Object { 
    Write-Host "Removing consumer: $($_.Name)" -ForegroundColor Gray
    $_.Delete() 
}

Start-Sleep 2

# Create new subscription
Write-Host "Creating new WMI subscription..." -ForegroundColor Yellow

try {
    # Create Event Filter
    $filter = Set-WmiInstance -Namespace $Namespace -Class "__EventFilter" -Arguments @{
        Name = $Name
        EventNamespace = "root\cimv2"
        QueryLanguage = "WQL"
        Query = "SELECT * FROM __InstanceCreationEvent WITHIN 10 WHERE TargetInstance ISA 'Win32_Process' AND TargetInstance.Name = 'notepad.exe'"
    }
    Write-Host "Filter created: $($filter.Name)" -ForegroundColor Green

    # Create Command Line Consumer
    $consumer = Set-WmiInstance -Namespace $Namespace -Class "CommandLineEventConsumer" -Arguments @{
        Name = $Name
        CommandLineTemplate = $PowerShellCommand
        RunInteractively = $false
        WorkingDirectory = "C:\Windows\System32\"
    }
    Write-Host "Consumer created: $($consumer.Name)" -ForegroundColor Green

    # Create Binding
    $binding = Set-WmiInstance -Namespace $Namespace -Class "__FilterToConsumerBinding" -Arguments @{
        Filter = $filter
        Consumer = $consumer
    }
    Write-Host "Binding created successfully!" -ForegroundColor Green

    Write-Host "`nWMI Event Subscription created successfully!" -ForegroundColor Green
    Write-Host "Test by running: Start-Process notepad.exe" -ForegroundColor Yellow
    
    # Verify the subscription
    Write-Host "`nVerifying subscription..." -ForegroundColor Cyan
    Get-WmiObject -Namespace $Namespace -Class __EventFilter | Where-Object { $_.Name -eq $Name }
    Get-WmiObject -Namespace $Namespace -Class CommandLineEventConsumer | Where-Object { $_.Name -eq $Name }
}
catch {
    Write-Host "Error creating subscription: $($_.Exception.Message)" -ForegroundColor Red
}