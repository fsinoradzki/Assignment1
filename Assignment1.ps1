#Frank Sinoradzki
#PowerShell script
#Dependent on AzureAD module import

#Checks to see if Azure is currently connected.
#If not, it prompts to connect to Azure
try { Get-AzureADCurrentSessionInfo
}
catch { Connect-AzureAD }

#Sets a password profile to give to newly created users
$PasswordProfile = New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordProfile
$PasswordProfile.Password = "<Password>"

#Gets the number of users that currently exist in the Azure account
#Assuming each user is named "Test User <number>", creates new accounts starting at the latest number +1
#UPN contains the allowed email domain on my personal Azure subscription
$numUsers = (Get-AzureADUser -Top 100000).Count+1
foreach($i in $numUsers..($numUsers+19)){
    New-AzureADUser `
    -DisplayName "Test User $i" `
    -PasswordProfile $PasswordProfile `
    -UserPrincipalName "TestUser$i@fsinoradzkigmail.onmicrosoft.com" `
    -AccountEnabled $true `
    -MailNickName "TestUser$i"
}

#If the Varonis Assignment Group doesn't already exist, creates the Group and stores its Object ID as a variable
if ((Get-AzureADGroup -SearchString "Varonis Assignment Group").Count -eq 0){
    New-AzureADGroup `
    -DisplayName "Varonis Assignment Group" `
    -MailEnabled $false `
    -SecurityEnabled $true `
    -MailNickName "NotSet"
}
$GroupID = (Get-AzureADGroup -SearchString "Varonis Assignment Group").ObjectID

#Adds each newly created user to the group
#Writes to a txt file with the timestamp, user's username, and if the addition was a success or failure
foreach($i in $numUsers..($numUsers+19)){
    $UserID = (Get-AzureADUser -Filter "startswith(DisplayName,'Test User $i')").ObjectID
    Write-Output (Get-AzureADUser -Filter "startswith(DisplayName,'Test User $i')").UserPrincipalName | Out-File -Append ./log.txt
    Write-Output Get-Date -Format "dddd MM/dd/yyyy HH:mm K" | Out-File ./log.txt

    #If the user is successfully added to the group, the logfile gets a "Success" entry
    #If it fails, the logfile gets a "Failure" entry
    try {
        Add-AzureADGroupMember -ObjectId "$GroupID" -RefObjectId "$UserID"
        Write-Output "Success" | Out-File ./log.txt
    }
    catch {
        Write-Output "Failure" | Out-File ./log.txt
    }
    Write-Output " " | Out-File ./log.txt
}