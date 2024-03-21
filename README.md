# VM-Deployment-in-Hyper-V
Automated functions to deploy new VMs in Hyper-V

Basically just run Create-VM.ps1 to import the functions. Once that's done you can:

Create-VM -VMName <name>  (creates a Hyper-V VM from an ISO file & an answer file and then starts it)

Config-VM -VMName <name> (sets the VM's IP to what you specified in VMConfig.ps1, along with the DNS servers. Also disables NetBIOS & IPv6. Skip if your lab uses DHCP)

Join-Domain -VMName <name> (joins the test.local domain using test\Mishky. Obviously tweak that to your lab's setup. I'll tweak this later so you can specify both as a command line option.)

Cleanup.ps1 imports a function that will delete the VM, VM HD, and AD account of the specified Hyper-V VM name. I used it while testing out the creation project. 

See our full writeup/howto on this project here (https://happycamper84.medium.com/hyper-v-iacing-vms-revisited-ec7ff6d884a8).

If you have any questions then just leave a comment on here or Medium.
