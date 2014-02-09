# Load JSon Serialization
$LoadJson = [System.Reflection.Assembly]::LoadWithPartialName("System.Web.Extensions")
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
 
# Restore Virtual Machines
$VirtualMachines = Get-Content -Path VirtualMachines.txt -Raw
$VirtualMachines = $JsonSerial.DeserializeObject($VirtualMachines)
 
Write-Host "Working on Host Groups.."
Write-Host " "
 
# Set Host Groups
foreach ($HostGroup in $HostGroups)
{
	$CheckHostGroup = Get-SCVMHostGroup | Where Path -eq $HostGroup.Path
	if (!$CheckHostGroup)
	{
		Write-Host $HostGroup.Name is not exist. Creating..
		$ParentHostGroup = @(Get-SCVMHostGroup | Where {$_.Path -eq $HostGroup.ParentHostGroup.Path})[0]
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
		$NewStaticIPAddressPool = New-SCStaticIPAddressPool -Name $StaticIPAddressPool.Name -Description $StaticIPAddressPool.Description -Subnet $StaticIPAddressPool.Subnet -Vlan $StaticIPAddressPool.VLanID -IPAddressRangeStart $StaticIPAddressPool.IPAddressRangeStart -IPAddressRangeEnd $StaticIPAddressPool.IPAddressRangeEnd -IPAddressReservedSet $StaticIPAddressPool.IPAddressReservedSet -DNSSuffix $StaticIPAddressPool.DNSSuffix -EnableNetBIOS $StaticIPAddressPool.EnableNetBIOS -LogicalNetworkDefinition $LogicalNetworkDefinition -DNSServer $StaticIPAddressPool.DNSServers -WINSServer $StaticIPAddressPool.WINSServers -DNSSearchSuffix $StaticIPAddressPool.DNSSearchSuffixes -DefaultGateway $Gateways
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
	$SubnetInfo = $VMSubnet.SubnetVLans.Split("-")
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
 
$LibraryShares = Get-SCLibraryShare
 
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
				if ($LibrarySharePool -notcontains $LibraryShare.Path)
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
		foreach ($Cloud in $UserRole.Cloud.Name)
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
			$UserRoleMemberName = $UserRoleMember.Name
 
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
 
		# Set Variables
		$OperatingSystem = $Null;
		$VirtualHardDisk = $Null;
 
		# Clear Result Code
		$ResultCode = "1"
 
		# Get Operating System
		$OperatingSystem = Get-SCOperatingSystem | Where Name -eq $VMTemplate.OperatingSystem.Name
 
		if (!$OperatingSystem)
		{
			$ResultCode = "-1"
 
			Write-Host Operating System for $VMTemplate.Name is not exist. Please check your library config.
		}
 
		# Get Virtual Hard Disk
		$VirtualHardDisk = Get-SCVirtualHardDisk | Where Location -eq $VMTemplate.VirtualHardDisks.Location
 
		if (!$VirtualHardDisk)
		{
			$ResultCode = "-1"
 
			Write-Host Virtual Hard Disk for $VMTemplate.Name is not exist. Please check your library config.
		}	
 
		# Create Job Group
		$JobGroupGuid = [System.Guid]::NewGuid().toString()
 
		# Get Virtual Network Adapter
		foreach ($VirtualNetworkAdapter in $VMTemplate.VirtualNetworkAdapters)
		{
			# Get IPv4 Address Type
			if ($VirtualNetworkAdapter.IPv4AddressType -eq "1")
			{
				$IPv4AddressType = "Static"
			}
			else
			{
				$IPv4AddressType = "Dynamic"
			}
 
			# Get IPv6 Address Type
			if ($VirtualNetworkAdapter.IPv6AddressType -eq "1")
			{
				$IPv6AddressType = "Static"
			}
			else
			{
				$IPv6AddressType = "Dynamic"
			}
 
			# Get VM Network
			$VMNetwork = Get-SCVMNetwork -Name $VirtualNetworkAdapter.VMNetwork
 
			# Get VM Subnet
			$VMSubnet = Get-SCVMSubnet -Name $VMNetwork.VMSubnet.Name
 
			if ($VirtualNetworkAdapter.VirtualNetworkAdapterType -eq "2")
			{
				# Synthetic
				New-SCVirtualNetworkAdapter -JobGroup $JobGroupGuid -MACAddress $VirtualNetworkAdapter.MACAddress -MACAddressType $VirtualNetworkAdapter.MACAddressType -Synthetic -EnableVMNetworkOptimization $VirtualNetworkAdapter.VMNetworkOptimizationEnabled -EnableMACAddressSpoofing $VirtualNetworkAdapter.MACAddressSpoofingEnabled -IPv4AddressType $IPv4AddressType -IPv6AddressType $IPv6AddressType -VMSubnet $VMSubnet -VMNetwork $VMNetwork 
			}
			else
			{
				# Emulated
				New-SCVirtualNetworkAdapter -JobGroup $JobGroupGuid -MACAddress $VirtualNetworkAdapter.MACAddress -MACAddressType $VirtualNetworkAdapter.MACAddressType -EnableVMNetworkOptimization $VirtualNetworkAdapter.VMNetworkOptimizationEnabled -EnableMACAddressSpoofing $VirtualNetworkAdapter.MACAddressSpoofingEnabled -IPv4AddressType $IPv4AddressType -IPv6AddressType $IPv6AddressType -VMSubnet $VMSubnet -VMNetwork $VMNetwork 
			}
		}
 
		if ($ResultCode -ne "-1")
		{		
			# Set VM Template
			$NewVMTemplate = New-SCVMTemplate -JobGroup $JobGroupGuid -Name $VMTemplate.Name -Description $VMTemplate.Description -OperatingSystem $OperatingSystem -VirtualHardDisk $VirtualHardDisk
 
			if ($NewVMTemplate)
			{
				Write-Host $VMTemplate.Name is successfully created.
			}
			else
			{
				Write-Host $VMTemplate.Name is failed to create. Please check your library configuration.
			}
		}
	}
	else
	{
		Write-Host $VMTemplate.Name is already available.
	}
}
 
Write-Host " "
Write-Host " "
Write-Host "Working on VM Template Properties.."
Write-Host " "
 
# Set VM Templates
foreach ($VMTemplate in $VMTemplates)
{
	$CheckVMTemplate = Get-SCVMTemplate -Name $VMTemplate.Name
	if (!$CheckVMTemplate)
	{
		Write-Host $VMTemplate.Name is not exist. Please check your library configuration..
	}
	else
	{
		Write-Host Working on $VMTemplate.Name properties..
 
		# Clear Variables	
		$UserRole = $Null;
		$Owner = $Null;
		$CapabilityProfile = $Null;
		$IsHighlyAvailable = $Null;
		$IsDRProtectionRequired = $Null;
		$ApplicationProfile = $Null;
		$GetApplicationProfile = $Null;
		$SQLProfile = $Null;
		$GetSQLProfile = $Null;
		$AnswerFile = $Null;
		$CPUType = $Null;
		$CPUCount = $Null;
		$CPURelativeWeight = $Null;
		$CPUReserve = $Null;
		$CPUMaximumPercent = $Null;
		$CPUPerVirtualNumaNodeMaximum = $Null;
		$VirtualNumaNodesPerSocketMaximum = $Null;
		$NumaIsolationRequired = $Null;
		$MemoryMB = $Null;
		$DynamicMemoryEnabled = $Null;
		$MemoryWeight = $Null;
		$MemoryPerVirtualNumaNodeMaximumMB = $Null;
		$VirtualVideoAdapterEnabled = $Null;
		$MonitorMaximumCount = $Null;
		$MonitorMaximumResolution = $Null;
		$HAVMPriority = $Null;
		$SysprepScript = $Null;
		$SysprepScriptName = $Null;
		$SysprepScriptFile = $Null;
		$SysprepFilePathName = $Null;
		$ComputerName = $Null;
		$FullName = $Null;
		$OrganizationName = $Null;
		$TimeZone = $Null;
		$AutoLogonCount = $Null;
		$GuiRunOnceCommands = $Null;
		$GuiRunOnceCommandsArray = $Null;
		$LinuxAdministratorSSHKey = $Null;
		$LinuxDomainName = $Null;
		$QuotaPoint = $Null;
		$Tag = $Null;
		$CostCenter = $Null;
 
		# Get User Role
		$UserRole = Get-SCUserRole -Name $VMTemplate.UserRole.Name
 
		if ($UserRole)
		{
			# Set User Role
			$SetVMTemplate = $CheckVMTemplate | Set-SCVMTemplate -UserRole $UserRole
		}
 
		# Get Template Owner
		$Owner = $VMTemplate.Owner
 
		if ($Owner)
		{
			# Set Template Owner
			$SetVMTemplate = $CheckVMTemplate | Set-SCVMTemplate -Owner $Owner
		}
 
		# Get Capability Profile
		$CapabilityProfile = Get-SCCapabilityProfile -Name $VMTemplate.CapabilityProfile.Name
 
		if ($CapabilityProfile)
		{
			# Set Capability Profile
			$SetVMTemplate = $CheckVMTemplate | Set-SCVMTemplate -CapabilityProfile $CapabilityProfile
		}
 
		# Get Availability Status
		$IsHighlyAvailable = $VMTemplate.IsHighlyAvailable
 
		if ($IsHighlyAvailable)
		{
			# Set Availability Status
			$SetVMTemplate = $CheckVMTemplate | Set-SCVMTemplate -HighlyAvailable $IsHighlyAvailable
		}
 
		# Get DR Protection
		$IsDRProtectionRequired = $VMTemplate.IsDRProtectionRequired
 
		if ($IsDRProtectionRequired)
		{
			# Set DR Protection Status
			$SetVMTemplate = $CheckVMTemplate | Set-SCVMTemplate -DRProtectionRequired $IsDRProtectionRequired
		}
 
		# Get Application Profile
		 $ApplicationProfile = $VMTemplate.ApplicationProfile
 
		if ($ApplicationProfile)
		{
			# Get Application Profile
			$GetApplicationProfile = Get-SCApplicationProfile -Name $ApplicationProfile.Name
 
			if ($GetApplicationProfile)
			{
				# Set Application Profile
				$SetVMTemplate = $CheckVMTemplate | Set-SCVMTemplate -ApplicationProfile $GetApplicationProfile
			}
		}
 
		# Get SQL Profile
		 $SQLProfile = $VMTemplate.SQLProfile
 
		if ($SQLProfile)
		{
			# Get SQL Profile
			$GetSQLProfile = Get-SCSQLProfile -Name $SQLProfile.Name
 
			if ($GetSQLProfile)
			{
				# Set SQL Profile
				$SetVMTemplate = $CheckVMTemplate | Set-SCVMTemplate -SQLProfile $GetSQLProfile
			}
		}
 
		# Get AnswerFile
		$AnswerFile = $VMTemplate.AnswerFile
 
		if ($AnswerFile)
		{
			# Set Answer File
			$SetVMTemplate = $CheckVMTemplate | Set-SCVMTemplate -AnswerFile $AnswerFile
		}
 
		# Get CPU Type
		$CPUType = Get-SCCPUType | Where Name -eq $VMTemplate.CPUType.Name
 
		if ($CPUType)
		{
			# Set CPU Type
			$SetVMTemplate = $CheckVMTemplate | Set-SCVMTemplate -CPUType $CPUType
		}
 
		# Get CPU Count
		$CPUCount = $VMTemplate.CPUCount
 
		if ($CPUCount)
		{
			# Set CPU Count
			$SetVMTemplate = $CheckVMTemplate | Set-SCVMTemplate -CPUCount $CPUCount
		}
 
		# Get CPU Relative Weight
		$CPURelativeWeight = $VMTemplate.CPURelativeWeight
 
		if ($CPURelativeWeight)
		{
			# Set CPU Relative Weight
			$SetVMTemplate = $CheckVMTemplate | Set-SCVMTemplate -CPURelativeWeight $CPURelativeWeight
		}
 
		# Get CPU Reserve
		$CPUReserve = $VMTemplate.CPUReserve
 
		if ($CPUReserve)
		{
			# Set CPU Reserve
			$SetVMTemplate = $CheckVMTemplate | Set-SCVMTemplate -CPUReserve $CPUReserve
		}
 
		# Get CPU Maximum Percent
		$CPUMaximumPercent = $VMTemplate.CPUMaximumPercent
 
		if ($CPUMaximumPercent)
		{
			# Set CPU Maximum Percent
			$SetVMTemplate = $CheckVMTemplate | Set-SCVMTemplate -CPUMaximumPercent $CPUMaximumPercent
		}
 
		# Get CPU Virtualization Numa Node Maximum
		$CPUPerVirtualNumaNodeMaximum = $VMTemplate.CPUPerVirtualNumaNodeMaximum
 
		if ($CPUMaximumPercent)
		{
			# Set CPU Virtualization Numa Node Maximum
			$SetVMTemplate = $CheckVMTemplate | Set-SCVMTemplate -CPUMaximumPercent $CPUMaximumPercent
		}
 
		# Get Virtual Numa Nodes Per Socket Maximum
		$VirtualNumaNodesPerSocketMaximum = $VMTemplate.VirtualNumaNodesPerSocketMaximum
 
		if ($VirtualNumaNodesPerSocketMaximum)
		{
			# Set Virtual Numa Nodes Per Socket Maximum
			$SetVMTemplate = $CheckVMTemplate | Set-SCVMTemplate -VirtualNumaNodesPerSocketMaximum $VirtualNumaNodesPerSocketMaximum
		}
 
		# Get Numa Isolation Required
		$NumaIsolationRequired = $VMTemplate.NumaIsolationRequired 
 
		if ($NumaIsolationRequired)
		{
			# Set Numa Isolation Required
			$SetVMTemplate = $CheckVMTemplate | Set-SCVMTemplate -NumaIsolationRequired $NumaIsolationRequired
		}
 
		# Get Memory MB
		$MemoryMB = $VMTemplate.Memory
 
		if ($MemoryMB)
		{
			# Set Memory MB
			$SetVMTemplate = $CheckVMTemplate | Set-SCVMTemplate -MemoryMB $MemoryMB
		}
 
		# Get Dynamic Memory
		$DynamicMemoryEnabled = $VMTemplate.DynamicMemoryEnabled
 
		if ($DynamicMemoryEnabled -eq $True)
		{
			# Set Dynamic Memory
			$SetVMTemplate = $CheckVMTemplate | Set-SCVMTemplate -DynamicMemoryEnabled $DynamicMemoryEnabled -DynamicMemoryMinimumMB $VMTemplate.DynamicMemoryMinimumMB -DynamicMemoryMaximumMB $VMTemplate.DynamicMemoryMaximumMB -DynamicMemoryBufferPercentage $VMTemplate.DynamicMemoryBufferPercentage
		}
 
		# Get Memory Weight
		$MemoryWeight = $VMTemplate.MemoryWeight
 
		if ($MemoryWeight)
		{
			# Set Memory Weight
			$SetVMTemplate = $CheckVMTemplate | Set-SCVMTemplate -MemoryWeight $MemoryWeight
		}
 
		# Get Memory Per Virtual Numa Node Maximum MB
		$MemoryPerVirtualNumaNodeMaximumMB = $VMTemplate.MemoryPerVirtualNumaNodeMaximumMB
 
		if ($MemoryPerVirtualNumaNodeMaximumMB)
		{
			# Set Memory Per Virtual Numa Node Maximum MB
			$SetVMTemplate = $CheckVMTemplate | Set-SCVMTemplate -MemoryPerVirtualNumaNodeMaximumMB $MemoryPerVirtualNumaNodeMaximumMB
		}
 
		# Get Virtual Video Adapter Status
		$VirtualVideoAdapterEnabled = $VMTemplate.VirtualVideoAdapterEnabled
 
		if ($VirtualVideoAdapterEnabled)
		{
			# Set Virtual Video Adapter Status
			$SetVMTemplate = $CheckVMTemplate | Set-SCVMTemplate -VirtualVideoAdapterEnabled $VirtualVideoAdapterEnabled
		}
 
		# Get Monitor Maximum Count
		$MonitorMaximumCount = $VMTemplate.MonitorMaximumCount
 
		if ($MonitorMaximumCount)
		{
			# Set Monitor Maximum Count
			$SetVMTemplate = $CheckVMTemplate | Set-SCVMTemplate -MonitorMaximumCount $MonitorMaximumCount
		}
 
		# Get Monitor Maximum Resolution
		$MonitorMaximumResolution = $VMTemplate.MonitorMaximumResolution 
 
		if ($MonitorMaximumResolution)
		{
			# Set Monitor Maximum Resolution
			$SetVMTemplate = $CheckVMTemplate | Set-SCVMTemplate -MonitorMaximumResolution $MonitorMaximumResolution
		}
 
		# Get HAVM Priority
		$HAVMPriority = $VMTemplate.HAVMPriority 
 
		if ($HAVMPriority)
		{
			# Set Monitor Maximum Resolution
			$SetVMTemplate = $CheckVMTemplate | Set-SCVMTemplate -HAVMPriority $HAVMPriority
		}
 
		# Get Sysprep Script
		$SysprepScript = $VMTemplate.SysprepScript
 
		if ($SysprepScript)
		{
			$SysprepScriptName = $SysprepScript.Name
			$SysprepScriptFile = Get-Script | where {$_.Name -eq $SysprepScriptName}
 
			if (!$SysprepScriptFile)
			{
				$SysprepFilePathName = ($VMTemplate.SysprepScript.SharePath).Split("\")[-1]
				$SysprepScriptFile = Get-Script | where {$_.SharePath -like "*$SysprepFilePathName"}
			}
 
			# Set Sysprep Script
			$SetVMTemplate = $CheckVMTemplate | Set-SCVMTemplate -SysPrepFile $SysprepScriptFile -MergeAnswerFile $True
		}
 
		# Get Computer Name
		$ComputerName = $VMTemplate.ComputerName
 
		if ($ComputerName)
		{
			# Set Monitor Maximum Resolution
			$SetVMTemplate = $CheckVMTemplate | Set-SCVMTemplate -ComputerName $ComputerName
		}
 
		# Get Full Name
		$FullName = $VMTemplate.FullName
 
		if ($FullName)
		{
			# Set Monitor Maximum Resolution
			$SetVMTemplate = $CheckVMTemplate | Set-SCVMTemplate -FullName $FullName
		}
 
		# Get Organization Name
		$OrganizationName = $VMTemplate.OrgName
 
		if ($OrganizationName)
		{
			# Set Organization Name
			$SetVMTemplate = $CheckVMTemplate | Set-SCVMTemplate -OrganizationName $OrganizationName
		}
 
		# Get Time Zone
		$TimeZone = $VMTemplate.TimeZone
 
		if ($TimeZone)
		{
			# Set Time Zone
			$SetVMTemplate = $CheckVMTemplate | Set-SCVMTemplate -TimeZone $TimeZone
		}
 
		# Get Auto Logon Count
		$AutoLogonCount = $VMTemplate.AutoLogonCount
 
		if ($AutoLogonCount)
		{
			# Set Auto Logon Count
			$SetVMTemplate = $CheckVMTemplate | Set-SCVMTemplate -AutoLogonCount $AutoLogonCount
		}
 
		# Get Gui Run Once Commands
		$GuiRunOnceCommands = $VMTemplate.GuiRunOnceCommands
 
		if ($GuiRunOnceCommands)
		{
			# Create Array
			$GuiRunOnceCommandsArray = @()
 
			foreach ($GuiRunOnceCommand in $GuiRunOnceCommands)
			{
				$GuiRunOnceCommandsArray += $GuiRunOnceCommand
			}
 
			# Set Gui Run Once Commands
			$SetVMTemplate = $CheckVMTemplate | Set-SCVMTemplate -GuiRunOnceCommands $GuiRunOnceCommandsArray
		}
 
		# Get Linux Administrator SSH Key
		$LinuxAdministratorSSHKey = $VMTemplate.LinuxAdministratorSSHKey
 
		if ($LinuxAdministratorSSHKey)
		{
			# Set Linux Administrator SSH Key
			$SetVMTemplate = $CheckVMTemplate | Set-SCVMTemplate -LinuxAdministratorSSHKey $LinuxAdministratorSSHKey
		}		
 
		# Get Linux Domain Name
		$LinuxDomainName = $VMTemplate.LinuxDomainName
 
		if ($LinuxDomainName)
		{
			# Set Linux Domain Name
			$SetVMTemplate = $CheckVMTemplate | Set-SCVMTemplate -LinuxDomainName $LinuxDomainName
		}
 
		# Get Quota Point
		$QuotaPoint = $VMTemplate.QuotaPoint
 
		if ($QuotaPoint)
		{
			# Set Quota Point
			$SetVMTemplate = $CheckVMTemplate | Set-SCVMTemplate -QuotaPoint $QuotaPoint
		}
 
		# Get Tag
		$Tag = $VMTemplate.Tag
 
		if ($Tag)
		{
			# Set Tag
			$SetVMTemplate = $CheckVMTemplate | Set-SCVMTemplate -Tag $Tag
		}
 
		# Get Cost Center
		$CostCenter = $VMTemplate.CostCenter
 
		if ($CostCenter)
		{
			# Set Cost Center
			$SetVMTemplate = $CheckVMTemplate | Set-SCVMTemplate -CostCenter $CostCenter
		}
	}
}

Write-Host " "
Write-Host " "
Write-Host "Working on Host Network Adapters.."
Write-Host " "
 
# Set Host Network Adapters
foreach ($HostNetworkAdapter in $HostNetworkAdapters)
{
	Write-Host Working on $HostNetworkAdapter.Name of $HostNetworkAdapter.VMHost ..
 
	# Clear Variables
	$VMHostNetworkAdapter = $Null;
 
	# Create Job Group
	$JobGroupGuid = [System.Guid]::NewGuid().toString()
 
	# Get Host Network Adapter
	$VMHost = Get-SCVMHost -ComputerName $HostNetworkAdapter.VMHost
	$VMHostNetworkAdapter =  Get-SCVMHostNetworkAdapter -Name $HostNetworkAdapter.Name -VMHost $VMHost
 
	if ($VMHostNetworkAdapter)
	{	
		# Set Changes
		$SetVMHostNetworkAdapter = Set-SCVMHostNetworkAdapter -VMHostNetworkAdapter $VMHostNetworkAdapter -Description $HostNetworkAdapter.Description -AvailableForPlacement $HostNetworkAdapter.AvailableForPlacement -UsedForManagement $HostNetworkAdapter.UsedForManagement -JobGroup $JobGroupGuid
 
		if ($HostNetworkAdapter.NetworkLocation)
		{
			# Get Logical Network
			$LogicalNetwork = Get-SCLogicalNetwork -Name $HostNetworkAdapter.NetworkLocation
 
			if ($HostNetworkAdapter.SubnetVLans)
			{	
				# Get Subnet VLANS
				$SubnetVLANs = ($HostNetworkAdapter.SubnetVLans).Split(" ")
 
				# Create Subnet VLAN Pool
				$SubnetVLANPool = @()
 
				foreach ($SubnetVLAN in $SubnetVLANs)
				{
					$SubnetInfo = $SubnetVLAN.Split("-")
					$SubnetAddr = $SubnetInfo[0]
					$SubnetVLANID = $SubnetInfo[1]
					$SubnetVLANPool += New-SCSubnetVLan -Subnet $SubnetAddr -VLanID $SubnetVLANID
				}
 
				# Set Changes
				$SetVMHostNetworkAdapter = Set-SCVMHostNetworkAdapter -VMHostNetworkAdapter $VMHostNetworkAdapter -AddOrSetLogicalNetwork $logicalNetwork -SubnetVLan $SubnetVLANPool -JobGroup $JobGroupGuid
 
				# Set VM Host
				$SetVMHost = Set-SCVMHost -VMHost $VMHost -JobGroup $JobGroupGuid
			}
			else
			{
				# Set Changes
				$SetVMHostNetworkAdapter = Set-SCVMHostNetworkAdapter -VMHostNetworkAdapter $VMHostNetworkAdapter -AddOrSetLogicalNetwork $logicalNetwork -JobGroup $JobGroupGuid
 
				# Set VM Host
				$SetVMHost = Set-SCVMHost -VMHost $VMHost -JobGroup $JobGroupGuid
			}
		}
	}
	else
	{
		Write-Host $HostNetworkAdapter.Name is not exist on host. Please refresh your SCVMM environment.
	}
}

Write-Host " "
Write-Host " "
Write-Host "Working on Virtual Machines.."
Write-Host " "
 
# Set Virtual Machines
foreach ($VirtualMachine in $VirtualMachines)
{
	Write-Host Working on $VirtualMachine.Name ..
 
	# Clear Variables
	$VM = $Null;
 
	# Get Virtual Machine
	$VM = Get-SCVirtualMachine | Where VMId -eq $VirtualMachine.VMId
 
	if ($VM)
	{
		if ($VirtualMachine.Cloud.Name)
		{
			# Get Cloud Info
			$CloudName = $VirtualMachine.Cloud.Name
 
			# Get Cloud
			$Cloud = Get-SCCloud -Name $CloudName
 
			# Set Virtual Machine Properties
			$SetVM = $VM | Set-SCVirtualMachine -Cloud $Cloud
		}			
 
		if ($VirtualMachine.UserRole.Name)
		{
			# Get User Role Info
			$UserRoleName = $VirtualMachine.UserRole.Name
 
			# Get User Role
			$UserRole = Get-SCUserRole -Name $UserRoleName
 
			# Set Virtual Machine Properties
			$SetVM = $VM | Set-SCVirtualMachine -UserRole $UserRole
		}
 
		if ($VirtualMachine.Owner)
		{
			# Get Virtual Machine Owner Info
			$Owner = $VirtualMachine.Owner
 
			# Set Virtual Machine Properties
			$SetVM = $VM | Set-SCVirtualMachine -Owner $Owner 
		}
 
		if ($VirtualMachine.CostCenter)
		{
			# Set Virtual Machine Properties
			$SetVM = $VM | Set-SCVirtualMachine -CostCenter $VirtualMachine.CostCenter
		}
 
		if ($VirtualMachine.Description)
		{
			# Set Virtual Machine Properties
			$SetVM = $VM | Set-SCVirtualMachine -Description $VirtualMachine.Description
		}
 
		if ($VirtualMachine.Tag)
		{
			# Set Virtual Machine Properties
			$SetVM = $VM | Set-SCVirtualMachine -Tag $VirtualMachine.Tag
		}
 
		if ($VirtualMachine.QuotaPoint)
		{
			# Set Virtual Machine Properties
			$SetVM = $VM | Set-SCVirtualMachine -QuotaPoint $VirtualMachine.QuotaPoint
		}
	}
	else
	{
		Write-Host $VirtualMachine.Name is not exist on SCVMM. Please refresh your SCVMM environment.
	}
}

Write-Host " "
Write-Host " "
Write-Host "Working on Domain Join Credentials"
Write-Host " "
 
# Get Templates
$VMTemplates = Get-SCVMTemplate
 
# Set Domain
$Domain = "domain.com"
 
# Get Credentials
$DomainJoinCredential = Get-Credential
 
# Set Templates
foreach ($VMTemplate in $VMTemplates)
{
	Write-Host Working on $VMTemplate.Name properties..
 
	$SetVMTemplate = $VMTemplate | Set-SCVMTemplate -Domain $Domain -DomainJoinCredential $DomainJoinCredential
}
