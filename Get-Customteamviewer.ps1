$downloadpath = "$ENV:HOMEPATH\Desktop"
$URL = "https://get.teamviewer.com/xxxx
Function Start-TeamViewerQSDownload () {
    $iebrowser = New-Object -ComObject InternetExplorer.Application
    $iebrowser.Navigate($URL)
    Start-Sleep -Seconds 3
    $CustomTeamviewer = $iebrowser.Document.getElementById('MasterBodyContent_btnRetry').href
    Start-BitsTransfer -source $CustomTeamviewer -Destination $downloadpath\TeamViewerQS.exe       
}

Function Set-TeamviewerQS{
    param(
        $downloadpath,
        $customURL
    )
    try {
        if (Test-Path $downloadpath){
            Start-TeamViewerQSDownload
        }
    }
    catch{
        Write-Output 'cannot download teamviewer'
    }
}

if  (!(Test-path "$downloadpath\TeamviewerQS.exe")){
    Set-TeamviewerQS -downloadpath $downloadpath -customURL $URL
}
else{
    Write-host 'Teamviewer already installed' -ForegroundColor Green
}
