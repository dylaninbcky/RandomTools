function Get-Size {
    param([string]$pth)
    "{0:n0}" -f ((gci -path $pth -recurse | measure-object -property length -sum).sum / 1mb) + " mb"
}

Function Set-Auditlogging {
    param (
        $pad, $logpad, $filter = '*.*')
    if ($pad) {
        if (!(Test-Path C:\temp)) {
            mkdir C:\temp
        }
        else {
            Write-Host "Temp exists lets go"
        }
        #Delete old watchers
        Get-EventSubscriber | Unregister-Event
        #prepare watcher 
        $kijker = New-Object System.IO.FileSystemWatcher $pad, $filter -Property @{IncludeSubdirectories = $true; EnableRaisingEvents = $true;
            NotifyFilter = [IO.NotifyFilters]'FileName, Lastwrite'
        }
        #register objects
        $action = ( {
                $path = $Event.SourceEventArgs.FullPath
                $changetype = $Event.SourceEventArgs.ChangeType
                $time = $Event.TimeGenerated
                $Logline = "$time, $changeType, $path, $(Get-Size -pth $Event.SourceEventArgs.FullPath)"
                Out-File 'C:\temp\Auditlogging.txt' -Append -InputObject $Logline
            })
        Register-ObjectEvent $kijker "Created" -Action $action
        Register-ObjectEvent $kijker "Changed" -Action $action
        Register-ObjectEvent $kijker "Deleted" -Action $action
    }
    else {
        Write-Warning "pad is leeg"
    }
}

Set-Auditlogging -pad 'C:\Users\Dylan\Downloads'
