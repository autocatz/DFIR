#  //  TargetUser should in the form of email address/AzureAD login//
#  //  
$TargetUser = Read-Host -Prompt 'Email of the user to reset'
#  //  JIC 
#$TargetUser = someone@domain.com

# //Begin Password Generator
# https://activedirectoryfaq.com/2017/08/creating-individual-random-passwords/

#Get Creds
Write-Host "ADMIN CREDS PLEASE"
$UserCredential = Get-Credential


function Get-RandomCharacters($length, $characters) {
    $random = 1..$length | ForEach-Object { Get-Random -Maximum $characters.length }
    $private:ofs=""
    return [String]$characters[$random]
}
 
function Scramble-String([string]$inputString){     
    $characterArray = $inputString.ToCharArray()   
    $scrambledStringArray = $characterArray | Get-Random -Count $characterArray.Length     
    $outputString = -join $scrambledStringArray
    return $outputString 
}

#Change length to modify length 
$password = Get-RandomCharacters -length 5 -characters 'abcdefghiklmnoprstuvwxyz'
$password += Get-RandomCharacters -length 1 -characters 'ABCDEFGHKLMNOPRSTUVWXYZ'
$password += Get-RandomCharacters -length 1 -characters '1234567890'
$password += Get-RandomCharacters -length 1 -characters '!"§$%&/()=?}][{@#*+'
$password = Scramble-String $password
$TargetPassword = $password


# Where the magic happens
Connect-AzureAD

#Disables User
Set-AzureADUser -ObjectID  $TargetUser -AccountEnabled $false

#Breaks Token
Get-AzureADUser -Filter "userPrincipalName eq $TargetUser" |Revoke-AzureADUserAllRefreshToken

#Resets Password
Set-AzureADUserPassword -ObjectId $TargetUser -Password $TargetPassword

#reenables the account
Set-AzureADUser -ObjectID $TargetUser -AccountEnabled $true
 
#$UserCredential = Get-Credential

#Exchange Shell
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection

#Connect to Shell
Import-PSSession $Session -DisableNameChecking

#Move the mailbox/Break Connection
New-MoveRequest -Identity $TargetUser -PrimaryOnly

#Kill Session, Clean up
Remove-PSSession $Session

#final output
Write-host "COMPLETED"
Write-host $TargetUser 
Write-host $TargetPassword
