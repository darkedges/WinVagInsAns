# ==============================================================================
#
# Nicholas Irving Copyright 2014 - Present - Released under the Apache 2.0 License
#
# Copyright 2007-2008 The Apache Software Foundation.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not use
# this file except in compliance with the License. You may obtain a copy of the
# License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software distributed
# under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
# CONDITIONS OF ANY KIND, either express or implied. See the License for the
# specific language governing permissions and limitations under the License.
# ==============================================================================
#Inspired by https://chocolatey.org/install.ps1

Function Add-EnvironmentVariable() {
    [Cmdletbinding()]
    param
    (
        [parameter(Mandatory=$True,ValueFromPipeline=$True,Position=0)]
        [String[]]$key,
        [parameter(Mandatory=$True,ValueFromPipeline=$True,Position=1)]
        [String[]]$value,
        [parameter(Mandatory=$True,ValueFromPipeline=$True,Position=2)]
        [ValidateSet("User","Machine","Process")] 
        [String[]]$type
    )
    [Environment]::SetEnvironmentVariable($key, $value, $type)
}

Function Add-Path() {
    [Cmdletbinding()]
    param
    (
        [parameter(Mandatory=$True,ValueFromPipeline=$True,Position=0)]
        [String[]]$AddedFolder
    )
  # Get the current search path from the environment keys in the registry.
  $OldPath=(Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH).Path

  # See if a new folder has been supplied.
  IF (!$AddedFolder){ Return 'No Folder Supplied. $ENV:PATH Unchanged'}

  # See if the new folder exists on the file system.
  IF (!(TEST-PATH $AddedFolder)){ Return 'Folder Does not Exist, Cannot be added to $ENV:PATH' }

  # See if the new Folder is already in the path.
  IF ($OldPath | Select-String -SimpleMatch $AddedFolder){ Return 'Folder already within $ENV:PATH' }

  # Set the New Path
  $NewPath=$OldPath+';'+$AddedFolder
  Set-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH -Value $newPath

  # Show our results back to the world
  Return $NewPath
}

function Get-Installed
{
    [CmdletBinding()]
    [OutputType([int])]
    Param
    (
        # Source directory or file
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string]
        $DisplayName
    )

    $INSTALLED = $FALSE;

    # paths: x86 and x64 registry keys are different
    if ([IntPtr]::Size -eq 4) {
        $path = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
    }
    else {
        $path = @(
            'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
            'HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
        )
    }
    
    # get all data
    $blah = Get-ItemProperty $path | .{process{ if ($_.DisplayName -and $_.UninstallString) { $_ } }} | Select-Object DisplayName | Sort-Object DisplayName | select DisplayName | where {$_.DisplayName -match $DisplayName}

    if ( $blah -ne $null) {
        $INSTALLED = $TRUE;
    }
    return $INSTALLED;
}

function DownloadFileWithStatus($url, $targetFile)

{
   $uri = New-Object "System.Uri" "$url"
   $request = [System.Net.HttpWebRequest]::Create($uri)
   $request.set_Timeout(15000) #15 second timeout
   $response = $request.GetResponse()
   $totalLength = [System.Math]::Floor($response.get_ContentLength()/1024)
   $responseStream = $response.GetResponseStream()
   $targetStream = New-Object -TypeName System.IO.FileStream -ArgumentList $targetFile, Create
   $buffer = new-object byte[] 10KB
   $count = $responseStream.Read($buffer,0,$buffer.length)
   $downloadedBytes = $count
   while ($count -gt 0)
   {
       $targetStream.Write($buffer, 0, $count)
       $count = $responseStream.Read($buffer,0,$buffer.length)
       $downloadedBytes = $downloadedBytes + $count
       Write-Progress -activity "Downloading file '$url'" -status "Downloaded ($([System.Math]::Floor($downloadedBytes/1024))K of $($totalLength)K): " -PercentComplete ((([System.Math]::Floor($downloadedBytes/1024)) / $totalLength)  * 100)
   }
   Write-Progress -activity "Finished downloading file '$($url.split('/') | Select -Last 1)'" -status "Downloaded"
   $targetStream.Flush()
   $targetStream.Close()
   $targetStream.Dispose()
   $responseStream.Dispose()
}


function Download-File {
param (
  [string]$urlx86,
  [string]$urlx64,
  [string]$file
 )
  $url = ""
  $is64bit = [Environment]::Is64BitProcess
  if ($urlx86 -And $urlx64) {
    # We have both configured, trying to figure out which one to download.  
    if ($is64bit) {
      $url = $urlx64
    } else {
      $url = $urlx86
    }
  } else {
    # Need to figure out which one is required.
    $url = $urlx86;
    if (!$url) {
       $url = $urlx64;
    }
    if (!$url) {
      Write-Host -Foregroundcolor Red "No download file specified!"
        exit(1);
    }
    
  }
  Write-Host "Detected '$url' for download"
  
  if ($env:TEMP -eq $null) {
    $env:TEMP = Join-Path $env:SystemDrive 'temp'
  }
  
  
  $tempDir = Join-Path $env:TEMP "vagrant"
    
  if (![System.IO.Directory]::Exists($tempDir)) {[System.IO.Directory]::CreateDirectory($tempDir)}
  $dlFile = Join-Path $tempDir $file
  
  if (!(Test-Path -Path $dlFile)) {
    Write-Host "Downloading $url to $dlFile"
    DownloadFileWithStatus $url $dlFile
  }
  return $dlFile
}

# Check that the Environment Variable WINVAGINSANS has been set
$installDir =  $env:WINVAGINSANS
if (!$installDir) { 
  Write-Host -ForegroundColor Red "Environment Variable 'WINVAGINSANS' not set. Exiting."
  exit 1;
} 

# Load Configuration from JSON File
$babun = Download-File "http://projects.reficio.org/babun/download" "" "babun.zip"
$vagrant = Download-File "https://dl.bintray.com/mitchellh/vagrant/vagrant_1.7.2.msi" "" "vagrant.msi"
$vbox = Download-File "http://download.virtualbox.org/virtualbox/4.3.28/VirtualBox-4.3.28-100309-Win.exe" "" "vbox.exe"
$7za = Download-File "https://chocolatey.org/7za.exe" "" "7za.exe"
$tmpDir = [System.IO.Path]::GetDirectoryName($babun) 
$babunInstallDir = Join-Path $installDir "babun"
$vagrantInstallDir = Join-Path $installDir "vagrant"
$vboxInstallDir = Join-Path $installDir "VirtualBox"

# Install Babun
# Need to figure out how to stop Babun from running the shell when finished

if (![System.IO.Directory]::Exists($babunInstallDir)) {
  Write-Host -ForegroundColor Yellow "Installing Babun"
  Write-Host "Extracting $babun to $tmpDir..."
  Start-Process "$7za" -ArgumentList "x -o`"$tmpDir`" -y `"$babun`"" -Wait -NoNewWindow
  Write-Host "Finding Babun install.bat"
  $babunInstallerObj = Get-ChildItem -Path $tmpDir -Filter install.bat -Recurse
  $babunInstaller =  Join-Path $babunInstallerObj.Directory $babunInstallerObj.Name
  Write-Host "Installing Babun"
  Start-Process $babunInstaller -ArgumentList "/t $babunInstallDir" -Wait  
  Write-Host -ForegroundColor Yellow "Babun Installed"
} else {
  Write-Host "Babun already installed"
}

#Install Vagrant
if (! (Get-Installed "Vagrant")) {
  if (![System.IO.Directory]::Exists($vagrantInstallDir)) {
    Write-Host -ForegroundColor Yellow "Installing Vagrant"
    Start-Process -FilePath "msiexec.exe" -ArgumentList "/qn /i $vagrant VAGRANTAPPDIR=$vagrantInstallDir" -Wait -Passthru
    Write-Host -ForegroundColor Yellow "Vagrant Installed"
  } else {
    Write-Host -ForegroundColor Red "Vagrant Directory exists"
    Write-Host -ForegroundColor Red "Please remove '$vagrantInstallDir' before trying again."
    exit 1
  }
} else {
  Write-Host "Vagrant already installed"
}

#Install Virtual Box
if (! (Get-Installed "Oracle VM VirtualBox.*")) {
  if (![System.IO.Directory]::Exists($babunInstallDir)) {
    Write-Host -ForegroundColor Yellow "Installing VirtualBox"
    Start-Process -FilePath "$vbox" -ArgumentList "--silent --msiparams REBOOT=ReallySuppress INSTALLDIR=d:\vm\VirtualBox"  -Wait -Passthru
    Write-Host -ForegroundColor Yellow "VirtualBox Installed"
  } else {
    Write-Host -ForegroundColor Red "VirtualBox Directory exists"
    Write-Host -ForegroundColor Red "Please remove '$vboxInstallDir' before trying again."
    exit 1
  }
} else {
  Write-Host "VirtualBox already installed"
}

# Add environment variables
Write-Host -ForegroundColor Yellow "Adding Environmental Variables"
Add-EnvironmentVariable -key "VAGRANT_HOME" -value "$vagrantInstallDir" -type User
Add-Path -AddedFolder $vboxInstallDir

# Generate ansible-playbook.bat
Write-Host -ForegroundColor Yellow "Generating ansible-playbook.bat"
$AnsibleWrapperFile = join-path "$vagrantInstallDir" -ChildPath "ansible-playbook.bat"
remove-item "$AnsibleWrapperFile" -ErrorAction silentlycontinue
add-content "$AnsibleWrapperFile" "@echo off
set SH=$babunInstallDir\.babun\cygwin\bin\bash.exe
`"%SH%`" -c `"/usr/bin/ansible-playbook %*`""

# Install Ansible
Write-Host -ForegroundColor Yellow "Installing Ansible in Babun"
$AnsibleWrapperFile = join-path "$babunInstallDir" -ChildPath ".babun\cygwin\tmp\InstallAnsible.sh"
Write-Host "Generating Installation Script"
remove-item "$AnsibleWrapperFile" -ErrorAction silentlycontinue
add-content "$AnsibleWrapperFile" "#!/bin/bash
# Taken from http://www.azavea.com/blogs/labs/2014/10/running-vagrant-with-ansible-provisioning-on-windows/

# First install the pre-requsite packages via pact
pact install python python-paramiko python-crypto gcc-g++ wget openssh python-setuptools

#Install PIP
python /usr/lib/python2.7/site-packages/easy_install.py pip

#Install Ansible
pip install ansible

# Remove issue that stops Windows SSH working
sed '/if private_key_file:/,/% (private_key_file,))/d' -i /usr/lib/python2.7/site-packages/ansible/runner/connection.py

# Echo create ansible configuration file
cat << EOF > ~/.ansible.cfg
[ssh_connection]
control_path = /tmp
EOF

exit
"
Write-Host "Converting to Unix Format"
[string]::Join( "`n", (gc $AnsibleWrapperFile)) | sc $AnsibleWrapperFile


# Pact for reasons unknown cannot find the correct database and fails.
Write-Host "Executing Installation Script"
$bash =  join-path "$babunInstallDir" -ChildPath ".babun\cygwin\bin\bash.exe"
Start-Process -FilePath $bash -ArgumentList "--login -c `"CYGWIN_VERSION=x86 /tmp/InstallAnsible.sh; read blah`"" -Wait -Passthru
Write-Host -ForegroundColor Yellow "Ansible configured"

# Rebasing Babun to resolve some issues with DLLs
Write-Host "Rebasing Babun"
$rebaseCmd =  Join-Path $babunInstallDir ".babun\cygwin\bin\dash.exe"
Write-Host $rebaseCmd
Start-Process $rebaseCmd -ArgumentList "-c '/bin/rebaseall -v> /tmp/b; exit'" -Wait -Passthru  -RedirectStandardOutput c:\stdout.txt -RedirectStandardError c:\stderr.txt
