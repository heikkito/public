<#  Service kickstarter script with logging - If service is not running, it attempts to start it. 
If logfile exists, it moves it to a new archive directory and names it according to date and time
This version skips internal hardcoded declared strings. Instead it reads them from JSON  so make changes in settings.JSON config file
#>

# Reading from JSON config settings
$SettingsObject = Get-Content -Path settings.json | ConvertFrom-Json 
# Some items cannot be referenced as SettingsObject so moving to variables
$actionlog = $SettingsObject.logfile
$temp_path = $SettingsObject.archiveprefix
#Full path from JSON. FIles and folders now created with date format + seconds at end if launched quickly multiple times
$archiveFolder = $temp_path+"_$(get-date -Format 'yyyy_dd_MM_HH_mm_ss')\"

# If the old file exists, move it to the archive and create a new logfile in original folder
if (Get-Item -Path $actionlog -ErrorAction Ignore) 
{
    try {
        ## If the Archive folder does not exist create it
        if (-not([System.IO.File]::Exists("$archivefolder"))) 
            {
            $null = New-Item -ItemType Directory -Path $archiveFolder -ErrorAction STOP
            
            # Logfile already there so making a note in log
            Write-Output $SettingsObject.createdirtext >> $actionlog
            }
        ## Move old logfile to the archive
        Move-Item -Path $actionlog -Destination $archiveFolder -Force -ErrorAction STOP
        
        } 
         catch 
            {
                throw $_.Exception.Message >> $actionlog
            }  
 }
  #No old file found - create a new logfile
 try 
    {
     $null = New-Item -ItemType File -Path $actionlog -Force -ErrorAction Stop
     Write-Output $SettingsObject.filesdone >> $actionlog
    } 
    
    catch 
    {
    Write-Host $_.Exception.Message >> $actionlog
    }

## Read the service from Windows to return a service object
$ServiceInfo = Get-Service -Name $SettingsObject.service

## If the server is not running (not equal to string)
if ($ServiceInfo.Status -ne 'Running') 
    {
		Write-Host 'Service is not in Running state, starting service' >> $actionlog
		$status = Get-Service $service
        Start-Service -InputObject $statis -PassThru | Format-List >> $actionlog
	    ## Display service current state on screen
	    $status.Refresh()
		Write-Host $status.Status
    } 
    else 
    { ## Status not equal to running? Then write to console the service is already running
	    Write-Host 'The service is already running'
    }
