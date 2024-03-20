#https://stackoverflow.com/questions/4988226/how-do-i-pass-multiple-parameters-into-a-function-in-powershell

Write-Host "Run Create-VM -VMName <name>"
Write-Host " "
Write-Host "Change the variable IP=192.168.0.108 in VMConfig.ps1 to the desired VM IP."
Write-Host "Run Config-VM -VMName <name>"
Write-Host " "
Write-Host "Finally run Join-Domain -VMName <name>"

Function Create-VM
{
    Param
    (
         [Parameter(Mandatory=$true, Position=0)]
         [string] $VMName,
         [Parameter(Mandatory=$false, Position=1)]
         [string] $IP
    )

#Creates the VM from a provided ISO & answer file, names it provided VMName
$isoFilePath = "C:\VM_Stuff_Share\Windows_Server_2019_Datacenter_EVAL_en-us.ISO"
$answerFilePath = "C:\VM_Stuff_Share\autounattend.xml"

New-Item -ItemType Directory -Path C:\Hyper-V_VMs\$VMName

$convertParams = @{
    SourcePath        = $isoFilePath
    SizeBytes         = 100GB
    Edition           = 'Windows Server 2019 Datacenter Evaluation (Desktop Experience)'
    VHDFormat         = 'VHDX'
    VHDPath           = "C:\Hyper-V_VMs\$VMName\$VMName.vhdx"
    DiskLayout        = 'UEFI'
    UnattendPath      = $answerFilePath
}

Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser
. 'C:\VM_Stuff_Share\Convert-WindowsImage (from PS Gallery)\Convert-WindowsImage.ps1'

Convert-WindowsImage @convertParams

New-VM -Name $VMName -Path "C:\Hyper-V_VMs\$VMName" -MemoryStartupBytes 6GB -Generation 2
Connect-VMNetworkAdapter -VMName $VMName -Name "Network Adapter" -SwitchName Testing
$vm = Get-Vm -Name $VMName
$vm | Add-VMHardDiskDrive -Path "C:\Hyper-V_VMs\$VMName\$VMName.vhdx"
$bootOrder = ($vm | Get-VMFirmware).Bootorder
#$bootOrder = ($vm | Get-VMBios).StartupOrder
if ($bootOrder[0].BootType -ne 'Drive') {
    $vm | Set-VMFirmware -FirstBootDevice $vm.HardDrives[0]
    #Set-VMBios $vm -StartupOrder @("IDE", "CD", "Floppy", "LegacyNetworkAdapter")
}
Start-VM -Name $VMName
}#Close the Create-VM function


# --- Config-NIC ---

Function Config-VM
{

Param
    (
         [Parameter(Mandatory=$true, Position=0)]
         [string] $VMName,
         [Parameter(Mandatory=$false, Position=1)]
         [string] $IP
    )

#VM's local admin:
[string]$userName = "Changme\Administrator"
[string]$userPassword = 'P@$$w0rd12'
# Convert to SecureString
[securestring]$secStringPassword = ConvertTo-SecureString $userPassword -AsPlainText -Force
[pscredential]$credObject = New-Object System.Management.Automation.PSCredential ($userName, $secStringPassword)

Invoke-Command -VMName $VMName -FilePath "C:\VM_Stuff_Share\VMConfig.ps1" -Credential $credObject

}#Close the Config-NIC function


# --- Join-Domain ---

Function Join-Domain
{

Param
    (
         [Parameter(Mandatory=$true, Position=0)]
         [string] $VMName,
         [Parameter(Mandatory=$false, Position=1)]
         [string] $IP
    )

#VM's local admin:
[string]$userName = "ChangeMe\Administrator"
[string]$userPassword = 'P@$$w0rd12'
# Convert to SecureString
[securestring]$secStringPassword = ConvertTo-SecureString $userPassword -AsPlainText -Force
[pscredential]$credObject = New-Object System.Management.Automation.PSCredential ($userName, $secStringPassword)

#VM's local admin:
[string]$userName = "$VMName\Administrator"
[string]$userPassword = 'P@$$w0rd12'
# Convert to SecureString
[securestring]$secStringPassword = ConvertTo-SecureString $userPassword -AsPlainText -Force
[pscredential]$credObject2 = New-Object System.Management.Automation.PSCredential ($userName, $secStringPassword)

Invoke-Command -VMName $VMName {Rename-Computer -NewName $using:VMName -LocalCredential $using:credObject -PassThru -restart -force} -Credential $credObject

Write-Host "Waiting for the VM to reboot ..."
Start-Sleep -Seconds 120

#Creates the AD account for the new VM and joins it to test.local
Write-Host "Creating AD account for the VM ..."
New-ADComputer -Name "$VMName" -DisplayName "$VMName" -Path "ou=member servers,dc=test,dc=local"

Invoke-Command -VMName $VMName {$NIC = (Get-NetIPInterface).InterfaceAlias;Set-DNSClientServerAddress -InterfaceAlias $NIC -ServerAddresses ("192.168.0.101", "192.168.0.102", "192.168.0.103", "192.168.0.104", "1.1.1.1", "8.8.8.8")} -Credential $credObject2
Invoke-Command -VMName $VMName {ping test.local} -Credential $credObject2
Invoke-Command -VMName $VMName {$NIC = (Get-NetIPInterface).InterfaceAlias;Set-DNSClientServerAddress -InterfaceAlias $NIC -ServerAddresses ("192.168.0.102", "192.168.0.103", "192.168.0.104", "192.168.0.101", "1.1.1.1", "8.8.8.8")} -Credential $credObject2
Invoke-Command -VMName $VMName {ping test.local} -Credential $credObject2
Invoke-Command -VMName $VMName {netsh advfirewall firewall set rule group="Network Discovery" new enable=Yes} -Credential $credObject2

Write-Host "Waiting for AD to sync ..."
Start-Sleep -Seconds 120

Invoke-Command -VMName $VMName {Add-Computer -DomainName "test.local" -Credential "test\Mishky" -restart -force} -Credential $credObject2
}#Close the Join-Domain Function



# --- Run the whole thing ---

#Just change the IP in VMConfig.ps1 to 192.168.0.115
Function Run-TheWholeThing
{
    Param
    (
         [Parameter(Mandatory=$true, Position=0)]
         [string] $MyVM,
         [Parameter(Mandatory=$false, Position=1)]
         [string] $IP
    )

Create-VM -VMName $MyVM
Write-Host "Waiting for the VM to start ..."
Start-Sleep -Seconds 120

Config-VM -VMName $MyVM
Start-Sleep -Seconds 60

Join-Domain -VMName $MyVM
}