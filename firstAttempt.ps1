function testport ($hostname='yahoo.com',$port=80,$timeout=100) {
  $requestCallback = $state = $null
  $client = New-Object System.Net.Sockets.TcpClient
  $beginConnect = $client.BeginConnect($hostname,$port,$requestCallback,$state)
  Start-Sleep -milli $timeOut
  if ($client.Connected) { $open = $true } else { $open = $false }
  $client.Close()
  [pscustomobject]@{hostname=$hostname;port=$port;open=$open}
}

$integratedWiredAdapter = Get-NetAdapter | Where-Object -FilterScript {$_.InterfaceDescription -Eq "Realtek PCIe GbE Family Controller"}
$phoneInternetAdapter = Get-NetAdapter | Where-Object -FilterScript {$_.InterfaceDescription -like "Remote NDIS based Internet Sharing Device*"}

$previousPingSucceeded = $True

while ($true) {
    $result = testport
    #Write-Host ($result | Format-List | Out-String)
    #$PingSucceeded = $result.PingSucceeded
    $PingSucceeded = $result.open

    if ($PingSucceeded -eq $False -and $previousPingSucceeded -eq $False) {
        Disable-NetAdapter -Name "Ethernet" -Confirm:$false
        Enable-NetAdapter -Name $phoneInternetAdapter.Name -Confirm:$false
        Write-Host "ping failed, disable wired internet"
    } else {
        Write-Host "ping succeeded, doing nothing"
    }

    Start-Sleep -Milliseconds 500
    $previousPingSucceeded = $PingSucceeded
}
