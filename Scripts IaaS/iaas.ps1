# AD Authentication
import-module activedirectory
$authenticated = $false
$auth_try_count = 0

DO
{
	$Cred = Get-Credential -Message "Enter your Cloudis Credentials"
	try {
		Get-ADUser -identity $cred.username -credential $cred -ErrorAction Stop *> $null # *> $null remove console output
		$authenticated = $true
	} catch {
		echo $ErrorMessage = $_.Exception.Message
		$auth_try_count = $auth_try_count + 1
		if($auth_try_count -eq 3){
			Exit
		}
	}
	
} While ($authenticated -eq $false)




# Prepare vSphere PowerCLI environment
Add-PSSnapin VMware.VimAutomation.Core
Add-PSSnapin VMware.VimAutomation.Vds
if(get-item HKLM:\SOFTWARE\Microsoft\PowerShell\1\PowerShellSnapIns\VMware.VimAutomation.Core){
	. ((get-item HKLM:\SOFTWARE\Microsoft\PowerShell\1\PowerShellSnapIns\VMware.VimAutomation.Core).GetValue("ApplicationBase")+"\Scripts\Initialize-PowerCLIEnvironment.ps1")
}
else
{
	write-warning "PowerCLI Path not found in registry, please set path to Initialize-PowerCLIEnvironment.ps1 manually. Is PowerCli aleady installed?"
	. "C:\Programs (x86)\VMware\Infrastructure\vSphere PowerCLI\Scripts\Initialize-PowerCLIEnvironment.ps1"
}

# vCenter connection
$Server = "192.168.107.151"
$MaxSampleVIEvent = 100000
$UserName = "Administrator@vsphere.local"
$Password = "Supinf0!"

$pLang = DATA {
   ConvertFrom-StringData @' 
      connError = Unable to connect to vCenter, please ensure you have altered the vCenter server address correctly. To specify a username and password edit the connection string in the file $GlobalVariables
'@
}

$VIServer = ($Server -Split ":")[0]
if (($server -split ":")[1]) {
   $port = ($server -split ":")[1]
}
else
{
   $port = 443
}

$OpenConnection = $global:DefaultVIServers | where { $_.Name -eq $VIServer }
if($OpenConnection.IsConnected) {
	$VIConnection = $OpenConnection
} else {
	$VIConnection = Connect-VIServer -Server $VIServer -Port $Port -User $UserName -Password $Password
}

if (-not $VIConnection.IsConnected) {
	Write-Error $pLang.connError
}

#Importing functions
. "$PSScriptRoot\iaas_functions.ps1"

Clear
write-host "Welcome to Cloudis !`n`n" -foregroundcolor "Green"
# Main Menu action chooser
$choosenMenuItem = 0
DO 
{
	write-host "What would you want to do ?`n" -foregroundcolor "Yellow"
	write-host "1 : Display all Virtual Machines"
	write-host "2 : Delete a virtual machine"
	write-host "3 : Restart a virtual machine"
	write-host "4 : Add a new virtual machine"
	write-host "5 : Exit"
	write-host "`n"
	
	$choosenMenuItem = Read-Host 'What is your choice ?'
	
	If($choosenMenuItem -eq 1)
	{
		VMs-DisplayAll
	}
	ElseIf($choosenMenuItem -eq 2)
	{
		VM-Delete
	}
	ElseIf($choosenMenuItem -eq 3)
	{
		VM-Restart
	}
	ElseIf($choosenMenuItem -eq 4)
	{
		VM-Add
	}
	ElseIf($choosenMenuItem -eq 5)
	{
	}
	Else
	{
		write-host "`nUnrecognized choice, please enter a number from the list`n" -foregroundcolor "Red"
	}
	
} While ($choosenMenuItem -ne 5)

