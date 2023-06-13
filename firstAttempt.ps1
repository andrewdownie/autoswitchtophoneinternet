function testport ($hostname='google.ca',$port=80,$timeout=100) {
  $requestCallback = $state = $null
  $client = New-Object System.Net.Sockets.TcpClient
  $beginConnect = $client.BeginConnect($hostname,$port,$requestCallback,$state)
  Start-Sleep -milli $timeOut
  if ($client.Connected) { $open = $true } else { $open = $false }
  $client.Close()
  [pscustomobject]@{hostname=$hostname;port=$port;open=$open}
}

# Run Get-NetAdapter to find what devices you want to use as primary/backup, using InterfaceDescription with asterisks seems to be a reliable and easy way to programatically grab the device you want to manipulate
$primaryAdapter = Get-NetAdapter | Where-Object -FilterScript {$_.InterfaceDescription -Eq "TP-Link Wireless MU-MIMO USB Adapter"}
$backupAdapter = Get-NetAdapter | Where-Object -FilterScript {$_.InterfaceDescription -like "SAMSUNG Mobile USB Remote*"}

if ($primaryAdapter -ne $NULL) {
    Enable-NetAdapter -Name $primaryAdapter.Name -Confirm:$false
}

if ($backupAdapter -ne $NULL -and $backupAdapter.Status -ne 'Disabled') {
    Disable-NetAdapter -Name $backupAdapter.Name -Confirm:$false
}

$previousPingSucceeded = $True
$primaryDisabled = $False

while ($true) {

    # Run Get-NetAdapter to find what devices you want to use as primary/backup, using InterfaceDescription with asterisks seems to be a reliable and easy way to programatically grab the device you want to manipulate
    $primaryAdapter = Get-NetAdapter | Where-Object -FilterScript {$_.InterfaceDescription -Eq "TP-Link Wireless MU-MIMO USB Adapter"}
    $backupAdapter = Get-NetAdapter | Where-Object -FilterScript {$_.InterfaceDescription -like "SAMSUNG Mobile USB Remote*"}

    $backupAdapterConnected = $backupAdapter -ne $NULL

    $result = testport
    #Write-Host ($result | Format-List | Out-String)
    #$PingSucceeded = $result.PingSucceeded
    $PingSucceeded = $result.open
    
    if ($PingSucceeded -eq $False -and $previousPingSucceeded -eq $False) {
        if ($backupAdapterConnected) {
            if ($primaryDisabled) {
                Write-Host "ping FAILED, WAITING for backup internet to come up"
            } else {
                Disable-NetAdapter -Name $primaryAdapter.Name -Confirm:$false
                Enable-NetAdapter -Name $backupAdapter.Name -Confirm:$false
                $primaryDisabled = $True
                Write-Host "ping failed, disabling primary internet"
            }

        } else {
            if ($primaryDisabled) {
                Enable-NetAdapter -Name $primaryAdapter.Name -Confirm:$false
                $primaryDisabled = $False
                Write-Host "ping FAILED, backup adapter is missing, renabling primary adapter"
            } else {
                Write-Host "ping FAILED, but back adapter is not connected so DOING NOTHING"
            }

        }
    } else {

        if ($backupAdapterConnected) {
            
            if ($primaryDisabled) {
                if ($primaryAdapter -ne $NULL) {
                    Write-Host "ping succeeded, doing nothing -- primary is disabled and backup adapter is engaged"
                }

            } else {
                Write-Host "ping succeeded, doing nothing -- backup adapter is READY"
            }

        } else {
            Write-Host "ping succeeded, doing nothing -- backup adapter is NOT connected"
        }

    }

    Start-Sleep -Milliseconds 500
    $previousPingSucceeded = $PingSucceeded
}
