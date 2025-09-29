
param (
    [switch]$Start,
    [switch]$Stop,
    [string]$LogDir = "C:\Windows\Temp\",
    [string]$SessionName = "WMImonitor"
)

# Provider WMI
$Provider = "Microsoft-Windows-WMI-Activity"
$ETLFile  = Join-Path $LogDir "$SessionName.etl"
$CSVFile  = Join-Path $LogDir "$SessionName.csv"
$XMLFile  = Join-Path $LogDir "$SessionName.xml"
$JSONFile = Join-Path $LogDir "$SessionName.json"

if ($Start) {
    if (-not (Test-Path $LogDir)) {
        New-Item -ItemType Directory -Path $LogDir | Out-Null
    }

    Write-Host "[+] Tao va start ETW session: $SessionName"
    logman create trace $SessionName -p $Provider -o $ETLFile -ets

    Write-Host "[+] Session da bat dau. Log se ghi vao file: $ETLFile"
    Write-Host "[!] dung '.\WMImonitor.ps1 -Stop' de dung va xuat log."
}

elseif ($Stop) {
    Write-Host "[+] dung ETW session: $SessionName"
    logman stop $SessionName -ets

    if (Test-Path $ETLFile) {
        Write-Host "[+] Xuat log ra CSV: $CSVFile"
        tracerpt $ETLFile -o $CSVFile -of CSV

        Write-Host "[+] Xuat log ra XML: $XMLFile"
        tracerpt $ETLFile -o $XMLFile -of XML

        Write-Host "[+] Chuyen CSV sang JSON: $JSONFile"
        try {
            Import-Csv $CSVFile | ConvertTo-Json -Depth 5 | Out-File $JSONFile -Encoding UTF8
            Write-Host "[+] Done!"
        }
        catch {
            Write-Warning "loi khong the CSV sang JSON: $_"
        }
    }
    else {
        Write-Warning "khong tim thay  file $ETLFile"
    }
}

else {
    Write-Host "su dung:"
    Write-Host "  .\WMImonitor.ps1 -Start    # Bắt đầu monitor WMI"
    Write-Host "  .\WMImonitor.ps1 -Stop     # Dừng monitor và export log (CSV, XML, JSON)"
}
