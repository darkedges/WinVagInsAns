# WinVagInAns
This is a Powershell script for Windows that installs [Babun](http://babun.github.io/), [Vagrant](https://www.vagrantup.com/), [VirtualBox](https://www.virtualbox.org/) and [Ansible](http://www.ansible.com/). It does all the configuration so that you don't have to and once completed will give you a flly working Ansible Provisioner in Vagrant.
##Installation - Chocolatey installed
### Powershell
    iex((new-object net.webclient).DownloadString('https://raw.githubusercontent.com/darkedges/WinVagInsAns/v1.0.1/chocolatey/tools/chocolateyinstall.ps1'))
### Windows CMD
    @powershell -NoProfile -ExecutionPolicy Bypass -Command "iex((new-object net.webclient).DownloadString('https://raw.githubusercontent.com/darkedges/WinVagInsAns/v1.0.1/chocolatey/tools/chocolateyinstall.ps1'))"

##Installation - Chocolatey not installed
This has been tested on Windows 7 Default Powershell V2. Other versions of OS / Powershell may have issues. It requires an environmental WINVAGINSANS to be set for where the software is to be installed.
**Note: This is for a clean install only. Existing installations will not work.**

It performs the following steps
* Installs Babun.
* Installs Vagrant.
* Installs Virtual Box.
* Creates the necessary Environmental Variables.
* Creates the ansible-playbook.bat wrapper in the Vagrant Installation directory.
* Creates the InstallAnsible.sh wrapper for installation and configuration of Ansible in Babun.
* Executes the InstallAnsible.sh wrapper.
* Rebases Babun.

### Powershell
    $env:WINVAGINSANS="d:\vm"; iex((new-object net.webclient).DownloadString('https://raw.githubusercontent.com/darkedges/WinVagInsAns/v1.0.1/WinVagInsAns.ps1'))
### Windows CMD
    @powershell -NoProfile -ExecutionPolicy Bypass -Command "$env:WINVAGINSANS="d:\vm"; iex((new-object net.webclient).DownloadString('https://raw.githubusercontent.com/darkedges/WinVagInsAns/v1.0.1/WinVagInsAns.ps1'))"

## Acknowledgements
The following resources have been helpful in generating this process.
* [Babun DLL Issue](http://stackoverflow.com/questions/9300722/cygwin-error-bash-fork-retry-resource-temporarily-unavailable)
* [Ansible Playbook Wrapper](http://www.azavea.com/blogs/labs/2014/10/running-vagrant-with-ansible-provisioning-on-windows/)
