$Gateway = "192.168.0.1"
$NIC = (Get-NetAdapter).InterfaceAlias
$IP = "192.168.0.108"

#Disable IPv6
Disable-NetAdapterBinding -InterfaceAlias $NIC -ComponentID ms_tcpip6

#Disable NetBIOS
$regkey = "HKLM:SYSTEM\CurrentControlSet\services\NetBT\Parameters\Interfaces"
Get-ChildItem $regkey | ForEach {Set-ItemProperty -Path "$regkey\$($_.pschildname)" -Name NetbiosOptions -Value 2 -Verbose}

#Set IPv4 address, gateway, & DNS servers
New-NetIPAddress -InterfaceAlias $NIC -AddressFamily IPv4 -IPAddress $IP -PrefixLength 24 -DefaultGateway $Gateway
Set-DNSClientServerAddress -InterfaceAlias $NIC -ServerAddresses ("192.168.0.102", "192.168.0.103", "192.168.0.104", "192.168.0.101", "1.1.1.1", "8.8.8.8")