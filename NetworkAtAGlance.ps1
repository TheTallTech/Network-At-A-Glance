#Initialization Section
Clear-Host
$VirtualTerminalStatus = $Host.UI.SupportsVirtualTerminal
$PowershellVersion = (Get-Host | Select-Object Version).Version
$esc = [char]27

$host.UI.RawUI.WindowTitle = "Network-At-A-Glance"

Write-Host "`n`n-------------------------`n   Network-At-A-Glance `n-------------------------" -ForegroundColor White
                                              
Write-Host "`n`nThis script was written and tested in Powershell Version 5.1.19041.1645" -ForegroundColor Yellow
if($PowershellVersion -lt "5.1.19041.1645") {
  Write-Host "Your Powershell Version is $PowershellVersion (This script may not work as intended.)" -ForegroundColor Red
}else{
  Write-Host "Your Powershell Version is $PowershellVersion" -ForegroundColor Green
}

Write-Host "This script must have Virtual Terminal enabled to work properly." -ForegroundColor Yellow
if($VirtualTerminalStatus -eq $false) {
  Write-Host "Current status of Virtual Terminal: $VirtualTerminalStatus (This script will not display correctly)" -ForegroundColor Red
}else{
  Write-Host "Current status of Virtual Terminal: $VirtualTerminalStatus" -ForegroundColor Green
}

Write-Host "`nPlease make any adjustments to the Powershell window `nthis script is currently running in, then press any key to continue" -ForegroundColor Yellow
Read-Host " "
Write-Host "Initializing script...   This may take awhile depending on how many devices are in CSV" -ForegroundColor Yellow

$LongestLength = 1

if (-Not(Test-Path "$PSScriptRoot\NetworkDevices.csv")) {
  Write-Host "Error: You're missing the NetworkDevices.csv file. Please see the NetworkDevices-Sample.csv"
  exit 1
}

$DevicesCSV = Import-Csv "$PSScriptRoot\NetworkDevices.csv"
$FullDeviceDetailedList = @()

foreach($Device in $DevicesCSV) {
  # Determine longest "DeviceName:DeviceIP" character length
  $CombinedString = $Device.'Displayed Name'.Trim()
  if($LongestLength -lt $CombinedString.Length) {
    $LongestLength = $CombinedString.Length
  }

  #Add device online status to object and set to false
  $FullDeviceDetails = @{
    DeviceName = $Device.'Displayed Name'.Trim()
    DeviceIP = $Device.'IP Address'.Trim()
    DeviceOnline = $false
    DeviceJobID = $CombinedString + (Get-Date -Format "yyyyMMddTHHmmssffff").ToString()
  }
  $FullDeviceDetailedList += New-Object psobject -Property $FullDeviceDetails
}



#Loop Section
DO {
  #Run ping tests in parallel
  foreach($MonitoredDevice in $FullDeviceDetailedList) {
    Start-Job -ScriptBlock {Test-Connection $input -Quiet} -InputObject $MonitoredDevice.DeviceIP -Name $MonitoredDevice.DeviceJobID | Out-Null
  }

  #Keep waiting 10 seconds until all jobs are no longer running
  DO {
    Start-Sleep -Seconds 10
    $AllJobsNotRunning = $true
    foreach($Dev in $FullDeviceDetailedList) {
      $JobStatus = Get-Job -Name $Dev.DeviceJobID
      if($JobStatus.State -eq "Running") {
        $AllJobsNotRunning = $false
        break
      }
    }
  } While ($AllJobsNotRunning -eq $false)

  #When all jobs are done, save data and delete job
  foreach($Dev2 in $FullDeviceDetailedList) {
    $Dev2.DeviceOnline = Receive-Job -Name $Dev2.DeviceJobID -AutoRemoveJob -Wait
  }

  #Display Updated Info based on window sizing
  #Display timestamp of update info for troubleshooting stuck issues
  Clear-Host
  $CurrentWindowWidth = $Host.UI.RawUI.WindowSize.Width
  $CurrentWindowHeight = $Host.UI.RawUI.WindowSize.Height
  $DisplayNameWith2SpacesAndSlash = $LongestLength + 3
  $NumberOfDevicesPerLine = [int][Math]::Floor(($CurrentWindowWidth - 1) / $DisplayNameWith2SpacesAndSlash)
  $NumberOfLinesOfDevices = $CurrentWindowHeight - 4

  #Check to make sure window width is longer than device name, ie greater than 0
  if($NumberOfDevicesPerLine -lt 1) {
    Write-Host "Window width too narrow to display "
    Write-Host "device information, please increase "
    Write-Host "the window width and wait for script "
    Write-Host "to update."
    break
  }
  
  $screenOutputBuffer = ""

  #Write first line to screen
  for($i=1;$i -le $CurrentWindowWidth;$i++) {
    if($i -eq $CurrentWindowWidth) {
      $screenOutputBuffer += "+`n"
    }elseif($i -eq 1){
      $screenOutputBuffer += "+"
    }else{
      $screenOutputBuffer += "-"
    }
  }

  #Build and write middle content
  $CurrentArrayObject = 0
  $HowManyDevicesCurrentlyOnThisLine = 0

  for($row = 1; $row -le $NumberOfLinesOfDevices; $row++) {
    $rowLocation = 1
    $numDevicesSoFar = 0
    while($rowLocation -lt $CurrentWindowWidth) {
      if($rowLocation -eq 1) { #If start of line, then print first '|'
        $screenOutputBuffer += "|"
        $rowLocation++

      }elseif($numDevicesSoFar -lt $NumberOfDevicesPerLine) { #Else if current number of devices printed is not equal to the max number of devices for this line, then print device
        $screenOutputBuffer += " "
        $rowLocation++

        if($CurrentArrayObject -lt $FullDeviceDetailedList.Length) { #If there is a device to print, then print
          $CurrentDeviceName = $FullDeviceDetailedList[$CurrentArrayObject].DeviceName
          $DeviceNameLength = $CurrentDeviceName.Length

          if($FullDeviceDetailedList[$CurrentArrayObject].DeviceOnline -eq $true) {
            for($spacing = 1; $spacing -le ($LongestLength - $DeviceNameLength); $spacing++) {
              $CurrentDeviceName += " "
            }
            # Black Text;Bright Green Background "$esc[30;102m$('$StringToOutput')$esc[0m"
            $screenOutputBuffer += "$esc[30;102m$($CurrentDeviceName)$esc[0m"
            $rowLocation += $CurrentDeviceName.Length
          }else{
            for($spacing = 1; $spacing -le ($LongestLength - $DeviceNameLength); $spacing++) {
              $CurrentDeviceName += " "
            }
            # Black Text;Bright Red Background "$esc[30;101m$('$StringToOutput')$esc[0m"
            $screenOutputBuffer += "$esc[30;101m$($CurrentDeviceName)$esc[0m"
            $rowLocation += $CurrentDeviceName.Length
          }

        }else{ #If there are no more devices to print, then print spaces
          $CurrentDeviceName = ""
          for($spacing = 1; $spacing -le $LongestLength; $spacing++) {
            $CurrentDeviceName += " "
          }
          $screenOutputBuffer += "$CurrentDeviceName"
          $rowLocation += $CurrentDeviceName.Length
        }
        
        $screenOutputBuffer += " |"
        $rowLocation += 2
        $CurrentArrayObject++
        $numDevicesSoFar++

      }
      if($numDevicesSoFar -ge $NumberOfDevicesPerLine) { #If current number of devices printed is equal to the max number of devices for this line, then print remaining spaces and end of line break
        $remainingSpaces = $CurrentWindowWidth - $rowLocation - 1
        $screenOutputBuffer += " "
        $rowLocation++
        for($spaceCount = 1; $spaceCount -le $remainingSpaces; $spaceCount++) {
          $screenOutputBuffer += " "
          $rowLocation++
        }
        $screenOutputBuffer += "|`n"
        $rowLocation++
      }
    }
  }

  #Write second to last line to screen
  for($i=1;$i -le $CurrentWindowWidth;$i++) {
    if($i -eq $CurrentWindowWidth) {
      $screenOutputBuffer += "+`n"
    }elseif($i -eq 1){
      $screenOutputBuffer += "+"
    }else{
      $screenOutputBuffer += "-"
    }
  }

  #Write timestamp to bottom of screen
  $timestamp = Get-Date
  $screenOutputBuffer += "Last monitor refresh: $timestamp --> Press Ctrl + C to stop script"

  #Write screen buffer to screen
  Write-Host $screenOutputBuffer

  Start-Sleep -Seconds 30

} While ($true) # Run program until manually stopped by user