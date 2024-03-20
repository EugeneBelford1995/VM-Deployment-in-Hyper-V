#Cleanup/delete a VM
#Remove-VMHardDiskDrive -VMName TestServer -ControllerType SCSI -ControllerNumber 0 -ControllerLocation 0

#Alt
Stop-VM -Name TestServer -Force
Get-VMHardDiskDrive -VMName TestServer | Remove-VMHardDiskDrive
Remove-VM -Name TestServer -Confirm
Remove-Item C:\VM_Stuff_Share\LocalCredential.xml
Remove-Item C:\Hyper-V_VMs\TestServer -Recurse
Remove-ADComputer "TestServer"

#https://pscustomobject.github.io/powershell/howto/PowerShell-ISE-Clear-Variables/
#Remove-Variable * -ErrorAction SilentlyContinue
#$error.Clear()
#Remove-Module *