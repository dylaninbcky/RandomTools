Function Remove-Lines{
    [cmdletbinding()]
    param (
        [parameter(Position=1,HelpMessage="input voor string to be replaced (Wildcard)")]
        $Wildcard,
        [parameter(Position=2,HelpMessage="Input string to be replaced (Literal)")]
        $Literal,
        [parameter(Position=0,HelpMessage="Input File to be replaced")]\
        $file
    )
    $output = @()
    $lines = Get-Content -path $file
    foreach ($line in $lines){
        if ($line -like $Wildcard){
            continue
        }
        elseif ($line -eq $Literal){
            continue
        }
        $output += $line
    }
    return $output
}