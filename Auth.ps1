<#
Sample to athenticate in AAD or Graph API with secure credentials
Before use this sample you need to create password hash with PasswordCreate.ps1
#>

$ScriptDir = Split-Path $script:MyInvocation.MyCommand.Path
$adminUPN = "user@mydomain.com"
$adminPwd = Get-Content -Path $ScriptDir\pwd.txt
$adminSecurePwd = ConvertTo-SecureString -String $adminPwd -Force
$credentials = New-Object System.Management.Automation.PSCredential ($adminUPN, $adminSecurePwd)

# connect to needed instance
#Connect-AzureAD -Credential $credentials
#Connect-MSGraph -PSCredential $credentials