#For subfolders
#Checking log files, delete first one if exist more that 10 log files
$folders = Get-ChildItem $ScriptDir\logs
foreach ($folder in $folders){
    $logs = Get-ChildItem $folder.FullName
    if ($logs.Count -gt 10){
        $deletingFile = $logs[0].FullName
        try {
            Remove-Item $deletingFile
            #Write-Verbose -Verbose -Message "$deletingFile deleted successfully" *>>  $logs[$logs.Length-1].FullName
            Write-Verbose -Verbose -Message "$deletingFile deleted successfully" *>>  $ScriptDir\logs\execution\execution_log_$timestamp.txt
        }
        catch{
            Write-Verbose -Verbose -Message "ERROR! Can't delete log file $deletingFile, script breaking. Please, check log files manually." *>>  $logs[$logs.Length-1].FullName
            Error-Catch
            Send-Logs
            break
        }
    }
}

#For one folder
#Checking log files, delete first one if exist more that 10 log files
$folder = "$ScriptDir\logs"
$logs = Get-ChildItem $folder
if ($logs.Count -gt 10){
    $deletingFile = $logs[0].FullName
    try {
        Remove-Item $deletingFile
        Write-Verbose -Verbose -Message "$deletingFile deleted successfully" *>>  $ScriptDir\logs\log_$timestamp.txt
    }
    catch{
        Write-Verbose -Verbose -Message "ERROR! Can't delete log file $deletingFile, script breaking. Please, check log files manually." *>>  $logs[$logs.Length-1].FullName
        Error-Catch
        break
    }
}