# Actions implementations

function VMs-DisplayAll
{
	write-host "`n"
	Get-VM | Select Name, PowerState, @{N="IP Address";E={@($_.guest.IPAddress[0])}}
	write-host "`n"
}

function VM-Restart
{
	VMs-DisplayAll
	$vm_name = Read-Host "Enter the name of virtual machine to be restarted "
	Get-VM $vm_name | Restart-VM -Confirm:$false
}

function VM-Delete
{
	VMs-DisplayAll
	$vm_name = Read-Host "Enter the name of virtual machine to be deleted "
	$vm = Get-VM $vm_name 
	$vm | Stop-VM -Kill -Confirm:$false
	$vm | Remove-VM -DeletePermanently -Confirm:$false
}

function VM-Add
{
	write-host "`nAvailable templates : `n" -foregroundcolor "Yellow"
	Get-Template
	write-host "`n"
	$selected_template = Read-Host "Enter the name of the choosen template "
	$vm_name = Read-Host "Enter the virtual machine name "
	
	$end_ip_address = Read-Host "Enter an ip address 192.168.107. (Laissez vide pour attribution DHCP) "
	write-host "`n"
	
	$task = $null
	if(!$end_ip_address)
	{
		write-host "`Starting virtual machine creation, waiting for task to finish, please wait : `n" -foregroundcolor "Yellow"
		$task = New-VM -Name $vm_name -Template $selected_template -ResourcePool CloudisCluster -Datastore "cloudisnfs" -RunAsync 
	}
	else 
	{
		# IP
		$ip_address = "192.168.107.$($end_ip_address)"
		$submask = "255.255.255.0"
		$gateway = "192.168.107.2"
		$dns = "192.168.107.150"
		
		$custSpec = New-OSCustomizationSpec -Type NonPersistent -OrgName Supinfo -FullName Supinfo -Domain "cloudis157959.lan" -DomainUsername "Administrateur" -DomainPassword "Supinf0" -ChangeSID:$true
	 
		$custSpec | Get-OSCustomizationNicMapping | Set-OSCustomizationNicMapping -IpMode UseStaticIP -IpAddress $ip_address -SubnetMask $submask -Dns $dns -DefaultGateway $gateway
	
		write-host "`Starting virtual machine creation, waiting for task to finish, please wait : `n" -foregroundcolor "Yellow"
		$task = New-VM -Name $vm_name -Template $selected_template -ResourcePool CloudisCluster -Datastore "cloudisnfs" -OSCustomizationSpec $custSpec -RunAsync 
	}
	
	while($task.ExtensionData.Info.State -eq "running"){
	  sleep 1
	  $task.ExtensionData.UpdateViewData('Info.State')
	}
	
	write-host "`nVirtual machine created, power on signal sended, your virtual machine will be available in few seconds : `n" -foregroundcolor "Yellow"
	Get-VM $vm_name | Start-VM 
}