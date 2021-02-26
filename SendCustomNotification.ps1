$ScriptDir = Split-Path $script:MyInvocation.MyCommand.Path
$intunePSAdmUPN = ""
$intunePSAdmPW = Get-Content -Path $ScriptDir\pwd.txt
$intunePSAdmSPW = ConvertTo-SecureString -String $intunePSAdmPW -Force
$intuneCredentials = New-Object System.Management.Automation.PSCredential ($intunePSAdmUPN, $intunePSAdmSPW)
$ScriptDir = Split-Path $script:MyInvocation.MyCommand.Path
$hlpCredentials = $intuneCredentials

Connect-AzureAD -Credential $intuneCredentials

Connect-MSGraph -PSCredential $intuneCredentials

$testUPN = "UPN"

$androidDevices = Get-IntuneManagedDevice -Filter "contains(operatingSystem,'Android')" | Get-MSGraphAllPages | Where-Object {$_.userPrincipalName -eq $testUPN} | Select-Object deviceName,id,osVersion,emailAddress,model,lastSyncDateTime,userDisplayName,userPrincipalName, serialNumber

$id = $androidDevices[0].id
$uri = "https://graph.microsoft.com/beta/deviceManagement/managedDevices/$id/sendCustomNotificationToCompanyPortal"

$JSON = @"
            {
            "notificationTitle": "title",
            "notificationBody": "notification"
            }
"@

Invoke-MSGraphRequest -HttpMethod POST -Url $uri -Content $JSON