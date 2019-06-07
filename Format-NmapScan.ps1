Function Format-NmapScan {
    param (
    [parameter(Mandatory = $true, Position = 0,
        Helpmessage = "Volledige command voor port outputting",
        ValueFromPipeline)][scriptblock]$Command
    )
    BEGIN {$stringcommand  = $Command.ToString().Trim() + " -OutFormat HashTable"}
    PROCESS {
        $results = Invoke-Expression -Command $stringcommand
        $output = @()
        for ($i = 0; $i -lt $results.host.ports.port.portid.Length; $i++) {
            $output += [PSCustomObject]@{
                Poorten  = $results.host.ports.port.portid[$i]
                Protocol = $results.host.ports.port.protocol[$i]
                Target   = $results.host.address.addr  
            }
        }
    }
    End {
        Write-host "Scan completed, results as followed: " -ForegroundColor Green
        return $output
    }
}

Format-NmapScan {
    Invoke-Nmap nas.dberghuis.nl -All
}