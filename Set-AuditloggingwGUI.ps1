#Your XAML goes here :)
$inputXML = @"
<Window x:Class="Auditloggerps1.MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        xmlns:local="clr-namespace:Auditloggerps1"
        mc:Ignorable="d"
        Title="Auditlogger" Height="450" Width="558.402">
    <Grid>
        <Label x:Name="LABEL_TOP" Content="Audit logger voor Fileshare" HorizontalAlignment="Left" Margin="18,25,0,0" VerticalAlignment="Top" Width="297" FontFamily="MV Boli" FontSize="20" Background="White" Foreground="#FF272727"/>
        <TextBlock x:Name="TEXTBLOCK_DESCRIPTION" HorizontalAlignment="Left" Margin="30,72,0,0" TextWrapping="Wrap" Text="Je kunt hier een map kiezen die word bekeken, vervolgens worden alle changes gelogt in                       C:\temp\Auditlogging.txt" VerticalAlignment="Top" Height="69" Width="268" FontFamily="Dubai Medium" Foreground="#FF4B4B4B"/>
        <TextBox x:Name="TEXTBOX_MAP" HorizontalAlignment="Left" Height="32" Margin="30,162,0,0" TextWrapping="Wrap" Text="Map: " VerticalAlignment="Top" Width="143" FontSize="14"/>
        <TextBox x:Name="TEXTBOX_FILTER" HorizontalAlignment="Left" Height="32" Margin="30,207,0,0" TextWrapping="Wrap" Text="Filter:" VerticalAlignment="Top" Width="143" FontSize="14"/>
        <Button x:Name="BUTTON_REGISTER" Content="REGISTER JOB!" HorizontalAlignment="Left" Margin="30,272,0,0" VerticalAlignment="Top" Width="143" Height="24"/>
        <Image x:Name="IMAGE_DYLAN" HorizontalAlignment="Left" Height="100" Margin="411,25,0,0" VerticalAlignment="Top" Width="75" Source="https://logos.textgiraffe.com/logos/logo-name/dylan-designstyle-i-love-m.png"/>
        <Button x:Name="BUTTON_SHOWOUTPUT" Content="SHOW OUTPUT!" HorizontalAlignment="Left" Margin="343,272,0,0" VerticalAlignment="Top" Width="143" Height="24"/>
        <Label x:Name="STATUSLABEL" Content="" HorizontalAlignment="Left" Margin="200,168,0,0" VerticalAlignment="Top" Width="350" FontSize="12"/>
        <Label x:Name="INFORMATION_LABEL" Content="Je kunt na het registreren van de Job het venster sluiten, laat de ISE sessie wel open.&#xD;&#xA;Of de powershell sessie waar je hem mee hebt geopend.. &#xD;&#xA;Bijv: ./AuditloggerGUI.ps1" HorizontalAlignment="Left" Margin="30,301,0,0" VerticalAlignment="Top" Height="83" Width="456" FontSize="10"/>
        <CheckBox x:Name="CLEANUPBOX" Content="Cleanup Old sessions?" HorizontalAlignment="Left" Margin="30,243,0,0" VerticalAlignment="Top"/>
    </Grid>
</Window>
"@ 
 
$inputXML = $inputXML -replace 'mc:Ignorable="d"','' -replace "x:N",'N' -replace '^<Win.*', '<Window'
[void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
[xml]$XAML = $inputXML
$reader=(New-Object System.Xml.XmlNodeReader $xaml)
try{
    $Form=[Windows.Markup.XamlReader]::Load( $reader )
}
catch{
    Write-Warning "Unable to parse XML, with error: $($Error[0])`n Ensure that there are NO SelectionChanged or TextChanged properties in your textboxes (PowerShell cannot process them)"
    throw
}
$xaml.SelectNodes("//*[@Name]") | %{"trying item $($_.Name)";
    try {Set-Variable -Name "WPF$($_.Name)" -Value $Form.FindName($_.Name) -ErrorAction Stop}
    catch{throw}
    }
 
Function Get-FormVariables{
if ($global:ReadmeDisplay -ne $true){Write-host "If you need to reference this display again, run Get-FormVariables" -ForegroundColor Yellow;$global:ReadmeDisplay=$true}
write-host "Found the following interactable elements from our form" -ForegroundColor Cyan
get-variable WPF*
}
 
Get-FormVariables

function Get-Size {
    param([string]$pth)
    "{0:n0}" -f ((gci -path $pth -recurse | measure-object -property length -sum).sum / 1mb) + " mb"
}

Function Set-Auditlogging {
    [Cmdletbinding()]
    param (
        $pad, $logpad, $filter = '*.*',[switch]$cleanup)
    if ($pad) {
        if (!(Test-Path C:\temp)) {
            mkdir C:\temp
        }
        else {
            Write-Host "Temp exists lets go"
        }
        Write-Verbose 'Deleting old subscribers'
        #Delete old watchers
        if ($cleanup){Get-EventSubscriber | Unregister-Event}
        #prepare watcher 
        Write-Verbose 'preparing watcher'
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
        Write-Verbose 'registered object Created'
        Register-ObjectEvent $kijker "Changed" -Action $action
        Write-Verbose 'registered object Changed'
        Register-ObjectEvent $kijker "Deleted" -Action $action
        Write-Verbose 'registered object Deleted'
    }
    else {
        Write-Warning "pad is leeg"
    }
}
write-host "To show the form, run the following" -ForegroundColor Cyan
$WPFTEXTBOX_MAP.Add_MouseEnter({if ($WPFTEXTBOX_MAP.Text -like '*Map:*'){$WPFTEXTBOX_MAP.Text = ''}})
$WPFTEXTBOX_FILTER.Add_MouseEnter({if ($WPFTEXTBOX_FILTER.Text -like '*Filter:*'){$WPFTEXTBOX_FILTER.Text = ''}})
$WPFBUTTON_REGISTER.Add_Click({
    if ($WPFCLEANUPBOX.IsChecked -eq $true){
        if (($WPFTEXTBOX_FILTER.Text -eq '') -or ($WPFTEXTBOX_FILTER.Text -like '*Filter:*' )){
            Set-Auditlogging -pad $WPFTEXTBOX_MAP.Text -cleanup -Verbose 
            $WPFSTATUSLABEL.Content = 'Audit logging aangemaakt! (Options: Cleaning)'
        }
        else {
            Set-Auditlogging -pad $WPFTEXTBOX_MAP.Text -filter $WPFTEXTBOX_FILTER.Text -cleanup -Verbose
            $WPFSTATUSLABEL.Content = 'Audit logging aangemaakt! (Options: Cleaning,Filtering)'
        }
    }
    else {
        if (($WPFTEXTBOX_FILTER.Text -eq '') -or ($WPFTEXTBOX_FILTER.Text -like '*Filter:*' )){
            Set-Auditlogging -pad $WPFTEXTBOX_MAP.Text -Verbose
            $WPFSTATUSLABEL.Content = 'Audit logging aangemaakt! (Options: X)'
        }
        else {
            Set-Auditlogging -pad $WPFTEXTBOX_MAP.Text -filter $WPFTEXTBOX_FILTER.Text -Verbose
            $WPFSTATUSLABEL.Content = 'Audit logging aangemaakt! (Options: Filtering)'
        }
    }

})
$WPFBUTTON_SHOWOUTPUT.Add_Click({notepad.exe C:\temp\Auditlogging.txt})

$Form.ShowDialog() | out-null

$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
