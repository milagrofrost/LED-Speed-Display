
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

