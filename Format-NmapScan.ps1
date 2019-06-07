Function Format-NmapScan {
    [Cmdletbinding()]
    param (
    [parameter(Mandatory = $true, Position = 0,
        Helpmessage = "Volledige command voor port outputting",
        ValueFromPipeline)][scriptblock]$Command
    )
    PROCESS {
        $stringcommand  = $Command.ToString().Trim() + " -OutFormat HashTable"
        $results = Invoke-Expression -Command $stringcommand
        $output = @()
        for ($i = 0; $i -lt $results.host.ports.port.portid.Length; $i++) {
            $output += [PSCustomObject]@{
                Poorten  = $results.host.ports.port.portid[$i]
                Protocol = $results.host.ports.port.protocol[$i]
                Target   = $results.host.address.addr  
            }
        }
      return $output
    }
}

Format-NmapScan -Command {
    Invoke-Nmap -computerName www.google.com
}