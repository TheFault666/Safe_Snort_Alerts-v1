function Show-Progress {
    param (
        [int]$current,
        [int]$total,
        [string]$activity = "Running Tests"
    )
    $percent = ($current / $total) * 100
    Write-Progress -Activity $activity -Status "$current of $total completed" -PercentComplete $percent
}

function Test-DNSRequests {
    Write-Host "`n[1/5] Testing Malicious DNS Lookups..."

    $domains = @(
        "malware.testdomain.com",
        "zeus.badguy.biz",
        "ransomware.fakeupdate.net",
        "phishing-site.loginverify.com",
        "cnc.unknownhost.pw"  #can add more 
    )

    $i = 0
    foreach ($domain in $domains) {
        Resolve-DnsName -Name $domain -ErrorAction SilentlyContinue | Out-Null
        Write-Host "[+] Requested DNS for: $domain"
        $i++
        Show-Progress -current $i -total $domains.Count -activity "Malicious DNS Lookups"
    }
}

function Test-HTTPRequests {
    Write-Host "`n[2/5] Testing Suspicious HTTP GET Requests..."

    $urls = @(
        "http://198.51.100.1",
        "http://203.0.113.5",
        "http://malicious.example.net/fakeupdate.exe",
        "http://attackersite.com/evil.js"  #can add more 
    )

    $userAgents = @(
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64)",
        "curl/7.68.0",
        "python-requests/2.25.1",
        "botnet-scanner/1.0",
        "CobaltStrike Beacon"  #can add more 
    )

    $i = 0
    foreach ($url in $urls) {
        $ua = Get-Random -InputObject $userAgents
        try {
            Invoke-WebRequest -Uri $url -Headers @{ "User-Agent" = $ua } -TimeoutSec 5 -ErrorAction SilentlyContinue
            Write-Host "[+] HTTP GET $url with UA: $ua"
        } catch {
            Write-Host "[-] Failed to reach $url (expected)"
        }
        $i++
        Show-Progress -current $i -total $urls.Count -activity "Suspicious HTTP Requests"
    }
}

function Test-TLSTraffic {
    Write-Host "`n[3/5] Simulating TLS Handshakes to Malicious IPs..."

    $ips = @("198.51.100.2", "203.0.113.7")
    $port = 443

    $i = 0
    foreach ($ip in $ips) {
        try {
            $client = New-Object System.Net.Sockets.TcpClient
            $client.Connect($ip, $port)

            $sslStream = New-Object System.Net.Security.SslStream($client.GetStream(), $false, ({ $true }))
            $sslStream.AuthenticateAsClient($ip)  # Trigger TLS handshake
            Write-Host "[+] TLS Handshake to $ip succeeded (unexpected)"
            $sslStream.Close()
            $client.Close()
        } catch {
            Write-Host "[*] Attempted TLS Handshake to $ip (failed as expected)"
        }
        $i++
        Show-Progress -current $i -total $ips.Count -activity "TLS Handshake Tests"
    }
}

function Test-PortScan {
    Write-Host "`n[4/5] Simulating Port Scan on pfSense Gateway..."

    $target = "192.168.xx.xx"  # Replace with your pfSense IP
    $ports = 21..30

    $i = 0
    foreach ($port in $ports) {
        try {
            $client = New-Object System.Net.Sockets.TcpClient
            $client.Connect($target, $port)
            Write-Host "[*] Port $port open on $target"
            $client.Close()
        } catch {
            Write-Host "[-] Port $port closed on $target"
        }
        $i++
        Show-Progress -current $i -total $ports.Count -activity "Port Scanning"
    }
}

function Test-CommandControlPattern {
    Write-Host "`n[5/5] Simulating Command & Control (C2) Beacon Pattern..."

    $url = "http://malicious.example.net/beacon"
    $interval = 3
    $count = 5

    for ($i = 1; $i -le $count; $i++) {
        try {
            Invoke-WebRequest -Uri $url -TimeoutSec 2 -ErrorAction SilentlyContinue
            Write-Host "[+] Beacon $i sent to $url"
        } catch {
            Write-Host "[-] Beacon $i failed (expected)"
        }
        Show-Progress -current $i -total $count -activity "C2 Beacon Simulation"
        Start-Sleep -Seconds $interval
    }
}

Clear-Host
Write-Host "=== Running Snort Testing Script ===`n"

Test-DNSRequests
Test-HTTPRequests
Test-TLSTraffic
Test-PortScan
Test-CommandControlPattern

Write-Host "`n=== All Tests Completed ==="
Write-Host "Check pfSense > Snort > Alerts to verify detection logs.`n"
