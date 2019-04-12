Function Get-Eventlog {
    param (
        [parameter(HelpMessage="Enable transcript for logging")]
        [switch]$enablelogging,
        [parameter(HelpMessage="Export enablen")]
        [switch]$exportenabled,
        [parameter(Mandatory=$true)]$logpad,
        [parameter(HelpMessage="Outputpath")]
        $resultpath = "$PSScriptRoot\"
    )
    BEGIN {
        Push-Location $resultPath
        $date = (Get-Date).ToString('dddd dd MMM yyyy')
        if ($enablelogging){
            Start-Transcript -Path "$logpad\$date.txt" -ErrorAction SilentlyContinue
            Write-Host "Logging aangezet"
        }
        ## http://www.computerperformance.co.uk/powershell/powershell_get_winevent.htm
        $currentculture = [System.Threading.Thread]::CurrentThread.CurrentCulture
        $eventloglist = 'System','Application','Setup'
        ## hoelang je terug gaat , verander dit naar preference
        $startdate = ((Get-Date).AddDays(-25))
        $COUNT = 0
        $Activity = 'Checking log properties'
    }
    PROCESS {
        foreach ($eventlog in $eventloglist){
            $COUNT += 1
            $pct = ($Count / $eventloglist.Count * 100)
            Write-Progress -Activity $Activity -Status $eventlog -PercentComplete $pct
            $export = Get-WinEvent -ListLog $eventlog | Select-Object  -Property LogName,LogFilePath,LogType,RecordCount,MaximumSizeInBytes,FileSize,LastWriteTime,LastAccessTime,IsLogFull,Logmode 
            $export

            ##preppen ven export
            $exportfile = $resultPath + "_props" + $eventlog + ".CSV.TXT"
            if ($exportenabled){
                $export | Export-Csv $exportfile -NoTypeInformation
            }
        }
        $allevents = [System.Collections.Hashtable]
        $COUNT = 0
        $Activity = 'Checken van details van log'
        foreach ($eventlog in $eventloglist){
            $COUNT += 1
            $pct = ($COUNT / $eventloglist.Count * 100)
            $status = $EventLog + " (" + $Count + "/" + $EventLogList.Count +")"
            Write-Progress -Activity $Activity -Status $status -PercentComplete $pct 
            Write-Host $count + '.' + $eventlog
            if ($eventlog -eq 'System'){[System.Threading.Thread]::CurrentThread.CurrentCulture = $currentculture}
            ## query de logs ##
            $allevents = $null
            $allevents = Get-WinEvent -FilterHashtable @{logname=$eventlog;StartTime=$startdate;level=0,1,2,3,4,5} -ErrorAction SilentlyContinue

            if ($allevents.Count -eq 0){
               Write-Host "No events for " + $eventlog + "log since "+ $startdate + "."
               continue
            }
            ## groepering per eventtype

            Write-host "Groepering per event"

            $export = $allevents | Group-Object -Property {$_.LevelDisplayName} -NoElement | Sort-Object Count -Descending  
            $export | Format-Table -AutoSize

            ##prepping export

            $exportfile = $resultPath + "_EventNameStats" + $eventlog + ".csv.txt"
            if ($exportEnabled) {$export | Select-Object -Property Count,Name |Export-Csv $exportfile}

            ##statistics voor non-information
            Write-Host "Status per event id"
            $evtStats = $allEvents | where -Property level -Notin -Value 0,4 | Group-Object id | Sort-Object Count -Descending 
            $allevents = $Null
            $export = $evtStats | Select-Object Count,Name
            $export | Format-table -AutoSize
            $exportfile = $resultPath + "_EventIDStats"+ $eventlog + ".csv.txt"
            if ($exportenabled){$export | Export-Csv $exportfile -NoTypeInformation}

            #prepping output

            [System.Collections.ArrayList]$results = @() 
            $Activity = 'Zoeken naar laatste voorkoming van event'
            $i = 0

            foreach ($item in $evtStats){
                $i += 1
                $pct = ($i / $evtStats.Count * 100)
                $eventid = $item.Name
                $status = "EventID: " + $item.Name
                Write-Progress -Activity $Activity -Status $status -PercentComplete $pct

                $customobj = "" | select Count,TimeCreated,ErrorID,ErrorType,Source,Message
                $customobj.Count = $item.Count
                $customobj.ErrorID = $item.Name
                    
                #get most recent event from the eventID
                $id = $item.Name.ToInt32($Null)
        
                [System.Threading.Thread]::CurrentThread.CurrentCulture = New-Object "System.Globalization.CultureInfo" "en-US"
                $lastevent = get-winevent -FilterHashtable @{LogName=$eventlog;Id=$id} -MaxEvents 1 -ErrorAction SilentlyContinue
        
                #depending on local settings, query might fail, if it fails reset to local culture 
                if ($lastevent.LevelDisplayName.Length -eq 0) 
                {
                    [System.Threading.Thread]::CurrentThread.CurrentCulture = $currentCulture
                    $lastevent = get-winevent -FilterHashtable @{LogName=$eventlog;Id=$id} -MaxEvents 1
                }
        
                $customobj.ErrorType = $lastevent.LevelDisplayName
                $customobj.Source = $lastevent.ProviderName
                $customobj.TimeCreated = $lastevent.TimeCreated
                $customobj.Message = $lastevent.Message
        
                
                #prep EventID export
                $exportfile = $resultPath + $eventlog +'_EventID_' + $customobj.ErrorID + ".csv.txt"
                if ($exportEnabled) 
                {
                    $customobj | Export-Csv $exportfile -NoTypeInformation
                }
        
                $results += $customobj
            
            }

            Write-Host "Laatste details per event"
            $results | Format-Table -AutoSize
            if ($exportEnabled) 
            {
                $exportfile = $resultPath + "_lastEvents_short_" + $eventlog + ".txt"
                $results| Format-Table -AutoSize | out-file $exportfile
                $exportfile = $resultPath + "_lastEvents_detail_" + $eventlog + ".txt"
                $results | out-file $exportfile
            }
        }
    }
    END{
        if ($enablelogging){Stop-Transcript -WarningAction Ignore -ErrorAction SilentlyContinue}
        Pop-Location
    }
}


Get-Eventlog -enablelogging -exportenabled -logpad 'C:\temp' -resultpath 'C:\temp\'