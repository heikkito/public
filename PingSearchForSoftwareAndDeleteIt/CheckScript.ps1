

## FUNCTION - test if host is responding to ping check ##
Function Test-Host {
  [CmdletBinding()]
  Param ([Parameter(Mandatory = $True, ValueFromPipeline = $True)]
    [string[]]$ADobjectNameName
  )
  Begin { }
  Process {
    IF ((Test-Connection -ComputerName $ADobjectNameName -Count 2 -BufferSize 1 -Quiet) -eq $true) { Write-Output $_ }
  }
  END { }
}

## FUNCTON - test if path exists to target program ##

Function Test-AppInstalled {
  [CmdletBinding()]
  Param ([Parameter(Mandatory = $True, ValueFromPipeline = $True)]
    [string[]]$ADobjectNameName
  )
  Begin { }
  Process {
    IF ((Test-Path "\\$ADobjectNameName\c$\Program Files\Miradore\Client") -eq $true) { Write-Output $_ }
  }
  End { }
}



####################### MAIN CODE ###########################################################################
#### Preparation 1: Fill in proper OU below. If you dont know fire this command separately: "Get-ADOrganizationalUnit -Filter 'Name -like "*"' | Format-Table Name, DistinguishedName -A" 
#### Preparation 2: Fill in proper program path above in Test-Path function 
#### Preparation 3: Fill in keyword inside the '' brackets to be used when uninstalling software in Get-Package line below 
#### Preparation 4: You are running this with a proper admin account? not just 'Run as Admin'.  shift-right click on powershell .exe of choice 'Run as different user'

#Get list of computers to uninstall software on
Write-Output ("`n",'This script will search for computers, check if they are online, check for installed software and uninstall. There are pauses between steps that allows stopping the script.')
$Desktops = Get-ADComputer -SearchBase 'OU=Workstations,OU=Clausion,DC=ad,DC=clausion,DC=com' -Filter * | select -ExpandProperty name
Write-Output ("`n",'Getting list of computers that exist on AD...  ')
Write-Output ('Objects found on AD:  ',"`n")
Write-Output $Desktops
Read-Host -Prompt "Press any key to continue or CTRL+C to quit" 


#Get list of computers available on the network that will be checked
Write-Output ("`n",'Ping checking hosts to determine which machines are online. Please standby as this can take considerable time...  ')
$OnlineDesktops = $Desktops | Test-Host
Write-Output ('Machines that responded to ping check:  ',"`n")
Write-Output $OnlineDesktops
Read-Host -Prompt "Press any key to continue or CTRL+C to quit" 

#Locate which machines has target software installed
$Targets = $OnlineDesktops | Test-AppInstalled
Write-Output ('Target software path found on these machines:  ',"`n")
Write-Output $Targets

Write-Output ('Now the software will be uninstalled from the listed hosts',"`n")
Read-Host -Prompt "Press any key to continue or CTRL+C to quit" 

#Uninstall target software
Write-Output ('Please enter credential to run the script with on remote machines. Format domain\username',"`n")
$RemoteCred = Read-Host -Prompt 'Input the user name'
Invoke-Command -ComputerName $Targets -Credential $RemoteCred -ScriptBlock {
  Get-Package | where { $_.name -eq 'Miradore' } | Uninstall-Package -WhatIf
}