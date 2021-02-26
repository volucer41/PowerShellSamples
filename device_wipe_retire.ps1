#Retire AFW/iOS/ADA - Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/$id/retire" -Headers $authToken -Method Post
#
#Wipe AFM/iOS/ADA - Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/$id/wipe" -Headers $authToken -Method Post
#
#Retire AFW/Wipe AFM/Retire Android Device Administrator - Get-IntuneManagedDevice | Get-MSGraphAllPages | Where-Object {$_.azureADDeviceId -eq $azureADDeviceId} | Remove-IntuneManagedDevice
#
#Delete SN or IMEI - Remove-CorporateDeviceIdentifier -ImportedDeviceId $CDI_Id
#
#Delete device from AAD - Get-AzureADDevice -all $true | Where-Object {$_.DeviceId -eq $azureADDeviceId} | Remove-AzureADDevice



function Get-AuthToken
{
    Param(
        [Parameter(Mandatory=$true)]  $Tenant,
        [Parameter(Mandatory=$true)]  $ClientID,
        [Parameter(Mandatory=$true)]  $ClientSecret
    )

        $uri_token = "https://login.microsoftonline.com/$tenant/oauth2/token"
        $TokenRequest = @{
                  Grant_Type    = "client_credentials"
                  Scope         = "https://graph.microsoft.com/.default"
                  Resource      = "https://graph.microsoft.com/"
                  Client_Id     = $ClientID
                  Client_Secret = $ClientSecret
                  }

        $TokenResponse = Invoke-RestMethod -Uri $uri_token `
                                       -Method POST `
                                       -Body $TokenRequest
        $tokenAccessToken = $TokenResponse.access_token
        $authToken = @{"authorization" = "Bearer $tokenaccesstoken"}
        return $authToken

}


function Connect-MSGraphByApp
{
        Param(
        [Parameter(Mandatory=$true)]  $tenant,
        [Parameter(Mandatory=$true)]  $ClientID,
        [Parameter(Mandatory=$true)]  $ClientSecret
    )

    $authority = “https://login.windows.net/$tenant”
    Update-MSGraphEnvironment -AppId $clientId -Quiet
    Update-MSGraphEnvironment -AuthUrl $authority -Quiet
    Connect-MSGraph -ClientSecret $clientSecret
}



try{
    $tenant = ""
    $clientID = ''
    $clientSecret = ""
    $authToken = Get-AuthToken -Tenant $tenant -ClientID $clientID -ClientSecret $clientSecret

    Connect-MSGraphByApp -tenant $tenant -ClientID $clientID -ClientSecret $clientSecret

    $devices = Get-IntuneManagedDevice | Get-MSGraphAllPages | Where-Object {$_.userPrincipalName -eq $username -and $_.serialNumber -eq $identifier -and $_.operatingSystem -eq $os}

    if ($devices -eq $null -OR $devices -eq '') {
        throw "Devices were not found. Please check Username, Identifier and OS.";
    }

    #$devices = Get-IntuneManagedDevice | Get-MSGraphAllPages | Where-Object {​​​​​$_.userPrincipalName -eq "_testbackup@jtilab.onmicrosoft.com" -and $_.operatingSystem -eq $os}​​​​​
    $deviceGroup = $devices | Group-Object -Property lastSyncDateTime
    $newestDevice = $deviceGroup.Group | Sort-Object -Property lastSyncDateTime -Descending | Select-Object -First 1
    $id = $newestDevice.id
    $isDeviceRvoke = $false

    if ($revokeMethod -eq "retire"){
        #Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/$id/retire" -Headers $authToken -Method Post
        $isDeviceRevoked = $true
        $ExitText = "Device $($newestDevice.deviceName) was retired."
    }
    elseif ($revokeMethod -eq "wipe"){
        #Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/$id/wipe" -Headers $authToken -Method Post
        $isDeviceRevoked = $true
        $ExitText = "Device $($newestDevice.deviceName) was wiped."
    }

    if ($isDeviceRevoked){
        $azureADDeviceIDs = $devices | Select-Object azureADDeviceId
        $CDI = ((Invoke-RestMethod -Uri "https://graph.microsoft.com/beta/deviceManagement/importedDeviceIdentities?`$filter=contains(importedDeviceIdentifier,'$identifier')" -Headers $authToken -Method Get).value).id
        if (![string]::IsNullOrEmpty($CDI)){​​​​​
            #Invoke-RestMethod -Uri "https://graph.microsoft.com/beta/deviceManagement/importedDeviceIdentities/$CDI" -Headers $authToken -Method Delete
            $ExitText += "SN found and deleted."
    }
        else {
            $ExitText += "SN not found in database."
        }
        $oldDevices = $deviceGroup.Group | Sort-Object -Property lastSyncDateTime -Descending | Select-Object -Skip 1
        foreach ($oldDevice in $oldDevices){
            $oldId = $oldDevice.id
            #Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/$oldId" -Headers $authToken -Method Delete
            $ExitText += "Device $($oldDevice.deviceName) deleted."
        }
    }



    $adminUPN = ""
    $adminPwd = ""
    $adminSecurePwd = ConvertTo-SecureString -String $adminPwd -AsPlainText -Force
    $credentials = New-Object System.Management.Automation.PSCredential ($adminUPN, $adminSecurePwd)
    Connect-AzureAD -Credential $credentials

    $azureADDevices = Get-AzureADDevice -all $true
    foreach ($azureADDeviceID in $azureADDeviceIDs){
        $azureADDevices | Where-Object {$_.DeviceId -eq $azureADDeviceID} | Remove-AzureADDevice
    }
}
catch
{}