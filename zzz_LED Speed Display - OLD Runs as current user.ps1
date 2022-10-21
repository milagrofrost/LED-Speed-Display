##### Customizable variables

$basepowerplan = "Balanced"
$turbopowerplan = "TURBO"


##### SCRIPT BLOCKS FOR JOBS #####


## Script block for the serial coms with arduino
$scriptBlock_LEDSpeedDisplay = {
    
    # Track the process ID for this job
    $PID >> "$($env:ALLUSERSPROFILE)\LEDSpeedDisplay\processids"

    function serial-connect {
        $port= new-Object System.IO.Ports.SerialPort $ledcom,$baud,None,8,one
        $port.close()
        $port.open()
        return $port
    }

    # checking to see if you've defined the Serial device name that is connected to ESP/Arduino.  This is set via the systray icon, right click on it.
    $timeout = 0
    while (!(Test-Path "$($env:ALLUSERSPROFILE)\LEDSpeedDisplay\COM_name")) { 
        
        Write-Host "Serial Device not yet defined.  Sleeping ...."
        Start-Sleep 10 
        $timeout++
        if ($timeout -gt 120) {
            exit
        }
    
    }
    
    # looking for the Serial device and setting up for the connection
    $serial_dev_name = get-content "$($env:ALLUSERSPROFILE)\LEDSpeedDisplay\COM_name"
    $baud = 115200  # this is statically set because our microcontroller code is set to this
    Write-Host 'Polling for all available COM ports'
    $comports = Get-WMIObject Win32_SerialPort | select DeviceID, Description
    $ledcom = ($comports | where Description -eq $serial_dev_name).DeviceID
    Write-Host 'Attempting to connect to' $serial_dev_name 'on port' $ledcom 'with baud' $baud
    $port = serial-connect



    # checking to see if we've defined a brightness setting before for the LED Display
    if ((test-path "$($env:ALLUSERSPROFILE)\LEDSpeedDisplay\brightness-startup")) {
        $brightness = get-content "$($env:ALLUSERSPROFILE)\LEDSpeedDisplay\brightness-startup"
        $port.WriteLine("b$brightness" + '\n')
        start-sleep 2
    }

    

    # begin running the forever loop.  This keeps the LED  program constantly running
    While ($true) {
         
        # check to see if brightness had been set at any point
        if ((test-path "$($env:ALLUSERSPROFILE)\LEDSpeedDisplay\brightness")) {
            $brightness = get-content "$($env:ALLUSERSPROFILE)\LEDSpeedDisplay\brightness"
            Move-Item "$($env:ALLUSERSPROFILE)\LEDSpeedDisplay\brightness" "$($env:ALLUSERSPROFILE)\LEDSpeedDisplay\brightness-startup" -Force
            $port.WriteLine("b$brightness" + '\n')
            start-sleep 2
        }
        

        # check to see if an exit was prompted at some point
        if ((test-path "$($env:ALLUSERSPROFILE)\LEDSpeedDisplay\exit")) {
            $port.Close()
            exit
        }

        # Attempt to read the lines being outputted by the microcontroller
        try {
            $lines = $port.ReadExisting() -split "`r" | select -last 8
            Write-Host $lines
        }
        catch {
            Write-host("Problem with Serial connection")
            exit
        }

        # Do stuff depending on which buttons are activated
        # these if-blocks will look at the serial output of the microcontroller and determine which statuses are being sent to the PC

        ## TURBO
        ## write files to our ALLUSERSPROFILE directory to indicate TURBO status

        if ($lines -like "*TURBO*") {
            Out-File -FilePath "$($env:ALLUSERSPROFILE)\LEDSpeedDisplay\TURBO" -Force
            remove-item "$($env:ALLUSERSPROFILE)\LEDSpeedDisplay\TURBO-disable" -Force -ErrorAction Ignore
        }
        else {
            remove-item "$($env:ALLUSERSPROFILE)\LEDSpeedDisplay\TURBO" -Force -ErrorAction Ignore
            Out-File -FilePath "$($env:ALLUSERSPROFILE)\LEDSpeedDisplay\TURBO-disable" -Force
        }

        ## LOCK/UNLOCK
        ## write files to our ALLUSERSPROFILE directory to indicate LOCK status

        if ($lines -like "*LOCK*") {
            remove-item "$($env:ALLUSERSPROFILE)\LEDSpeedDisplay\netadapter-unlock" -Force -ErrorAction Ignore
            Out-File -FilePath "$($env:ALLUSERSPROFILE)\LEDSpeedDisplay\netadapter-lock" -Force
        }
        if ($lines -like "*UNLCK*") {
            remove-item "$($env:ALLUSERSPROFILE)\LEDSpeedDisplay\netadapter-lock" -Force -ErrorAction Ignore
            Out-File -FilePath "$($env:ALLUSERSPROFILE)\LEDSpeedDisplay\netadapter-unlock" -Force
        }

        ## CPU has been toggled
        ## find and save the microcontroller the CPU speed
        if ($lines -like "*CPU*") {
            $MaxClockSpeed = (Get-CimInstance CIM_Processor).MaxClockSpeed
            $ProcessorPerformance = (Get-Counter -Counter '\Processor Information(_Total)\% Processor Performance').CounterSamples.CookedValue
            $CurrentClockSpeed = [math]::Round($MaxClockSpeed*($ProcessorPerformance/1000)) 

            Write-Host 'Current Processor Speed: ' -ForegroundColor Yellow -NoNewLine
            Write-Host $CurrentClockSpeed
            $serialinput = $CurrentClockSpeed
        }

        ## GPU has been toggled
        ## find and save the GPU utilization in percentage
        if ($lines -like "*GPU*") {
            $GpuUseTotal = (((Get-Counter "\GPU Engine(*engtype_3D)\Utilization Percentage").CounterSamples | where CookedValue).CookedValue | measure -sum).sum
            Write-Host 'Total GPU Engine Usage: '  -ForegroundColor Yellow -NoNewLine
            Write-host ([math]::Round($GpuUseTotal,0))
            $serialinput = ([math]::Round($GpuUseTotal,0))
        }

        ## Network has been toggled
        ## find and save the network adapter usage in Mbps
        if ($lines -like "*NET*") {
            $Netuse = [math]::Round((Get-CimInstance -Query "Select BytesTotalPersec from Win32_PerfFormattedData_Tcpip_NetworkInterface" | Select-Object BytesTotalPerSec).BytesTotalPerSec / 1Mb * 8)
            Write-Host 'Total Netwok Usage in Mbps: '  -ForegroundColor Yellow -NoNewLine
            Write-Host ([math]::Round($Netuse,0))
            $serialinput = ([math]::Round($Netuse,0))
        }

        
        ## RAM has been toggled
        ## find and save the RAM  utilization in percentage
        if ($lines -like "*RAM*") {
            $ComputerMemory = Get-WmiObject -Class win32_operatingsystem -ErrorAction Stop
            $Memory = ((($ComputerMemory.TotalVisibleMemorySize - $ComputerMemory.FreePhysicalMemory)*100)/ $ComputerMemory.TotalVisibleMemorySize) 
            $RoundMemory = [math]::Round($Memory, 0)
            Write-Host 'Total RAM Usage percent: '  -ForegroundColor Yellow -NoNewLine
            Write-Host ([math]::Round($RoundMemory,0))
            $serialinput = ([math]::Round($RoundMemory,0))
        }

        ## write the requested/saved value to the microcontroller
        try {
            $port.WriteLine([string]$serialinput + '\n')
        }
        catch {
            Write-host("Problem with Serial connection")
            exit
        }

        # give it break. no need to go fast
        Start-Sleep -seconds 1
    }

    # This is never used...
    $port.Close()
} # end of LEDSpeedDisplay scriptblock






## Script block for the systray process

$scriptBlock_systray = {
    
    #Track the process ID for this job
    $PID >> "$($env:ALLUSERSPROFILE)\LEDSpeedDisplay\processids"

    # Force garbage collection just to start slightly lower RAM usage.
    [System.GC]::Collect()

    # Declare assemblies 
    [System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')    | out-null
    [System.Reflection.Assembly]::LoadWithPartialName('presentationframework')   | out-null
    [System.Reflection.Assembly]::LoadWithPartialName('System.Drawing')    | out-null
    [System.Reflection.Assembly]::LoadWithPartialName('WindowsFormsIntegration') | out-null

    # this iconBase64 var is the actual icon in base64 format.  
    $iconBase64  = 'Qk14CAAAAAAAAHYAAAAoAAAAQAAAAEAAAAABAAQAAAAAAAIIAAASCwAAEgsAAAAAAAAAAAAAAAAAACDQYAAh0GEAIM9gACDPYQAg0WAAIc9hAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAyIiIiIiIiIiImMAAAAAAANCIiIiIiIiIiIkMAAAAAABIiIiIiIiIiIiIzAAAAAAMyIiIiIiIiIiIiIzAAAAA0MSIiIiIiIiIiITYwAAAANEMiIiIiIiIiIiI0QwAAACJDEiIiIiIiIiITIkAAAAAyJDIiIiIiIiIiI0IjAAAAIiQxIiIiIiIiITIiQAAAADIiQyIiIiIiIiI0IiMAAAAiIkAAAAAAAAADIiJAAAAAMiIjAAAAAAAAADIiIwAAACIiIAAAAAAAAAMiIkAAAAAyIiMAAAAAAAAAQiIjAAAAIiIgAAAAAAAAAyIiQAAAADIiIwAAAAAAAABCIiMAAAAiIiAAAAAAAAADIiJAAAAAMiIjAAAAAAAAAEIiIwAAACIiIAAAAAAAAAMiIkAAAAAyIiMAAAAAAAAAQiIjAAAAIiIgAAAAAAAAAyIiQAAAADIiIwAAAAAAAABCIiMAAAAiIiAAAAAAAAADIiJAAAAAMiIjAAAAAAAAAEIiIwAAACIiIAAAAAAAAAMiIkAAAAAyIiMAAAAAAAAAQiIjAAAAIiIgAAAAAAAAAyIiQAAAADIiIwAAAAAAAABCIiMAAAAiIiAAAAAAAAADIiJAAAAAMiIjAAAAAAAAAEIiIwAAACIiIAAAAAAAAAMiIkAAAAAyIiMAAAAAAAAAQiIjAAAAIiIgAAAAAAAAAyIiQAAAADIiIwAAAAAAAABCIiMAAAAiIjMzMzMzMzMzEiJAAAAAMiITMzMzMzMzMzEiIwAAACIjMiIiIiIiIiYxIkAAAAAyITQiIiIiIiIiQxIjAAAAVTMiIiIiIiIiImNVMAAAADVTQiIiIiIiIiIkNVMAAAAzMSIiIiIiIiIiEwAAAAAAMzMSIiIiIiIiIiEAAAAAACIjEiIiIiIiIiEwAAAAAAAyJDEiIiIiIiIiEAAAAAAAIiI1VVVVVVVVUwAAAAAAADIiY1VVVVVVVVUAAAAAAAAiIiAAAAAAAAAAAAAAAAAAMiIjAAAAAAAAAAAAAAAAACIiIAAAAAAAAAAAAAAAAAAyIiMAAAAAAAAAAAAAAAAAIiIgAAAAAAAAAAAAAAAAADIiIwAAAAAAAAAAAAAAAAAiIiAAAAAAAAAAAAAAAAAAMiIjAAAAAAAAAAAAAAAAACIiIAAAAAAAAAAAAAAAAAAyIiMAAAAAAAAAAAAAAAAAIiIgAAAAAAAAAAAAAAAAADIiIwAAAAAAAAAAAAAAAAAiIiAAAAAAAAAAAAAAAAAAMiIjAAAAAAAAAAAAAAAAACIiIAAAAAAAAAAAAAAAAAAyIiMAAAAAAAAAAAAAAAAAIiIgAAAAAAAAAAAAAAAAADIiIwAAAAAAAAAAAAAAAAAiIiAAAAAAAAAAAAAAAAAAMiIjAAAAAAAAAAAAAAAAACIiIAAAAAAAAAAAAAAAAAAyIiMAAAAAAAAAAAAAAAAAIiIQAAAAAAAAAAAAAAAAADIiIwAAAAAAAAAAAAAAAAAiITQiIiIiIiIkAAAAAAAAMiITIiIiIiIiIjAAAAAAACITQiIiIiIiIiJAAAAAAAAyITIiIiIiIiIiIwAAAAAAETQiIiIiIiIiIiQAAAAAADETIiIiIiIiIiIiMAAAAAADQiIiIiIiIiIiIjAAAAAAAzIiIiIiIiIiIiIjAAAAAAASIiIiIiIiIiIhMAAAAAAAMSIiIiIiIiIiIhMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA='
    $bitmap = New-Object System.Windows.Media.Imaging.BitmapImage
    $bitmap.BeginInit()
    $bitmap.StreamSource = [System.IO.MemoryStream][System.Convert]::FromBase64String($iconBase64)
    $bitmap.EndInit()
    $bitmap.Freeze()
    $image = [System.Drawing.Bitmap][System.Drawing.Image]::FromStream($bitmap.StreamSource)
    $icon = [System.Drawing.Icon]::FromHandle($image.GetHicon())


    # Create object for the systray 
    $Systray_Tool_Icon = New-Object System.Windows.Forms.NotifyIcon
    # Text displayed when you pass the mouse over the systray icon
    $Systray_Tool_Icon.Text = "LED Speed Display"
    # Systray icon
    $Systray_Tool_Icon.Icon = $icon
    $Systray_Tool_Icon.Visible = $true
 
    # First menu displayed in the Context menu
    $Menu1 = New-Object System.Windows.Forms.MenuItem
    $Menu1.Text = "Brightness"

    # First menu displayed in the Context menu
    $Menu2 = New-Object System.Windows.Forms.MenuItem
    $Menu2.Text = "Serial Device"

    $Menu3 = New-Object System.Windows.Forms.MenuItem
    $Menu3.Text = "Logs"

    $Menu4 = New-Object System.Windows.Forms.MenuItem
    $Menu4.Text = "Net Adapter"
 
    # Fifth menu displayed in the Context menu - This will close the systray tool
    $Menu_Exit = New-Object System.Windows.Forms.MenuItem
    $Menu_Exit.Text = "Exit"
 
    # Create the context menu for all menus above
    ## don't forget this section when adding more menu items
    $contextmenu = New-Object System.Windows.Forms.ContextMenu
    $Systray_Tool_Icon.ContextMenu = $contextmenu
    $Systray_Tool_Icon.contextMenu.MenuItems.AddRange($Menu1)
    $Systray_Tool_Icon.contextMenu.MenuItems.AddRange($Menu2)
    $Systray_Tool_Icon.contextMenu.MenuItems.AddRange($Menu3)
    $Systray_Tool_Icon.contextMenu.MenuItems.AddRange($Menu4)
    $Systray_Tool_Icon.contextMenu.MenuItems.AddRange($Menu_Exit)
 
    ## This menu item prompts user to set LCD brightness.
    $Menu1.add_click({
        
        $form = New-Object System.Windows.Forms.Form
        $form.Text = 'Brightness'
        $form.Size = New-Object System.Drawing.Size(300,200)
        $form.StartPosition = 'CenterScreen'

        $okButton = New-Object System.Windows.Forms.Button
        $okButton.Location = New-Object System.Drawing.Point(75,120)
        $okButton.Size = New-Object System.Drawing.Size(75,23)
        $okButton.Text = 'OK'
        $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $form.AcceptButton = $okButton
        $form.Controls.Add($okButton)

        $cancelButton = New-Object System.Windows.Forms.Button
        $cancelButton.Location = New-Object System.Drawing.Point(150,120)
        $cancelButton.Size = New-Object System.Drawing.Size(75,23)
        $cancelButton.Text = 'Cancel'
        $cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
        $form.CancelButton = $cancelButton
        $form.Controls.Add($cancelButton)

        $label = New-Object System.Windows.Forms.Label
        $label.Location = New-Object System.Drawing.Point(10,20)
        $label.Size = New-Object System.Drawing.Size(280,20)
        $label.Text = 'A number between 0 and 15'
        $form.Controls.Add($label)

        $textBox = New-Object System.Windows.Forms.TextBox
        $textBox.Location = New-Object System.Drawing.Point(10,40)
        $textBox.Size = New-Object System.Drawing.Size(260,20)
        $form.Controls.Add($textBox)

        $form.Topmost = $true

        $form.Add_Shown({$textBox.Select()})
        $result = $form.ShowDialog()

        if ($result -eq [System.Windows.Forms.DialogResult]::OK)
        {
            $x = $textBox.Text
            "$x" > "$($env:ALLUSERSPROFILE)\LEDSpeedDisplay\brightness"
        }
    })
 

    ## This menu item prompts user to select the Serial Device name of the microcontroller
    $Menu2.add_click({
        
        $form = New-Object System.Windows.Forms.Form
        $form.Text = 'Select a Serial Device'
        $form.Size = New-Object System.Drawing.Size(400,300)
        $form.StartPosition = 'CenterScreen'

        $okButton = New-Object System.Windows.Forms.Button
        $okButton.Location = New-Object System.Drawing.Point(75,120)
        $okButton.Size = New-Object System.Drawing.Size(75,23)
        $okButton.Text = 'OK'
        $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $form.AcceptButton = $okButton
        $form.Controls.Add($okButton)

        $cancelButton = New-Object System.Windows.Forms.Button
        $cancelButton.Location = New-Object System.Drawing.Point(150,120)
        $cancelButton.Size = New-Object System.Drawing.Size(75,23)
        $cancelButton.Text = 'Cancel'
        $cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
        $form.CancelButton = $cancelButton
        $form.Controls.Add($cancelButton)

        $label = New-Object System.Windows.Forms.Label
        $label.Location = New-Object System.Drawing.Point(50,20)
        $label.Size = New-Object System.Drawing.Size(350,20)
        $label.Text = 'Select which Serial Device is our LED Speed Display'
        $form.Controls.Add($label)

        $serialdevices = Get-WMIObject Win32_SerialPort | select Description

        $List = New-Object System.Windows.Forms.Combobox 
        $List.Location = New-Object System.Drawing.Size(10,40) 
        $List.Size = New-Object System.Drawing.Size(260,20) 

        # Add the items in the dropdown list
        $serialdevices.Description | ForEach-Object {[void] $List.Items.Add($_)}
        # Select the default value
        $List.SelectedIndex = 0
        $List.location = New-Object System.Drawing.Point(70,50)
        $List.Font = ‘Microsoft Sans Serif,10’
        $form.Controls.Add($List)

        $form.Topmost = $true

        $result = $form.ShowDialog()

        if ($result -eq [System.Windows.Forms.DialogResult]::OK)
        {
            $x = $List.Text
            "$x" > "$($env:ALLUSERSPROFILE)\LEDSpeedDisplay\COM_name"
        }
    })

    ## This menu item prompts user to set the network adapter that will be set to be disabled/enabled, locked/unlocked.
    $Menu4.add_click({
        
        $form = New-Object System.Windows.Forms.Form
        $form.Text = 'Select a Network Adapter'
        $form.Size = New-Object System.Drawing.Size(400,300)
        $form.StartPosition = 'CenterScreen'

        $okButton = New-Object System.Windows.Forms.Button
        $okButton.Location = New-Object System.Drawing.Point(75,120)
        $okButton.Size = New-Object System.Drawing.Size(75,23)
        $okButton.Text = 'OK'
        $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $form.AcceptButton = $okButton
        $form.Controls.Add($okButton)

        $cancelButton = New-Object System.Windows.Forms.Button
        $cancelButton.Location = New-Object System.Drawing.Point(150,120)
        $cancelButton.Size = New-Object System.Drawing.Size(75,23)
        $cancelButton.Text = 'Cancel'
        $cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
        $form.CancelButton = $cancelButton
        $form.Controls.Add($cancelButton)

        $label = New-Object System.Windows.Forms.Label
        $label.Location = New-Object System.Drawing.Point(50,20)
        $label.Size = New-Object System.Drawing.Size(350,20)
        $label.Text = 'Select the network adapter that can be disbaled/enabled'
        $form.Controls.Add($label)

        $networkadapters = Get-NetIPAddress | where { $_.AddressFamily -eq "IPv4" } | select InterfaceAlias, IPAddress | foreach { New-Object PsObject -Property @{ Interface = $_.InterfaceAlias + ", (" + $_.IPAddress + ")" } }

        $List = New-Object System.Windows.Forms.Combobox 
        $List.Location = New-Object System.Drawing.Size(10,40) 
        $List.Size = New-Object System.Drawing.Size(260,20) 

        # Add the items in the dropdown list
        $networkadapters.Interface | ForEach-Object {[void] $List.Items.Add($_)}
        # Select the default value
        $List.SelectedIndex = 0
        $List.location = New-Object System.Drawing.Point(70,50)
        $List.Font = ‘Microsoft Sans Serif,10’
        $form.Controls.Add($List)

        $form.Topmost = $true

        $result = $form.ShowDialog()

        if ($result -eq [System.Windows.Forms.DialogResult]::OK)
        {
            $x = $List.Text
            "$x" > "$($env:ALLUSERSPROFILE)\LEDSpeedDisplay\networkadapter"
        }
    })
 
    # When Exit is clicked, close everything and kill the PowerShell process
    $Menu_Exit.add_Click({
     new-item "$($env:ALLUSERSPROFILE)\LEDSpeedDisplay\exit" -force
     Remove-item "$($env:ALLUSERSPROFILE)\LEDSpeedDisplay\processids"
     $Systray_Tool_Icon.Visible = $false
     $window.Close()
     $window_Config.Close() 
     Stop-Process $pid
     exit
    })
  
    $Menu3.add_Click({
     ii "$($env:ALLUSERSPROFILE)\LEDSpeedDisplay\log.txt"
    })

    # Make PowerShell Disappear
    $windowcode = '[DllImport("user32.dll")] public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);'
    $asyncwindow = Add-Type -MemberDefinition $windowcode -name Win32ShowWindowAsync -namespace Win32Functions -PassThru
    $null = $asyncwindow::ShowWindowAsync((Get-Process -PID $pid).MainWindowHandle, 0)
 

 
    # Create an application context for it to all run within.
    # This helps with responsiveness, especially when clicking Exit.
    $appContext = New-Object System.Windows.Forms.ApplicationContext
    [void][System.Windows.Forms.Application]::Run($appContext)


} # end of systray scriptblock

                                                            #####################
                                                            #                   #
                                                            ####### MAIN ########
                                                            #                   #
                                                            #####################

# Powershell script starts here...... Then calls the script blocks above in separate running jobs

# Make PowerShell Disappear
$windowcode = '[DllImport("user32.dll")] public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);'
$asyncwindow = Add-Type -MemberDefinition $windowcode -name Win32ShowWindowAsync -namespace Win32Functions -PassThru
$null = $asyncwindow::ShowWindowAsync((Get-Process -PID $pid).MainWindowHandle, 0)

# set up our ALLUSERSPROFILE directories
new-item -itemtype directory "$($env:ALLUSERSPROFILE)\LEDSpeedDisplay" -Force
remove-item "$($env:ALLUSERSPROFILE)\LEDSpeedDisplay\exit" -force

# Clean up old/hung processes
if (test-path "$($env:ALLUSERSPROFILE)\LEDSpeedDisplay\processids"){
    $processids = Get-Content "$($env:ALLUSERSPROFILE)\LEDSpeedDisplay\processids"
    foreach ($processid in $processids) {
        Get-Process -id $processid  -ErrorAction Ignore | where { $_.ProcessName -like "powershell" } | stop-process -ErrorAction Ignore
    }
    Remove-item "$($env:ALLUSERSPROFILE)\LEDSpeedDisplay\processids"
}

# Track the process ID for this job
$PID >> "$($env:ALLUSERSPROFILE)\LEDSpeedDisplay\processids"

# start taking notes!  Writing output of this powershell to a log file.
Start-Transcript -path "$($env:ALLUSERSPROFILE)\LEDSpeedDisplay\log.txt" -Force

# begin running the forever loop.  This keeps the main program constantly running
While ($true) {
    
    
    # keep track of the log file.  Make sure it doesn't get too big. Delete and recreate once it gets to 500KB.
    if ((Get-Item "$($env:ALLUSERSPROFILE)\LEDSpeedDisplay\log.txt").length/1KB -gt 500) {
        Stop-Transcript -path "$($env:ALLUSERSPROFILE)\LEDSpeedDisplay\log.txt" -Force
        remove-item "$($env:ALLUSERSPROFILE)\LEDSpeedDisplay\log.txt" -force
        Start-Transcript -path "$($env:ALLUSERSPROFILE)\LEDSpeedDisplay\log.txt" -Force
    }

    # our jobs/scriptblocks that we want run from this parent script.  
    $subscript_names =  @("LEDSpeedDisplay", "systray") 

    # the systray job/script is capable of creating an exit file (on exit) that will alert this parent script that it should exit as well.
    if (test-path "$($env:ALLUSERSPROFILE)\LEDSpeedDisplay\exit") {
        foreach ($job in (Get-Job | where { $_.State -eq "Running" })) {
            stop-job $job 

        }
        exit
    }
    

    # creating jobs from the defined scriptblocks above.  Contantly checking on their status.  Recreate them if they exited unexpectedly. 
    # kill if more than two running for some reason.
    # continually adopting running jobs 
    foreach ($jobname in $subscript_names ) {
        
        $scriptblock = (Get-Variable  "scriptblock_$jobname").Value

        try {
            #Write-Host "Finding already running $jobname Jobs"
            $jobs = get-job -name $jobname | where {$_.state -eq "Running"}
            # in the rare chance that more than one job is running
            if ($jobs.Count -gt 1) {
                Write-host "More than one running $jobname job! Gotta stop em. Something ain't right..."
                foreach ($job in $jobs) {
                    write-host "Stopping " $job.id
                    Stop-Job $job
                }
            }
            if ($jobs.Count -eq 1) {
                # Continuous normal operation.  Constantly checking in job and "adopting it"
                #Write-Host "One job already running. Adopting it..."
                $thejob = $jobs
            }
            # if job isn't running, start it up
            if (($jobs.Count -eq 0) -and -not (test-path "$($env:ALLUSERSPROFILE)\LEDSpeedDisplay\exit")) {
                Write-host "No $jobname jobs running. Starting one now..."
                $thejob = start-job -name $jobname -ScriptBlock $scriptBlock
            }
        }
        catch {
            # This situation is where there are no jobs running. start them up!
            Write-host "No $jobname jobs running. Starting one now..."
            $thejob = start-job -name $jobname -ScriptBlock $scriptBlock
        }
        
        Receive-Job $thejob


        start-sleep -Seconds 1 
    }

    ### Button actions

    ## What TURBO do

    # not a good situation when these two files exists side by side.  deleting both.
    if ((test-path ("$($env:ALLUSERSPROFILE)\LEDSpeedDisplay\TURBO")) -and (test-path ("$($env:ALLUSERSPROFILE)\LEDSpeedDisplay\TURBO-disable"))) {
        remove-item "$($env:ALLUSERSPROFILE)\LEDSpeedDisplay\TURBO" -Force -ErrorAction Ignore
        remove-item "$($env:ALLUSERSPROFILE)\LEDSpeedDisplay\TURBO-disable" -Force -ErrorAction Ignore
    }

    # see if we got any messages(files) to indicate enable or disable TURBO.  Files are created/deleted by the "LEDSpeedDisplay" scriptblock
    if ((test-path ("$($env:ALLUSERSPROFILE)\LEDSpeedDisplay\TURBO")) -or (test-path ("$($env:ALLUSERSPROFILE)\LEDSpeedDisplay\TURBO-disable"))) {

        if (test-path "$($env:ALLUSERSPROFILE)\LEDSpeedDisplay\TURBO") {
            $planname = $turbopowerplan
        }

        if (test-path "$($env:ALLUSERSPROFILE)\LEDSpeedDisplay\TURBO-disable") {
            $planname = $basepowerplan
        }

        # See if we already defined power plans
        # TURBO Plan needs to be made manually before this portion can run successfully 
        $powerplans = gwmi -NS root\cimv2\power -Class win32_PowerPlan 
        if ( ($powerplans | select -ExpandProperty ElementName) -notcontains $planname) {
            Write-Host "No Power Plan Named $planname.  No $planname for you..."
        }
        else {
            # checking to see if the plan is enabled.  If not, enable it.
            $planID = ($powerplans | where ElementName -eq $planname).InstanceID -replace "Microsoft:PowerPlan\\{" -replace "}"
            if (($powerplans | where ElementName -eq $planname).IsActive -ne "True" ) {
                Write-Host "Engaging $planname"
                powercfg /setactive $planID
            }
            else {
                Write-Host "$planname Already Activated"
            }
        }
    }


    # Network disabling/locking feature

    if ((test-path ("$($env:ALLUSERSPROFILE)\LEDSpeedDisplay\netadapter-lock")) -and (test-path ("$($env:ALLUSERSPROFILE)\LEDSpeedDisplay\networkadapter-unlock"))) {
        remove-item "$($env:ALLUSERSPROFILE)\LEDSpeedDisplay\netadapter-unlock" -Force -ErrorAction Ignore
        remove-item "$($env:ALLUSERSPROFILE)\LEDSpeedDisplay\netadapter-lock" -Force -ErrorAction Ignore
    }

    # if the networkadapter name is not defined, this portion will be skipped.  
    if ( test-path "$($env:ALLUSERSPROFILE)\LEDSpeedDisplay\networkadapter") {

        $netadaptername = ((Get-content "$($env:ALLUSERSPROFILE)\LEDSpeedDisplay\networkadapter") -split ",")[0]
        
        # disable the adapter if in LOCK mode
        if ( test-path "$($env:ALLUSERSPROFILE)\LEDSpeedDisplay\netadapter-lock") {
            $netadaptername = ((get-content "$($env:ALLUSERSPROFILE)\LEDSpeedDisplay\networkadapter") -split ",")[0]
            $netstatus = get-netadapter -name $netadaptername | select -expand Status
            if ( $netstatus -ne "Disabled" ) { 
                start powershell -ArgumentList "-noexit & Set-Variable -name 'Confirmpreference' -Value 'None' ; Disable-NetAdapter -Name 'networkadapter'; exit".replace("networkadapter", $netadaptername) -WindowStyle hidden
            }
        }
        # enable the adapter if in UNLCK mode
        if ( test-path "$($env:ALLUSERSPROFILE)\LEDSpeedDisplay\netadapter-unlock") {
            
            Enable-NetAdapter -Name $netadaptername
            
        }
    }
   
} #end of main loop
