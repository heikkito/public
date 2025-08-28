# Requires AWS CLI configured + 'aws configure'ä done so you have a working connection to your EC2 machines and snapshots. Dont forget to grant proper rights in IAM. 
#

param( 
    [string]$InstanceId = "i-055xxxxxxx", 
    [string]$Region = "eu-north-1" 
) 

  

Write-Output "QA EC2 manager - restores dirty machines to clean state"

  

# Attempt to stop the instance if it's running 

Write-Output "Attempting to stop instance $InstanceId..." 
aws ec2 stop-instances --instance-ids $InstanceId --region $Region 
aws ec2 wait instance-stopped --instance-ids $InstanceId --region $Region 

  

# Get root volume 

$VolumeId = aws ec2 describe-instances --instance-ids $InstanceId --region $Region ` 
    --query "Reservations[0].Instances[0].BlockDeviceMappings[0].Ebs.VolumeId" ` 
    --output text 
Write-Output "Root volume ID: $VolumeId" 

  

# Step 1: Try latest completed snapshot tied to this volume 

$SnapshotId = aws ec2 describe-snapshots --region $Region ` 
    --filters "Name=volume-id,Values=$VolumeId" "Name=status,Values=completed" ` 
    --query "Snapshots | sort_by(@, &StartTime) | [-1].SnapshotId" ` 
    --output text 

  

if ([string]::IsNullOrWhiteSpace($SnapshotId) -or $SnapshotId -eq "None") { 
    Write-Output "No recent completed snapshot found. Checking for host-specific gold snapshot..." 
    # Step 2: Try host-specific baseline snapshot - Requires tag on the baseline snapshot as below. Do this manually in the snapshot console
    $SnapshotId = aws ec2 describe-snapshots --region $Region ` 
        --filters "Name=tag:Baseline,Values=Gold" "Name=tag:InstanceId,Values=$InstanceId" "Name=status,Values=completed" ` 
        --query "Snapshots | sort_by(@, &StartTime) | [0].SnapshotId" ` 
        --output text 

  

    if ([string]::IsNullOrWhiteSpace($SnapshotId) -or $SnapshotId -eq "None") { 
        Write-Output "No gold snapshot found for this instance. Exiting." 
        exit 1 

    } else { 
        Write-Output "Using host-specific gold snapshot: $SnapshotId" 
    } 

} else { 
    Write-Output "Using latest snapshot: $SnapshotId" 
} 

  

# If snapshots exist proceed on and detach the current root volume 

Write-Output "Detaching current volume" 
aws ec2 detach-volume --volume-id $VolumeId --region $Region 
aws ec2 wait volume-available --volume-ids $VolumeId --region $Region 
Write-Output "Volume detached." 

  

# Get the instance's availability zone 

$AvailabilityZone = aws ec2 describe-instances --instance-ids $InstanceId --region $Region ` 
    --query "Reservations[0].Instances[0].Placement.AvailabilityZone" ` 
    --output text 

  

# Create a new volume from the latest snapshot 

Write-Output "Creating new volume from snapshot $SnapshotId..." 
$NewVolumeId = aws ec2 create-volume ` 
    --snapshot-id $SnapshotId ` 
    --availability-zone $AvailabilityZone ` 
    --volume-type gp3 ` 
    --region $Region ` 
    --query "VolumeId" ` 
    --output text 

aws ec2 wait volume-available --volume-ids $NewVolumeId --region $Region 
Write-Output "New volume created: $NewVolumeId" 

  

# Attach the new volume as the root device 

Write-Output "Attaching new volume..." 
aws ec2 attach-volume ` 
    --volume-id $NewVolumeId ` 
    --instance-id $InstanceId ` 
    --device /dev/sda1 ` 
    --region $Region 
aws ec2 wait volume-in-use --volume-ids $NewVolumeId --region $Region 

Write-Output "New volume attached." 

  

# Start the EC2 instance 

Write-Output "Starting instance..." 
aws ec2 start-instances --instance-ids $InstanceId --region $Region 
aws ec2 wait instance-running --instance-ids $InstanceId --region $Region 
Write-Output "Instance is now running with a snapshotted state" 

  

# --- Windows Update Section (improved) --- 

Write-Output "Waiting 90 seconds for SSM service to start. Please wait and do not close window. " 
Start-Sleep -Seconds 90 

  

Write-Output "Sending Windows Update command via SSM..." 

$commandId = aws ssm send-command ` 
    --document-name "AWS-InstallWindowsUpdates" ` 
    --targets "Key=instanceIds,Values=$InstanceId" ` 
    --region $Region ` 
    --query "Command.CommandId" ` 
    --output text 

  

Write-Output "Windows Update command sent. CommandId: $commandId" 
Write-Output "If there is a visible command ID above then system will attempt update. Max 3 hour timeout if failing" 
 

# Poll until command finishes 

$status = "InProgress" 
$maxChecks = 180   # safety limit (~3 hours if 1 min per check) 
$checkCount = 0 

  

while (($status -eq "InProgress" -or $status -eq "Pending") -and $checkCount -lt $maxChecks) { 

    Start-Sleep -Seconds 60 
    $status = aws ssm list-command-invocations ` 
        --command-id $commandId ` 
        --instance-id $InstanceId ` 
        --region $Region ` 
        --query "CommandInvocations[0].Status" ` 
        --output text 

    $checkCount++ 

    Write-Output "[$checkCount/$maxChecks] Windows Update status: $status" 

} 

  

if ($status -eq "Success") { 

    Write-Output "Windows Updates finished successfully." 
} else { 
    Write-Output "Windows Updates ended with status: $status" 

} 

  

# Force Reboot the instance 

Write-Output "Rebooting instance after updates..." 
aws ec2 reboot-instances --instance-ids $InstanceId --region $Region 
aws ec2 wait instance-status-ok --instance-ids $InstanceId --region $Region 
Write-Output "Instance rebooted successfully." 

  

# Shut down the instance 

Write-Output "Shutting down instance for clean snapshot storing post update" 
aws ec2 stop-instances --instance-ids $InstanceId --region $Region 
aws ec2 wait instance-stopped --instance-ids $InstanceId --region $Region 
Write-Output "Instance shut down." 

  

# Create a new snapshot of the clean and updated system 

Write-Output "Creating new clean snapshot..." 
$FinalSnapshotId = aws ec2 create-snapshot ` 
    --volume-id $NewVolumeId ` 
    --description "Post-update clean state of EC2 instance $InstanceId" ` 
    --region $Region ` 
    --query "SnapshotId" ` 
    --output text 

Write-Output "New snapshot created: $FinalSnapshotId" 

  
Write-Output "Process done. Clean snapshot ready" 
