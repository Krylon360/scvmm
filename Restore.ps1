# Load JSon Serialization
$LoadJson = [void][System.Reflection.Assembly]::LoadWithPartialName("System.Web.Extensions")
$JsonSerial= New-Object -TypeName System.Web.Script.Serialization.JavaScriptSerializer
$JsonSerial.MaxJsonLength = [int]::MaxValue

# Restore Host Groups
$HostGroupsRaw = Get-Content -Path HostGroups.txt -Raw
$HostGroups = $JsonSerial.DeserializeObject($HostGroupsRaw)
$HostGroups = $HostGroups | Sort-Object -Property ParentHostGroup.Path
 
# Restore Logical Network
$LogicalNetworksRaw = Get-Content -Path LogicalNetworks.txt -Raw
$LogicalNetworks = $JsonSerial.DeserializeObject($LogicalNetworksRaw)

# Restore Logical Network Definition
$LogicalNetworkDefinitionsRaw = Get-Content -Path LogicalNetworkDefinitions.txt -Raw
$LogicalNetworkDefinitions = $JsonSerial.DeserializeObject($LogicalNetworkDefinitionsRaw)
 
# Restore Static IP Address Pool
$StaticIPAddressPoolsRaw = Get-Content -Path StaticIPAddressPools.txt -Raw
$StaticIPAddressPools = $JsonSerial.DeserializeObject($StaticIPAddressPoolsRaw)
 
# Restore VM Networks
$VMNetworksRaw = Get-Content -Path VMNetworks.txt -Raw
$VMNetworks = $JsonSerial.DeserializeObject($VMNetworksRaw)
 
# Restore VM Subnets
$VMSubnetsRaw = Get-Content -Path VMSubnets.txt -Raw
$VMSubnets = $JsonSerial.DeserializeObject($VMSubnetsRaw)
 
# Restore Clouds
$CloudsRaw = Get-Content -Path Clouds.txt -Raw
$Clouds = $JsonSerial.DeserializeObject($CloudsRaw)

# Restore Library Shares
$LibrarySharesRaw = Get-Content -Path LibraryShares.txt -Raw
$LibraryShares = $JsonSerial.DeserializeObject($LibrarySharesRaw)
 
# Restore User Roles
$UserRolesRaw = Get-Content -Path UserRoles.txt -Raw
$UserRoles = $JsonSerial.DeserializeObject($UserRolesRaw)
 
# Restore User Role Quotas
$UserRoleQuotasRaw = Get-Content -Path UserRoleQuotas.txt -Raw
$UserRoleQuotas = $JsonSerial.DeserializeObject($UserRoleQuotasRaw)

# Restore VM Templates
$VMTemplatesRaw = Get-Content -Path VMTemplates.txt -Raw
$VMTemplates = $JsonSerial.DeserializeObject($VMTemplatesRaw)

# Restore Host Network Adapters
$HostNetworkAdaptersRaw = Get-Content -Path HostNetworkAdapters.txt -Raw
$HostNetworkAdapters = $JsonSerial.DeserializeObject($HostNetworkAdaptersRaw)
 
Write-Host "Working on Host Groups.."
Write-Host " "
 
# Set Host Groups
foreach ($HostGroup in $HostGroups)
{
	$CheckHostGroup = Get-SCVMHostGroup | Where Path -eq $HostGroup.Path
	if (!$CheckHostGroup)
	{
		Write-Host $HostGroup.Name is not exist. Creating..
		$ParentHostGroup = @(Get-SCVMHostGroup | Where {$_.ParentHostGroup.Path -eq $HostGroup.ParentHostGroup.ParentHostGroup})[0]
		$NewHostGroup = New-SCVMHostGroup -Name $HostGroup.Name -Description $HostGroup.Description -ParentHostGroup $ParentHostGroup -EnableUnencryptedFileTransfer $HostGroup.AllowUnencryptedTransfers -InheritNetworkSettings $HostGroup.InheritNetworkSettings
	}
	else
	{
		Write-Host $HostGroup.Name is already available.
	}
}
 
Write-Host " "
Write-Host " "
Write-Host "Working on Logical Networks.."
Write-Host " "
 
# Set Logical Networks
foreach ($LogicalNetwork in $LogicalNetworks)
{
	$CheckLogicalNetwork = Get-SCLogicalNetwork -Name $LogicalNetwork.Name
	if (!$CheckLogicalNetwork)
	{
		Write-Host $LogicalNetwork.Name is not exist. Creating..
		$NewLogicalNetwork = New-SCLogicalNetwork -Name $LogicalNetwork.Name -Description $LogicalNetwork.Description -EnableNetworkVirtualization $LogicalNetwork.NetworkVirtualizationEnabled -UseGRE $LogicalNetwork.UseGRE -IsPVLAN $LogicalNetwork.IsPVLAN -LogicalNetworkDefinitionIsolation $LogicalNetwork.IsLogicalNetworkDefinitionIsolated
	}
	else
	{
		Write-Host $LogicalNetwork.Name is already available.
	}
}
 
Write-Host " "
Write-Host " "
Write-Host "Working on Logical Network Definitions.."
Write-Host " "
 
# Set Logical Network Definition
foreach ($LogicalNetworkDefinition in $LogicalNetworkDefinitions)
{
	$CheckLogicalNetworkDefinition = Get-SCLogicalNetworkDefinition -Name $LogicalNetworkDefinition.Name
	if (!$CheckLogicalNetworkDefinition)
	{
		Write-Host $LogicalNetworkDefinition.Name is not exist. Creating..
 
		# Get Logical Network
		$LogicalNetwork = Get-SCLogicalNetwork -Name $LogicalNetworkDefinition.LogicalNetwork.Name
 
		# Get Subnet VLANS
		$SubnetVLANPool = @()
		foreach ($SubnetVLAN in $LogicalNetworkDefinition.SubnetVLans)
		{
			$SubnetInfo = $SubnetVLAN.Split("-")
			$SubnetVLANPool += New-SCSubnetVLan -Subnet $SubnetInfo[0] -VLanID $SubnetInfo[1]
		}
 
		# Get VMHost Groups
		$HostGroupPool = @()
		foreach ($HostGroup in $LogicalNetworkDefinition.HostGroups)
		{
			$HostGroupPool += Get-SCVMHostGroup | Where Path -eq $HostGroup
 
		}
 
		# Create Logical Network Definition
		$NewLogicalNetworkDefinition = New-SCLogicalNetworkDefinition -Name $LogicalNetworkDefinition.Name -LogicalNetwork $LogicalNetwork -SubnetVLan $SubnetVLANPool -VMHostGroup $HostGroupPool
	}
	else
	{
		Write-Host $LogicalNetworkDefinition.Name is already available.
	}
}
 
Write-Host " "
Write-Host " "
Write-Host "Working on Static IP Address Pools.."
Write-Host " "
 
# Set Static IP Address Pool
foreach ($StaticIPAddressPool in $StaticIPAddressPools)
{
	$CheckStaticIPAddressPool = Get-SCStaticIPAddressPool -Name $StaticIPAddressPool.Name
	if (!$CheckStaticIPAddressPool)
	{
		Write-Host $StaticIPAddressPool.Name is not exist. Creating..
 
		# Create Gateway
		$Gateways = @()
		foreach ($DefaultGateway in $StaticIPAddressPool.DefaultGateways)
		{
			$Gateways += New-SCDefaultGateway -IPAddress $DefaultGateway
		}
 
		# Get Logical Network Definition
		$LogicalNetworkDefinition = Get-SCLogicalNetworkDefinition -Name $StaticIPAddressPool.LogicalNetworkDefinition.Name
 
		# Create Static IP Address Pool
		$NewStaticIPAddressPool = New-SCStaticIPAddressPool -Name $StaticIPAddressPool.Name -Description $StaticIPAddressPool.Description -Subnet $StaticIPAddressPool.Subnet -Vlan $StaticIPAddressPool.VLANID -IPAddressRangeStart $StaticIPAddressPool.IPAddressRangeStart -IPAddressRangeEnd $StaticIPAddressPool.IPAddressRangeEnd -IPAddressReservedSet $StaticIPAddressPool.IPAddressReservedSet -DNSSuffix $StaticIPAddressPool.DNSSuffix -EnableNetBIOS $StaticIPAddressPool.EnableNetBIOS -LogicalNetworkDefinition $LogicalNetworkDefinition -DNSServer $StaticIPAddressPool.DNSServers -WINSServer $StaticIPAddressPool.WINSServers -DNSSearchSuffix $StaticIPAddressPool.DNSSearchSuffixes -DefaultGateway $Gateways
	}
	else
	{
		Write-Host $StaticIPAddressPool.Name is already available.
	}
}
 
Write-Host " "
Write-Host " "
Write-Host "Working on VM Networks.."
Write-Host " "
 
# Set VM Networks
foreach ($VMNetwork in $VMNetworks)
{
	# Get User Role
	$UserRole = Get-SCUserRole -Name $VMNetwork.UserRole.Name
 
	# Get Logical Network
	$LogicalNetwork = Get-SCLogicalNetwork -Name $VMNetwork.LogicalNetwork.Name
 
	$CheckVMNetwork = Get-SCVMNetwork -Name $VMNetwork.Name
	if (!$CheckVMNetwork)
	{
		Write-Host $VMNetwork.Name is not exist. Creating..
 
		$UserRole = Get-SCUserRole -Name $VMNetwork.UserRole.Name
		$LogicalNetwork = Get-SCLogicalNetwork -Name $VMNetwork.LogicalNetwork.Name
		$NewSCVMNetwork = New-SCVMNetwork -Name $VMNetwork.Name -Description $VMNetwork.Description -UserRole $UserRole -LogicalNetwork $LogicalNetwork -RoutingDomainId $VMNetwork.RoutingDomainId -IsolationType $VMNetwork.IsolationType -PAIPAddressPoolType $VMNetwork.PAIPAddressPoolType -CAIPAddressPoolType $VMNetwork.CAIPAddressPoolType -Owner $VMNetwork.Owner
	}
	else
	{
		Write-Host $VMNetwork.Name is already available.
	}	
}
 
Write-Host " "
Write-Host " "
Write-Host "Working on VM Subnets.."
Write-Host " "
 
# Set VM Subnets
foreach ($VMSubnet in $VMSubnets)
{
	# Get Subnet VLAN Information
	$SubnetInfo = $VMSubnet.SubnetVLANs.Split("-")
	$SubnetName = $SubnetInfo[0]
	$SubnetVLanID = $SubnetInfo[1]
 
	# Create Subnet VLAN
	$SubnetVLAN = New-SCSubnetVLan -Subnet $SubnetName -VLanID $SubnetVLanID
 
	# Get Logical Network Definition
	$LogicalNetworkDefinition = Get-SCLogicalNetworkDefinition -VLanID $SubnetVLanID
 
	# Get VM Network
	$VMNetwork = Get-SCVMnetwork -Name $VMSubnet.VMNetwork.Name
 
	$CheckVMSubnet = Get-SCVMSubnet -Name $VMSubnet.Name
	if (!$CheckVMSubnet)
	{
		Write-Host $VMSubnet.Name is not exist. Creating..
 
		$NewVMSubnet = New-SCVMSubnet -Name $VMSubnet.Name -Description $VMSubnet.Description -LogicalNetworkDefinition $LogicalNetworkDefinition -SubnetVLan $SubnetVLAN -VMNetwork $VMNetwork -MaxNumberOfPorts $VMSubnet.MaxNumberOfPorts
	}
	else
	{
		Write-Host $VMSubnet.Name is already available.
	}	
}
 
Write-Host " "
Write-Host " "
Write-Host "Working on Clouds.."
Write-Host " "
 
# Set Clouds
foreach ($Cloud in $Clouds)
{
	$CheckCloud = Get-SCCloud -Name $Cloud.Name
	if (!$CheckCloud)
	{
		Write-Host $Cloud.Name is not exist. Creating..
 
		# Get VMHost Groups
		$HostGroupPool = @()
		foreach ($HostGroup in $Cloud.HostGroup)
		{
			$HostGroupPool += Get-SCVMHostGroup | Where Path -eq $HostGroup
		}
 
		# Create Cloud
		$NewCloud = New-SCCloud -Name $Cloud.Name -VMHostGroup $HostGroupPool -DisasterRecoverySupported $Cloud.IsDRProtected
	}
	else
	{
		Write-Host $Cloud.Name is already available.
	}
}

Write-Host " "
Write-Host " "
Write-Host "Working on Capability Profiles.."
Write-Host " "
 
# Set Capability Profiles
foreach ($Cloud in $Clouds)
{
	$CheckCloud = Get-SCCloud -Name $Cloud.Name
	if ($CheckCloud)
	{		
		# Get Capability Profiles
		$CapabilityProfilePool = @()
		
		foreach ($CapabilityProfileItem in $Cloud.CapabilityProfiles)
		{
			$CapabilityProfile = Get-SCCapabilityProfile -Name $CapabilityProfileItem
			
			if ($CapabilityProfile)
			{
				if ($CheckCloud.CapabilityProfiles.Name -notcontains $CapabilityProfile.Name)
				{
					Write-Host $CapabilityProfile.Name is added to capability profile pool.
					
					$CapabilityProfilePool += $CapabilityProfile
				}
				else
				{
					Write-Host $CapabilityProfile.Name is already exist on cloud capability profile.
				}
			}
			else
			{
				Write-Host $CapabilityProfileItem is not exist. Please check your capability profile config.
			}
		}
		
		# Set Capability Profile
		if ($CapabilityProfilePool)
		{
			Write-Host Setting Capability Profiles on $Cloud.Name ..
			
			$SetCloud = $CheckCloud | Set-SCCloud -AddCapabilityProfile $CapabilityProfilePool
		}
		else
		{
			Write-Host No additional capability profiles are exist for $Cloud.Name ..
		}
	}
	else
	{
		Write-Host $Cloud.Name is not exist. Please check your cloud configuration.
	}
}

Write-Host " "
Write-Host " "
Write-Host "Working on Library Shares.."
Write-Host " "
 
# Set Library Shares
foreach ($Cloud in $Clouds)
{
	$CheckCloud = Get-SCCloud -Name $Cloud.Name
	if ($CheckCloud)
	{		
		# Get Library Shares
		$LibrarySharePool = @()
		
		foreach ($LibrarySharePath in $Cloud.ReadableLibraryPaths)
		{
			$LibraryShareName = ($LibraryShares | Where Path -eq $LibrarySharePath).Name
			$LibraryShare = Get-SCLibraryShare | Where Name -eq $LibraryShareName
			
			if ($LibraryShare)
			{
				if ($Cloud.ReadableLibraryPaths -notcontains $LibraryShare.Path)
				{
					Write-Host $LibraryShareName is added to library share pool.
					
					$LibrarySharePool += $LibraryShare
				}
				else
				{
					Write-Host $LibraryShareName is already exist on cloud.
				}
			}
			else
			{
				Write-Host $LibraryShareName is not exist. Please update your library shares manually.
			}
		}
		
		# Set Library Shares
		if ($LibrarySharePool)
		{
			Write-Host Setting Library Shares on $Cloud.Name ..
			
			$SetCloud = $CheckCloud | Set-SCCloud -AddReadOnlyLibraryShare $LibrarySharePool
		}
		else
		{
			Write-Host No additional library shares are exist for $Cloud.Name ..
		}
	}
	else
	{
		Write-Host $Cloud.Name is not exist. Please check your cloud configuration.
	}
}
 
Write-Host " "
Write-Host " "
Write-Host "Working on User Roles.."
Write-Host " "
 
# Set User Roles
foreach ($UserRole in $UserRoles)
{
	$CheckUserRole = Get-SCUserRole -Name $UserRole.Name
	if (!$CheckUserRole)
	{
		Write-Host $UserRole.Name is not exist. Creating..
 
		# Create User Role
		$NewUserRole = New-SCUserRole -Name $UserRole.Name -UserRoleProfile $UserRole.UserRoleProfile -Description $UserRole.Description -ParentUserRole $UserRole.ParentUserRole.ParentUserRole
 
		# Get Scopes
		$CloudScope = @()
		foreach ($Cloud in $UserRole.Cloud)
		{
			$CloudScope += Get-SCCloud -Name $Cloud
		}
 
		# Set User Role
		$GetUserRole = Get-SCUserRole -Name $UserRole.Name
		$SetUserRole = Set-SCUserRole -UserRole $GetUserRole -AddScope $CloudScope
		
		# Get User Role Members
		$UserRoleMembers = $UserRole.Members
		
		# Set User Role Members
		foreach ($UserRoleMember in $UserRoleMembers)
		{
			Write-Host $UserRoleMemberName is being applied on $UserRoleName user role..
		 
			$SetUserRole = Set-SCUserRole -UserRole $GetUserRole -AddMember @("$UserRoleMemberName")
		}
	}
	else
	{
		Write-Host $UserRole.Name is already available.
	}
}
 
Write-Host " "
Write-Host " "
Write-Host "Working on User Role Quotas.."
Write-Host " "
 
# Set User Role Quotas
foreach ($UserRoleQuota in $UserRoleQuotas)
{
	# Get User Role
	$UserRoleName = $Null;
	$UserRoleName = ($UserRoles | Where ID -eq $UserRoleQuota.RoleID).Name
	$UserRole = Get-SCUserRole -Name $UserRoleName
 
	# Get Cloud
	$CloudName = $Null;
	$CloudName = ($Clouds | Where ID -eq $UserRoleQuota.CloudID).Name
	$Cloud = Get-SCCloud -Name $CloudName
	$GetUserRoleQuota = Get-SCUserRoleQuota -UserRole $UserRole -Cloud $Cloud
 
	Write-Host $UserRole.Name role quota is being applied on $Cloud.Name cloud..
 
	# Set User Role Quota
	if ($UserRoleQuota.CPUCount)
	{
		$SetUserRoleQuota = $GetUserRoleQuota | Set-SCUserRoleQuota -CPUCount $UserRoleQuota.CPUCount
	}
	else
	{
		$SetUserRoleQuota = $GetUserRoleQuota | Set-SCUserRoleQuota -UseCPUCountMaximum
	}
 
	# Set User Role Quota
	if ($UserRoleQuota.MemoryMB)
	{
		$SetUserRoleQuota = $GetUserRoleQuota | Set-SCUserRoleQuota -MemoryMB $UserRoleQuota.MemoryMB
	}
	else
	{
		$SetUserRoleQuota = $GetUserRoleQuota | Set-SCUserRoleQuota -UseMemoryMBMaximum
	}
 
	# Set User Role Quota
	if ($UserRoleQuota.StorageGB)
	{
		$SetUserRoleQuota = $GetUserRoleQuota | Set-SCUserRoleQuota -StorageGB $UserRoleQuota.StorageGB
	}
	else
	{
		$SetUserRoleQuota = $GetUserRoleQuota | Set-SCUserRoleQuota -UseStorageGBMaximum
	}
 
	# Set User Role Quota
	if ($UserRoleQuota.VMCount)
	{
		$SetUserRoleQuota = $GetUserRoleQuota |Set-SCUserRoleQuota -VMCount $UserRoleQuota.VMCount
	}
	else
	{
		$SetUserRoleQuota = $GetUserRoleQuota |Set-SCUserRoleQuota -UseVMCountMaximum
	}
 
	# Set User Role Quota
	if ($UserRoleQuota.CustomQuotaCount)
	{
		$SetUserRoleQuota = $GetUserRoleQuota | Set-SCUserRoleQuota -CustomQuotaCount $UserRoleQuota.CustomQuotaCount
	}
	else
	{
		$SetUserRoleQuota = $GetUserRoleQuota | Set-SCUserRoleQuota -UseCustomQuotaCountMaximum
	}
}

Write-Host " "
Write-Host " "
Write-Host "Working on VM Templates.."
Write-Host " "
 
# Set VM Templates
foreach ($VMTemplate in $VMTemplates)
{
	$CheckVMTemplate = Get-SCVMTemplate -Name $VMTemplate.Name
	if (!$CheckVMTemplate)
	{
		Write-Host $VMTemplate.Name is not exist. Creating..
		
		# Get Operating System
		$OperatingSystem = Get-SCOperatingSystem | Where Name -eq $VMTemplate.OperatingSystem.Name
		
		# Get Virtual Hard Disk
		$VirtualHardDisk = Get-SCVirtualHardDisk | Where Name -eq $VMTemplate.VirtualHardDisks
		
		# Get User Role
		$UserRole = Get-SCUserRole -Name $VMTemplate.UserRole.Name
		
		# Get Capability Profile
		$CapabilityProfile = Get-SCCapabilityProfile -Name $VMTemplate.CapabilityProfile.Name
		
		# Get CPU Type
		$CPUType = Get-SCCPUType | Where Name -eq $VMTemplate.CPUType.Name
 
		if ($VirtualHardDisk)
		{
			Write-Host Hello
			# Set VM Template
			$NewVMTemplate = New-SCVMTemplate -Name $VMTemplate.Name -Description $VMTemplate.Description -Owner $VMTemplate.Owner -UserRole $UserRole -OperatingSystem $OperatingSystem -VirtualHardDisk $VirtualHardDisk
		}
		else
		{
			Write-Host $VMTemplate.VirtualHardDisks is not available on Library. Please check your library configuration.
		}
	}
	else
	{
		Write-Host $VMTemplate.Name is already available.
	}
}

Write-Host " "
Write-Host " "
Write-Host "Working on Host Network Adapters.."
Write-Host " "
 
# Set Host Network Adapters
foreach ($VMTemplate in $VMTemplates)
{
	# 
	$UserRoleName = $Null;
	$UserRoleName = ($UserRoles | Where ID -eq $UserRoleQuota.RoleID).Name
	$UserRole = Get-SCUserRole -Name $UserRoleName
 
	# Get Cloud
	$CloudName = $Null;
	$CloudName = ($Clouds | Where ID -eq $UserRoleQuota.CloudID).Name
	$Cloud = Get-SCCloud -Name $CloudName
	$GetUserRoleQuota = Get-SCUserRoleQuota -UserRole $UserRole -Cloud $Cloud
 
	Write-Host $UserRole.Name role quota is being applied on $Cloud.Name cloud..
 
	# Set User Role Quota
	if ($UserRoleQuota.CPUCount)
	{
		$SetUserRoleQuota = $GetUserRoleQuota | Set-SCUserRoleQuota -CPUCount $UserRoleQuota.CPUCount
	}
	else
	{
		$SetUserRoleQuota = $GetUserRoleQuota | Set-SCUserRoleQuota -UseCPUCountMaximum
	}
 
	# Set User Role Quota
	if ($UserRoleQuota.MemoryMB)
	{
		$SetUserRoleQuota = $GetUserRoleQuota | Set-SCUserRoleQuota -MemoryMB $UserRoleQuota.MemoryMB
	}
	else
	{
		$SetUserRoleQuota = $GetUserRoleQuota | Set-SCUserRoleQuota -UseMemoryMBMaximum
	}
 
	# Set User Role Quota
	if ($UserRoleQuota.StorageGB)
	{
		$SetUserRoleQuota = $GetUserRoleQuota | Set-SCUserRoleQuota -StorageGB $UserRoleQuota.StorageGB
	}
	else
	{
		$SetUserRoleQuota = $GetUserRoleQuota | Set-SCUserRoleQuota -UseStorageGBMaximum
	}
 
	# Set User Role Quota
	if ($UserRoleQuota.VMCount)
	{
		$SetUserRoleQuota = $GetUserRoleQuota |Set-SCUserRoleQuota -VMCount $UserRoleQuota.VMCount
	}
	else
	{
		$SetUserRoleQuota = $GetUserRoleQuota |Set-SCUserRoleQuota -UseVMCountMaximum
	}
 
	# Set User Role Quota
	if ($UserRoleQuota.CustomQuotaCount)
	{
		$SetUserRoleQuota = $GetUserRoleQuota | Set-SCUserRoleQuota -CustomQuotaCount $UserRoleQuota.CustomQuotaCount
	}
	else
	{
		$SetUserRoleQuota = $GetUserRoleQuota | Set-SCUserRoleQuota -UseCustomQuotaCountMaximum
	}
}