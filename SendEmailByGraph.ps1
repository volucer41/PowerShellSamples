function Get-jsonEmailBody
{
    Param(
        [Parameter(Mandatory=$true)]  $toRecipients,                      # String of recipient or an array of recipients
	    [Parameter(Mandatory=$False)] $bccRecipients,                     # String of BCC or an array of BCC recipients
        [Parameter(Mandatory=$False)] $attachments, 
	    [Parameter(Mandatory=$true)]  [string]$Subject,                   # Subject
	    [Parameter(Mandatory=$true)]  [string]$BodyText,                  # Email message
        [Parameter(Mandatory=$False)] [string]$BodyType = "HTML",         # HTML / Text
        [Parameter(Mandatory=$False)] [string]$Importance = "High",       # Low / Normal / High
        [Parameter(Mandatory=$False)] [string]$SaveToSentItems = "false"   # false / true
    )

    $objBody = @{
        message = @{
            importance = $Importance
            subject = $Subject
            body = @{
                contentType = $BodyType
                content = $BodyText
            }
            toRecipients = @(
                $toRecipients | %{@{emailAddress = @{address = $_}}}
            )
        }
        saveToSentItems = $SaveToSentItems
    } 
    if ($bccRecipients) {$objBody['message']['bccRecipients'] = @($bccRecipients | %{@{emailAddress = @{address = $_}}})}
    if ($attachments.count -gt 0) {$objBody['message']['attachments'] = @($attachments)}

    return $objBody | ConvertTo-Json -Depth 5

}

Function Get-AttachmentObj ($Name,$Type,$FilePath,$isInline=$false) {
    If ($Name -and $Type -and (test-path $FilePath)){
        return @{
            '@odata.type' = "#microsoft.graph.fileAttachment"
            name = $Name
            contentType = $Type
            contentBytes = [convert]::ToBase64String((Get-Content $FilePath -Encoding byte))
            isInline = if ($isInline) {"True"} else {"False"}
        }
    }
}

function Send-emailByGraph
{
    Param(
        [Parameter(Mandatory=$true)]  $SenderAddressUPN,
        [Parameter(Mandatory=$true)]  $Header,
        [Parameter(Mandatory=$true)]  $HtmlBody,
        [Parameter(Mandatory=$true)]  $attachments,
        [Parameter(Mandatory=$true)]  $EmailTo,
        [Parameter(Mandatory=$false)]  $EmailBcc,
        [Parameter(Mandatory=$true)]  $EmailSubject


    )

    $EmailBody = Get-jsonEmailBody -toRecipients $EmailTo `
                               -bccRecipients $EmailBcc `
                               -Subject $EmailSubject `
                               -BodyText "TextToReplaceToHtml" `
                               -attachments $attachments `
                               -SaveToSentItems "false"


    $EmailBody = $EmailBody.Replace("TextToReplaceToHtml",$HtmlBody)
    $EmailBody = [System.Text.Encoding]::UTF8.GetBytes($EmailBody)

    $SenEmailUri = "https://graph.microsoft.com/v1.0/users/$SenderAddressUPN/sendMail"

    $HtmlBodyUTF = [System.Text.Encoding]::UTF8.GetBytes($HtmlBody)
    # POST to Graph endpoint
    Invoke-RestMethod -Method Post `
                      -Uri $SenEmailUri `
                      -Headers $Header `
                      -ContentType "application/json" `
                      -Body $EmailBody

}

function Get-TokenResponse
{
    Param(
        [Parameter(Mandatory=$true)]  $uri_token,
        [Parameter(Mandatory=$true)]  $ClientID,
        [Parameter(Mandatory=$true)]  $ClientSecret
    )

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
        return $TokenResponse

}

$ClientID ="your app ID"
$uri_token = "endpoint to get token in your app"
$ClientSecret = "client secret"

$SenderAddressUPN = "user@mydomain.com"
$email = "email@mydomain.com"
$emailSubject = "test message"
$emailBody = "<html><body>My HTML</body></html>"

$TokenResponse = Get-TokenResponse -uri_token $uri_token -ClientID $ClientID -ClientSecret $ClientSecret
$tokenaccesstoken = $tokenresponse.access_token
$Header = @{"authorization" = "Bearer $tokenaccesstoken"}

$attachments = @()
$attachments += Get-AttachmentObj -Name "attachment"    -Type "image/png" -FilePath "$ScriptDir\myImage.png"

Send-emailByGraph -SenderAddressUPN $SenderAddressUPN -EmailTo $email -EmailSubject $emailSubject -HtmlBody $emailBody -attachments $attachments -Header $Header


