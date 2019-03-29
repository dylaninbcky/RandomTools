Function Send-Pushbullet {
    param([Parameter(Mandatory = $True)][string]$Title = $(throw "Title is mandatory, please provide a value."), [string]$Message = "", [string]$Link = "", [string]$DeviceIden = "", [string]$ContactEmail = "")
    $APIKey = 'APIKEY'
    if ($Link -ne "") {
        $Body = @{
            type        = "link"
            title       = $Title
            body        = $Message
            url         = $Link
            device_iden = $DeviceIden
            email       = $ContactEmail
        }
    }
    else {
        $Body = @{
            type        = "note"
            title       = $Title
            body        = $Message
            device_iden = $DeviceIden
            email       = $ContactEmail
        }
    }
    $Creds = New-Object System.Management.Automation.PSCredential ($APIKey, (ConvertTo-SecureString $APIKey -AsPlainText -Force))
    Invoke-WebRequest -Uri "https://api.pushbullet.com/v2/pushes" -Credential $Creds -Method Post -Body $Body
}