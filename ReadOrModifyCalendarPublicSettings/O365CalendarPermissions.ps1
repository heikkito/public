# Before launching you may do to do a Set-ExecutionPolicy Unrestricted manually or with attached .bat file if scirpt execution on this machine is disabled. 


# Function to Show a menu and direct user towards right sub-function - No other functionality and created as function for future expansion
function Show-Menu {
    param (
        [string]$Title = 'O365 - Change Calendar Permissions to make calendars visible to others'
    )
    Clear-Host
    Write-Host "================ $Title ================"
    
    Write-Host "Press 'c' if you expect the target user to have a 'Calendar' in O365 (usually newer users)."
    Write-Host "Press 'k' if you expect the target user to have a 'Kalenteri' in O365 (usually older imported users with OS language se to 'Finnish') "
    Write-Host "Press 'i' to query the permissions state for a user without doing any changes"
    Write-Host "Press 'q' to quit."
}

# ******** MAIN ******
# Setup session and ask for login credentials in firstname.lastname@domain.com format
# WARNING: This part relies on ExchangeOneline module working. 
$UserCredential = Get-Credential
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection
Import-PSSession $Session -DisableNameChecking

# ******* Main menu loop *******
# C selection does the Calendar change overwriting existing access grants if already there. K does same for finnish 'Kalenteri' 
do
 {
    Show-Menu
    $selection = Read-Host "Please make a selection:"
    switch ($selection)
    {
        'C' 
            {
            Write-Host "C as Calendar was chosen"
            $cal = New-Object System.Management.Automation.Host.ChoiceDescription '&Calendar', 'Calendar (English OS)'
            $userinput = Read-Host -Prompt 'Input username in firstanme.lastname format without scandic characters'
            $user = Get-mailbox $userinput
            $cal = $user.alias+”:\Calendar”
            Write-Output "Using $user as target for mailbox manipulation"
            Write-Host 'Start situation:'
            Get-MailboxFolderPermission -Identity $cal
            Add-MailboxFolderPermission -Identity $cal -User clausion.finland.sec -AccessRights Reviewer
            set-MailboxFolderPermission -Identity $cal -User clausion.finland.sec -AccessRights Reviewer
            Write-Host 'End result after changes:'
            Get-MailboxFolderPermission -Identity $cal
            Read-Host "Press any key to return to menu"
            } 
        'K' 
            {
            Write-Host "K as Kalenteri was chosen"
            $cal = New-Object System.Management.Automation.Host.ChoiceDescription '&Kalenteri', 'Kalenteri (Finnish OS)'
            $userinput = Read-Host -Prompt 'Input username in firstanme.lastname format without scandic characters'
            $user = Get-mailbox $userinput
            $cal = $user.alias+”:\Kalenteri”
            Write-Output "Using $user as target for mailbox manipulation"
            Write-Host 'Start situation:'
            Get-MailboxFolderPermission -Identity $cal
            Add-MailboxFolderPermission -Identity $cal -User clausion.finland.sec -AccessRights Reviewer
            set-MailboxFolderPermission -Identity $cal -User clausion.finland.sec -AccessRights Reviewer
            Write-Host 'End result after changes:'
            Get-MailboxFolderPermission -Identity $cal
            Read-Host "Press any key to return to menu"
            } 
        'I' 
            {
            Write-Host "I for Information was chosen - Queries the current state"
            $cal = New-Object System.Management.Automation.Host.ChoiceDescription '&Calendar', 'Calendar (English OS)'
            $userinput = Read-Host -Prompt 'Input username in firstanme.lastname format without scandic characters'
            $user = Get-mailbox $userinput
            $cal = $user.alias+”:\Calendar”
            Write-Output "Using $user as target for mailbox state reading"
            Write-Host 'Current permission state:'
            Get-MailboxFolderPermission -Identity $cal
            Read-Host "Press any key to return to menu"
            } 
    }
 ##   pause
 }
 until ($selection -eq 'q')

#### Ending session
Write-Host "Ending powershell session and exiting"
Remove-PSSession $Session

