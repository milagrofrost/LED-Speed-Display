# checking to see if the script is being run as admin
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isadmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (!$isadmin) {
    Write-host "You did not open powershell as admin.  Please do so and try again...."
    Read-Host "Press Enter to exit"
    exit
}
else {
    Write-host "You are running this as Admin. Good Job."
    Write-host "Please make sure your LED Speed Display is plugged into your PC"
    Write-host "and that the device is recognized, has a driver installed, "
    Write-host "and is showing up as a serial(COM) port in Device Manager"
    Read-Host "Press Enter once you've done/confirmed these things"
}


# set up our directories.  Give all users permission to edit the folders
$folders = @(
    "$($env:ALLUSERSPROFILE)\LEDSpeedDisplay",
    "c:\LED Speed Display"
)

foreach ($folder in $folders) {
    write-host $folder
    new-item -itemtype directory $folder -Force

    $ACL = Get-ACL -Path $folder
    $AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("BUILTIN\Users","Modify","ContainerInherit,ObjectInherit", "None", "Allow")
    $ACL.SetAccessRule($AccessRule) 
    $ACL | Set-Acl -Path $folder
}

# Copy over crucial files
Copy-Item ".\LED Speed Display - Systray.ps1" "c:\LED Speed Display\"
Copy-Item ".\LED Speed Display.ps1" "c:\LED Speed Display\"

# Setup the systray scheduled task 
$schedTasks = Get-ScheduledTask | select taskname

if ("LED Speed Display Systray" -in $schedTasks.taskname ) {
    Write-host "Systray scheduled task exists"
    $systrayTask = Get-ScheduledTask -TaskName "LED Speed Display Systray"
}
else {
    Write-host "Systray scheduled task does not exist.  Creating..."
    $trigger = New-ScheduledTaskTrigger -AtLogOn
    $action = New-ScheduledTaskAction -execute "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -Argument '-ExecutionPolicy Bypass -file "c:\LED Speed Display\LED Speed Display - Systray.ps1"'
    $settingsSet = New-ScheduledTaskSettingsSet -ExecutionTimeLimit '00:00:00'
    $task = New-ScheduledTask -Trigger $trigger -Action $action -Settings $settingsSet
    Register-ScheduledTask -TaskName "LED Speed Display Systray" -InputObject $task
    Start-ScheduledTask -TaskName "LED Speed Display Systray"
}


# set serial device name
$serialdevices = Get-WMIObject Win32_SerialPort | select Description
if ($serialdevices -eq $null) {
    Write-Host "No Serial Devices found.  Please Investigate and re-run this script when fixed."
    Read-Host "Press Enter to exit"
    exit
}
else {
    Write-host "`nDetected these Serial Devices."
    Write-host "Which one is the MicroController for the LED Speed Display?  "
}
$select = 1
foreach ($serialdevice in $serialdevices) {
    Write-host "["$select"]" $serialdevice.Description
    $select++
}

$whichone = 99

while (($whichone -gt $select) -or ($whichone -lt 1)) {
    Write-host "If the device of the Microcontroller is not here.  Please close out of this script and fix the issue"
    $whichone = Read-Host "`nEnter the number of the serial device of the LED Speed Display and hit enter."
}

$ourserialdevice = ($serialdevices[$whichone - 1]).description
$ourserialdevice > "$($env:ALLUSERSPROFILE)\LEDSpeedDisplay\COM_name"
Write-host "Serial name set in $($env:ALLUSERSPROFILE)\LEDSpeedDisplay\COM_name"









# install Chocolatey package manager so we can then install nssm
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

#install nssm
choco install nssm

# setup nssm for the LED Speed Display system service
nssm install LEDSpeedDisplay C:\WINDOWS\System32\WindowsPowerShell\v1.0\powershell.exe
nssm set LEDSpeedDisplay AppParameters '-ExecutionPolicy Bypass -NoProfile -File ""C:\LED Speed Display\LED Speed Display.ps1""'
nssm set LEDSpeedDisplay AppDirectory C:\WINDOWS\System32\WindowsPowerShell\v1.0
nssm set LEDSpeedDisplay AppExit Default Restart
nssm set LEDSpeedDisplay DisplayName LEDSpeedDisplay
nssm set LEDSpeedDisplay ObjectName LocalSystem
nssm set LEDSpeedDisplay Start SERVICE_AUTO_START
nssm set LEDSpeedDisplay Type SERVICE_WIN32_OWN_PROCESS
nssm start LEDSpeedDisplay

# Setup complete.  check the logs.

Write-host "`n`nSetup is complete.  Hit enter to start looking at the logs to see if we are communicating with the device."
Write-host "or close just close this window and enjoy!"
read-host "Hit Enter to view logs for LED Speed Display (Located at $($env:ALLUSERSPROFILE)\LEDSpeedDisplay\log.txt"
get-content "$($env:ALLUSERSPROFILE)\LEDSpeedDisplay\log.txt" -tail 10 -wait