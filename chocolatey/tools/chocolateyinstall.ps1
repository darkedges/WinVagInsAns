function Get-RegistryValue($key, $value) {try{(Get-ItemProperty $key -name $value -Ea Stop).$value} catch{}}
function Get-Which($command) {try{(get-command $command -ea stop).Definition | split-path }catch{}}
Write-Host "Install"

#VariablesGet-Which
if ($env:TEMP -eq $null) {
  $env:TEMP = Join-Path $env:SystemDrive 'temp'
}
$ansibleTempDir = Join-Path $env:TEMP "ansible"
$tempDir = Join-Path $ansibleTempDir "ansibleInstall"
$installed = $TRUE;

$vagrantInstallDir = Get-Which "choco"
if (!$vagrantInstallDir) {$installed=$FALSE; Write-Host -ForegroundColor Red "Need to install Chocolocatey: https://chocolatey.org/ for instructions" }

$virtualboxInstallDir = Get-RegistryValue "HKLM:\SOFTWARE\Oracle\VirtualBox" "InstallDir"
if (!$virtualboxInstallDir) {$installed=$FALSE; Write-Host -ForegroundColor Red "Need to install chocolocatey dependency: choco install virtualbox" }
$cygwinInstallDir = Get-RegistryValue "HKLM:\SOFTWARE\Cygwin\setup" "rootdir"
if (!$cygwinInstallDir) {$installed=$FALSE; Write-Host -ForegroundColor Red "Need to install chocolocatey dependency: choco install cygwin" }
$vagrantInstallDir = Get-Which "vagrant"
if (!$vagrantInstallDir) {$installed=$FALSE; Write-Host -ForegroundColor Red "Need to install chocolocatey dependency: choco install vagrant" }
$cyggetInstallDir = Get-Which "cyg-get"
if (!$cyggetInstallDir) {$installed=$FALSE; Write-Host -ForegroundColor Red "Need to install chocolocatey dependency: choco install cyg-get" }

if (!$installed) { exit; }

Write-Host "Installing Cygwin Dependencies"
Start-Process -FilePath "cyg-get"  -ArgumentList "mintty python python-paramiko python-crypto gcc-g++ wget openssh python-setuptools" -Wait -Passthru

$AnsibleWrapperFile = join-path "$CygwinInstallDir" -ChildPath "\tmp\InstallAnsible.sh"

Write-Host "Generating Installation Script"
remove-item "$AnsibleWrapperFile" -ErrorAction silentlycontinue

add-content "$AnsibleWrapperFile" "#!/bin/bash
# Taken from http://www.azavea.com/blogs/labs/2014/10/running-vagrant-with-ansible-provisioning-on-windows/

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

Write-Host "Executing Installation Script"
$bash =  join-path "$CygwinInstallDir" -ChildPath "\bin\bash.exe"
Start-Process -FilePath $bash -ArgumentList "--login -c `"/tmp/InstallAnsible.sh; read blah`"" -Wait -Passthru

# Generate ansible-playbook.bat
Write-Host -ForegroundColor Yellow "Generating ansible-playbook.bat"
$AnsibleWrapperFile = join-path "$vagrantInstallDir" -ChildPath "ansible-playbook.bat"
remove-item "$AnsibleWrapperFile" -ErrorAction silentlycontinue
add-content "$AnsibleWrapperFile" "@echo off
set SH=$CygwinInstallDir\bin\bash.exe
`"%SH%`" -c `"/usr/bin/ansible-playbook %*`""

Write-Host -ForegroundColor Yellow "Ansible configured"