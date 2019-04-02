Function Send-teammessage{
    [cmdletbinding()]

    param (
    [parameter(Mandatory=$true,Position=0)]$text
    )
    $webhook = '##YOURWEBHOOKHERE##'
    $prejson = @{
        "Text" = $text
    }
    $json = ConvertTo-Json $prejson
    Invoke-RestMethod -Method post -ContentType 'Application/Json' -Body $json -Uri $webhook
}