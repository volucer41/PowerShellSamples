<#
Sample to save password hash to file
Only user created this hash can be authenticated with that file
If you want save password hash for service account use runas command or task scheduler
#>

$ScriptDir = Split-Path $script:MyInvocation.MyCommand.Path
$password = 'password'
$passwordSecure = ConvertTo-SecureString -AsPlainText -String $password -Force 
$passwordSecure| ConvertFrom-SecureString | Set-Content -Path $ScriptDir\pwd.txt