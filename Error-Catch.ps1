#function to catch the error
function Error-Catch{
    $curTime = Get-Date -Format o
    Write-Verbose -Verbose -Message $curTime *>> $ScriptDir\logs\log_$timestamp.txt
    Write-Verbose -Verbose -Message $Error[0].Exception *>> $ScriptDir\logs\log_$timestamp.txt
}