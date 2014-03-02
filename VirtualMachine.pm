# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

# ====================================================================================
# Copyright (c) 2014 Risto Mäntylä
#
# File: 	VirtualMachine.pm
#
# Usage: 	my $vm = vEasy::VirtualMachine->new($vim, "my_dns_server_01");
# 			my $vm = vEasy::VirtualMachine->new($vim, $vm_view);
# 			my $vm = vEasy::VirtualMachine->new($vim, $vm_moref);
#			
#			where $vim is vEasy::Connect object
#
# Purpose:	This file is part of vEase Automation Framework. This class represents 
#			VirtualMachine in VMware vSphere infrastructure.
#
# vEasy Documentation
# https://github.com/aaremiz/vEasy/wiki
#
# VMware vSphere API Reference:
# https://www.vmware.com/support/developer/vc-sdk/
# 
# VMware vSphere SDK for Perl Documentation:
# https://www.vmware.com/support/developer/viperltoolkit/
#
# ====================================================================================

package vEasy::VirtualMachine;

use strict;
use warnings;

use Data::Dumper;

our @ISA = qw(vEasy::Entity); 

# Constructor
sub new
{
	my ($class, $vim, $arg) = @_;
	
	my $self = $class->SUPER::new($vim, $arg, "VirtualMachine" );
	
	if( $self )
	{
		bless ($self, $class);
		return $self;
	}
	return 0;
}

# Destructor
sub DESTROY 
{
	my ($self) = @_;
	
}

# ============================================================================================
# GETs 
# ============================================================================================

sub getNetworks
{
	my ($self) = @_;

	my @networks = ();
	
	if( $self->getView()->network )
	{
		for(my $i = 0; $i < scalar @{$self->getView()->network}; ++$i)
		{
			push(@networks, vEasy::Network->new($self->vim(), $self->getView()->network->[$i])); 
		}
	}
	return \@networks;
}

sub getDatastores
{
	my ($self) = @_;

	my @datastores = ();
	
	if( $self->getView()->datastore )
	{
		for(my $i = 0; $i < scalar @{$self->getView()->datastore}; ++$i)
		{
			push(@datastores, vEasy::Datastore->new($self->vim(), $self->getView()->datastore->[$i])); 
		}
	}
	return \@datastores;
}


sub getResourcePool
{
	my ($self) = @_;
	
	return vEasy::ResourcePool->new($self->vim(), $self->getView()->resourcePool);
}

sub getCluster
{
	my ($self) = @_;
	
	my $owner = $self->getResourcePool()->getOwner();
	
	if( $owner->isa("vEasy::Cluster") )
	{
		return $owner;
	}
	$self->addCustomFault("Virtual machine is not running in a Cluster.");
	return 0;
}

sub getHost
{
	my ($self) = @_;
	
	return vEasy::HostSystem->new($self->vim(), $self->getView()->runtime->host);
}

sub checkIfToolsRunning
{
	my ($self) = @_;
	
	if( $self->getView()->guest )
	{
		if( $self->getView()->guest->toolsRunningStatus eq "guestToolsRunning" )
		{
			return 1;
		}
	}
	$self->addCustomFault("Couln't get VirtualMachine parameter.");
	return 0;
}

sub checkIfPoweredOn
{
	my ($self) = @_;
	
	if( $self->getPowerState() eq "poweredOn" )
	{
		return 1;
	}
	return 0;
}

sub getNotes
{
	my ($self) = @_;
	
	if( $self->getView()->config->annotation )
	{
		return $self->getView()->config->annotation;
	}
	$self->addCustomFault("Couln't get VirtualMachine parameter.");
	return 0;
}

sub getPowerState
{
	my ($self) = @_;
	
	return $self->{view}->runtime->powerState->val;
}

sub getPowerOnDate
{
	my ($self) = @_;

	if( defined $self->getView()->runtime->bootTime )
	{
		return $self->getView()->runtime->bootTime;
	}
	$self->addCustomFault("Couln't get VirtualMachine parameter.");
	return 0;
}

sub getMemory
{
	my ($self) = @_;

	return $self->getView()->config->hardware->memoryMB;
}

sub getCpuSockets
{
	my ($self) = @_;
	
	my $sockets = $self->getView()->config->hardware->numCPU / $self->getView()->config->hardware->numCoresPerSocket;
	return $sockets;
}

sub getCpuCores
{
	my ($self) = @_;
	
	if( $self->getView()->config->hardware->numCoresPerSocket )
	{
		return $self->getView()->config->hardware->numCoresPerSocket;
	}
	return 1;
}

sub getVirtualHardwareVersion
{
	my ($self) = @_;

	return $self->getView()->config->version;
}

sub getGuestOperatingSystemType
{
	my ($self) = @_;

	return $self->getView()->config->guestId;
}

sub getVirtualDevice
{
	my ($self, $name) = @_;
	
	$self->refresh();
	
	my $vm_devices = $self->{view}->config->hardware->device;
	for(my $i= 0; $i < scalar @$vm_devices; ++$i) 
	{
		if($vm_devices->[$i]->deviceInfo->label =~ m/$name/) 
		{
			return $vm_devices->[$i];
		}
	}
	$self->addCustomFault("VirtualMachine device was not found.");
	return 0;
}

sub getTotalUsedDiskSize
{
	my ($self) = @_;

	my $datastore_usages = $self->getView()->storage->perDatastoreUsage;
	if( $datastore_usages )
	{
		my $used = 0;
		
		for(my $i = 0; $i < scalar @$datastore_usages; ++$i)
		{
			$used += $datastore_usages->[$i]->committed;
		}
		return int($used/1024/1024); #MB
	}
	$self->addCustomFault("Couln't get VirtualMachine parameter.");
	return 0;
}

sub getTotalAllocatedDiskSize
{
	my ($self) = @_;

	my $datastore_usages = $self->getView()->storage->perDatastoreUsage;
	if( $datastore_usages )
	{
		my $total = 0;
		
		for(my $i = 0; $i < scalar @$datastore_usages; ++$i)
		{
			$total += ($datastore_usages->[$i]->committed + $datastore_usages->[$i]->uncommitted);
		}
		return int($total/1024/1024); #MB
	}
	$self->addCustomFault("Couln't get VirtualMachine parameter.");
	return 0;
}

# ============================================================================================
# Guest OS Operations
# ============================================================================================

sub getGuestHostname
{
	my ($self) = @_;

	if( $self->getView()->guest )
	{
		if( $self->getView()->guest->hostName )
		{
			return $self->getView()->guest->hostName;
		}
	}
	$self->addCustomFault("Couln't get VirtualMachine parameter.");
	return 0;
}

sub getGuestIpAddress
{
	my ($self) = @_;

	if( $self->getView()->guest )
	{
		if( $self->getView()->guest->ipAddress )
		{
			return $self->getView()->guest->ipAddress;
		}
	}
	$self->addCustomFault("Couln't get VirtualMachine parameter.");
	return 0;
}

# ============================================================================================
# Power State Modifications
# ============================================================================================

sub powerOn
{
	my ($self) = @_;
	
	my $task = 0;
	eval
	{
		$task = $self->getView()->PowerOnVM_Task();
	};
	my $fault = vEasy::Fault->new($@);
	if( $fault )
	{
		$self->addFault($fault);
		return 0;
	}
	return vEasy::Task->new($self, $task);
}

sub powerOff
{
	my ($self) = @_;

	my $task = 0;
	eval
	{
		$task = $self->getView()->PowerOffVM_Task();
	};
	my $fault = vEasy::Fault->new($@);
	if( $fault )
	{
		$self->addFault($fault);
		return 0;
	}
	return vEasy::Task->new($self, $task);
}

sub suspend
{
	my ($self) = @_;

	my $task = 0;
	eval
	{
		$task = $self->getView()->SuspendVM_Task();
	};
	my $fault = vEasy::Fault->new($@);
	if( $fault )
	{
		$self->addFault($fault);
		return 0;
	}
	return vEasy::Task->new($self, $task);
}

sub reset
{
	my ($self) = @_;
	
	my $task = 0;
	eval
	{
		$task = $self->getView()->ResetVM_Task();
	};
	my $fault = vEasy::Fault->new($@);
	if( $fault )
	{
		$self->addFault($fault);
		return 0;
	}
	return vEasy::Task->new($self, $task);
}

sub reboot
{
	my ($self) = @_;
	
	eval
	{
		$self->getView()->RebootGuest();
	};
	my $fault = vEasy::Fault->new($@);
	if( $fault )
	{
		$self->addFault($fault);
		return 0;
	}
	return 1;
}

sub shutdown
{
	my ($self) = @_;
	
	eval
	{
		$self->getView()->ShutdownGuest();
	};
	my $fault = vEasy::Fault->new($@);
	if( $fault )
	{
		$self->addFault($fault);
		return 0;
	}
	return 1;

}

# ============================================================================================
# Snapshot Operations
# ============================================================================================

sub takeSnapshot
{
	my ($self, $name, $description, $mem, $quiesce) = @_;
	
	my $task = 0;
	eval
	{
		$task = $self->getView()->CreateSnapshot_Task(name => $name, description => $description, memory => $mem, quiesce => $quiesce);
	};
	my $fault = vEasy::Fault->new($@);
	if( $fault )
	{
		$self->addFault($fault);
		return 0;
	}
	return vEasy::Task->new($self, $task);

}

sub revertToCurrentSnapshot
{
	my ($self) = @_;
	
	my $task = 0;
	eval
	{
		$task = $self->getView()->RevertToCurrentSnapshot_Task();
	};
	my $fault = vEasy::Fault->new($@);
	if( $fault )
	{
		$self->addFault($fault);
		return 0;
	}
	return vEasy::Task->new($self, $task);
}

sub removeSnapshots
{
	my ($self) = @_;
	
	my $task = 0;
	eval
	{
		$task = $self->getView()->RemoveAllSnapshots_Task();
	};
	my $fault = vEasy::Fault->new($@);
	if( $fault )
	{
		$self->addFault($fault);
		return 0;
	}
	return vEasy::Task->new($self, $task);

	return 0;
}

# ============================================================================================
# General Operations
# ============================================================================================

sub upgradeVirtualHardware
{
	my ($self, $version) = @_;

	my $task = 0;
	eval
	{	
		if( $version )
		{
			$task = vEasy::Task->new($self, $self->getView()->UpgradeVM_Task(version => $version));
		}
		$task = vEasy::Task->new($self, $self->getView()->UpgradeVM_Task());
	};
	my $fault = vEasy::Fault->new($@);
	if( $fault )
	{
		$self->addFault($fault);
		return 0;
	}
	return vEasy::Task->new($self, $task);
}

sub removeFromInventory
{
	my ($self) = @_;

	eval
	{
		$self->getView()->UnregisterVM();
	};
	my $fault = vEasy::Fault->new($@);
	if( $fault )
	{
		$self->addFault($fault);
		return 0;
	}
	return 1;
}

# sub clone
# {
	# my ($self, $newname, $folder, $rp, $ds) = @_;

	# my $vm_relocate_spec = VirtualMachineRelocateSpec->new(datastore => $ds->getView(), 
															# pool => $rp->getView(), 
															# transform => VirtualMachineRelocateTransformation->new('sparse') );
	# my $vm_clone_spec = VirtualMachineCloneSpec->new(location => $vm_relocate_spec,
													# powerOn => 0, template => 0);
	
	# return 
	
	# my $task = 0;
	# eval
	# {
		# $task = $self->{view}->CloneVM_Task(folder => $folder->getView(), name => $newname, spec => $vm_clone_spec);
	# };
	# my $fault = vEasy::Fault->new($@);
	# if( $fault )
	# {
		# $self->addFault($fault);
		# return 0;
	# }
	# return vEasy::Task->new($self, $task);
# }

sub migrate
{
	my ($self, $host, $rp) = @_;

	if( $host->isa("vEasy::HostSystem") )
	{	
		if( not $rp or not $rp->isa("vEasy::ResourcePool") )
		{
			$rp = $self->getResourcePool();
		}
		my $task = 0;
		eval
		{
			$task = $self->{view}->MigrateVM_Task(host => $host->getView(), pool => $rp->getView(), priority => VirtualMachineMovePriority->new('highPriority'));
		};
		my $fault = vEasy::Fault->new($@);
		if( $fault )
		{
			$self->addFault($fault);
			return 0;
		}
		return vEasy::Task->new($self, $task);
	}
	$self->addCustomFault("Invalid function argument - host");
	return 0;
}

sub relocate
{
	my ($self, $ds, $rp) = @_;

	if( $ds->isa("vEasy::Datastore") )
	{
		if( not $rp or not $rp->isa("vEasy::ResourcePool") )
		{
			$rp = $self->getResourcePool();
		}
		my $vm_relocate_spec = VirtualMachineRelocateSpec->new(datastore => $ds->getView(), pool =>$rp->getView(), transform => VirtualMachineRelocateTransformation->new('sparse') );
	
		my $task = 0;
		eval
		{
			$task = $self->{view}->RelocateVM_Task(spec => $vm_relocate_spec, priority => VirtualMachineMovePriority->new('highPriority'));
		};
		my $fault = vEasy::Fault->new($@);
		if( $fault )
		{
			$self->addFault($fault);
			return 0;
		}
		return vEasy::Task->new($self, $task);
	}
	$self->addCustomFault("Invalid function argument - ds");
	return 0;
}

# ============================================================================================
# Hardware Configuration Modifications
# ============================================================================================

sub configure
{
	my ($self, $spec) = @_;

	if( $spec->isa("VirtualMachineConfigSpec") )
	{
		my $task = 0;
		eval
		{
			$task = $self->getView()->ReconfigVM_Task(spec => $spec);
		};
		my $fault = vEasy::Fault->new($@);
		if( $fault )
		{
			$self->addFault($fault);
			return 0;
		}
		return vEasy::Task->new($self, $task);
	}
	$self->addCustomFault("Invalid function argument - spec");
	return 0;
}

sub setCpusAndCores
{
	my ($self, $cpus, $cores) = @_;

	my $config_spec = VirtualMachineConfigSpec->new(numCPUs => $cpus*$cores, numCoresPerSocket => $cores);

	return $self->configure($config_spec);
}

sub setMemory
{
	my ($self, $mem_MB) = @_;

	my $config_spec = VirtualMachineConfigSpec->new(memoryMB => $mem_MB);

	return $self->configure($config_spec);
}

sub setGuestOperatingSystemType
{
	my ($self, $os) = @_;

	my $config_spec = VirtualMachineConfigSpec->new(guestId => $os );

	return $self->configure($config_spec);
}

sub setNotes
{
	my ($self, $notes) = @_;
	my $config_spec = VirtualMachineConfigSpec->new(annotation => $notes);
	
	return $self->configure($config_spec);
}

sub addDiskController
{
	my ($self, $controller) = @_;
	
	if( not $self->getVirtualDevice("SCSI controller $controller->{busNumber}") )
	{
		my $dev_conf_spec = VirtualDeviceConfigSpec->new(device => $controller, operation => VirtualDeviceConfigSpecOperation->new("add") );

		my $vm_conf_spec = VirtualMachineConfigSpec->new(deviceChange => [$dev_conf_spec]);
		
		return $self->configure($vm_conf_spec);
	}
	$self->addCustomFault("Device not found - SCSI controller $controller->{busNumber}");	
	return 0;
}	

sub addSasScsiController
{
	my ($self, $bus) = @_;
	
	my $controller = VirtualLsiLogicSASController->new(key => -1, busNumber => $bus, sharedBus => VirtualSCSISharing->new("noSharing"));
		
	return $self->addDiskController($controller);
}	

sub addLsiLogicScsiController
{
	my ($self, $bus) = @_;
	
	my $controller = VirtualLsiLogicController->new(key => -1, busNumber => $bus, sharedBus => VirtualSCSISharing->new("noSharing"));
		
	return $self->addDiskController($controller);
}	

sub addBusLogicScsiController
{
	my ($self, $bus) = @_;
	
	my $controller = VirtualBusLogicController->new(key => -1, busNumber => $bus, sharedBus => VirtualSCSISharing->new("noSharing"));
		
	return $self->addDiskController($controller);
}	

sub addParavirtualScsiController
{
	my ($self, $bus) = @_;
	
	my $controller = ParaVirtualSCSIController->new(key => -1, busNumber => $bus, sharedBus => VirtualSCSISharing->new("noSharing"));
		
	return $self->addDiskController($controller);
}	

sub setScsiControllerSharing
{
	my ($self, $controllername, $sharemode) = @_;
	
	my $controller = $self->getVirtualDevice($controllername);
	if( $controller )
	{
		$controller->{sharedBus} = VirtualSCSISharing->new($sharemode);
		
		my $dev_conf_spec = VirtualDeviceConfigSpec->new(device => $controller, operation => VirtualDeviceConfigSpecOperation->new("edit") );

		my $vm_conf_spec = VirtualMachineConfigSpec->new(deviceChange => [$dev_conf_spec]);
		
		return $self->configure($vm_conf_spec);
	}
	$self->addCustomFault("Device not found - $controllername");
	return 0;
}

sub setScsiControllerModeToNoSharing
{
	my ($self, $controllername) = @_;
	
	return $self->setScsiControllerSharing($controllername, "noSharing");
}

sub setScsiControllerModeToVirtualSharing
{
	my ($self, $controllername) = @_;
	
	return $self->setScsiControllerSharing($controllername, "virtualSharing");
}

sub setScsiControllerModeToPhysicalSharing
{
	my ($self, $controllername) = @_;
	
	return $self->setScsiControllerSharing($controllername, "physicalSharing");
}

sub addUsbController
{
	my ($self) = @_;
	
	if( not $self->getVirtualDevice("USB controller") )
	{
		my $usb_device = VirtualUSBController->new(busNumber => 0, key => -1, autoConnectDevices => 1, ehciEnabled => 1);
		
		my $dev_conf_spec = VirtualDeviceConfigSpec->new(device => $usb_device, operation => VirtualDeviceConfigSpecOperation->new("add") );

		my $vm_conf_spec = VirtualMachineConfigSpec->new(deviceChange => [$dev_conf_spec]);
		
		return $self->configure($vm_conf_spec);
	}
	$self->addCustomFault("Device already exists - USB controller.");
	return 0;
}

sub addUsbXhciController
{
	my ($self) = @_;
	
	if( not $self->getVirtualDevice("USB xHCI controller") )
	{
		my $usb_device = VirtualUSBXHCIController->new(busNumber => 0, key => -1, autoConnectDevices => 1);
		
		my $dev_conf_spec = VirtualDeviceConfigSpec->new(device => $usb_device, operation => VirtualDeviceConfigSpecOperation->new("add") );

		my $vm_conf_spec = VirtualMachineConfigSpec->new(deviceChange => [$dev_conf_spec]);
		
		return $self->configure($vm_conf_spec);
	}
	$self->addCustomFault("Device already exists - USB xHCI controller.");
	return 0;
}

sub addVirtualDisk
{
	my ($self, $controller_name, $device_number, $size, $thin, $eagerzeroed) = @_;
	
	if( $size > 0 )
	{
		my $disksize = $size * 1048576; # Gigabytes
		
		my $controller = $self->getVirtualDevice($controller_name);
		if( $controller )
		{
			my $disk_name = $self->name();
			if( $device_number >= 1 )
			{
				$disk_name .= "\_$device_number";
			}
			my $path = $self->getView()->config->files->vmPathName;
			$path =~ /^(\[.*\] .+)\/.*\.vmx/;
			my $disk_filepath = "$1/$disk_name.vmdk";
			
			my $backing_info = VirtualDiskFlatVer2BackingInfo->new(diskMode => "persistent", fileName => $disk_filepath, thinProvisioned => $thin, eagerlyScrub => $eagerzeroed);
			
			my $vdisk = VirtualDisk->new(controllerKey => $controller->key, unitNumber => $device_number, key => -1, backing => $backing_info, capacityInKB => $disksize);

			my $dev_conf_spec = VirtualDeviceConfigSpec->new(device => $vdisk, operation => VirtualDeviceConfigSpecOperation->new("add"), fileOperation => VirtualDeviceConfigSpecFileOperation->new('create') );

			my $vm_conf_spec = VirtualMachineConfigSpec->new(deviceChange => [$dev_conf_spec]);
			
			return $self->configure($vm_conf_spec);
		}
		else
		{
			$self->addCustomFault("Device not found - $controller_name.");
		}
	}
	else
	{
		$self->addCustomFault("Invalid funtion argument - size.");
	}
	return 0;
}

sub addThinVirtualDisk
{
	my ($self, $controller_name, $device_number, $size) = @_;
	
	return $self->addVirtualDisk($controller_name, $device_number, $size, 1, 0);
}

sub addLazyZeroedVirtualDisk
{
	my ($self, $controller_name, $device_number, $size) = @_;
	
	return $self->addVirtualDisk($controller_name, $device_number, $size, 0, 0);
}

sub addEagerlyZeroedVirtualDisk
{
	my ($self, $controller_name, $device_number, $size) = @_;
	
	return $self->addVirtualDisk($controller_name, $device_number, $size, 0, 1);
}

sub addFloppyDrive
{
	my ($self) = @_;

	my $backing_info = VirtualFloppyRemoteDeviceBackingInfo->new(deviceName => '', useAutoDetect => 0);
	
	my $floppy = VirtualFloppy->new(backing => $backing_info, key => -1);
	
	my $dev_conf_spec = VirtualDeviceConfigSpec->new(device => $floppy, operation =>VirtualDeviceConfigSpecOperation->new('add') );
	
	my $vm_conf_spec = VirtualMachineConfigSpec->new(deviceChange => [$dev_conf_spec]);

	return $self->configure($vm_conf_spec);	

}

sub addCdDvdDrive
{
	my ($self, $ide_controller, $device_number) = @_;

	my $controller = $self->getVirtualDevice($ide_controller);
	if( $controller )
	{
		my $backing_info = VirtualCdromRemotePassthroughBackingInfo->new(exclusive => 0, deviceName => '', useAutoDetect => 0);
		
		my $cddvd = VirtualCdrom->new(controllerKey => $controller->key, unitNumber => $device_number, backing => $backing_info, key => -1);
		
		my $dev_conf_spec = VirtualDeviceConfigSpec->new(device => $cddvd, operation =>VirtualDeviceConfigSpecOperation->new('add') );
		my $vm_conf_spec = VirtualMachineConfigSpec->new(deviceChange => [$dev_conf_spec]);

		return $self->configure($vm_conf_spec);	
	}
	$self->addCustomFault("Device not found - $ide_controller.");
	return 0;
}

sub addNetworkAdapter
{
	my ($self, $adapter) = @_;
	
	if( $adapter->isa("VirtualE1000") or $adapter->isa("VirtualE1000e") or $adapter->isa("VirtualPCNet32") or $adapter->isa("VirtualVmxnet3") )
	{
		my $dev_conf_spec = VirtualDeviceConfigSpec->new(device => $adapter, operation =>VirtualDeviceConfigSpecOperation->new('add') );
		my $vm_conf_spec = VirtualMachineConfigSpec->new(deviceChange => [$dev_conf_spec]);

		return $self->configure($vm_conf_spec);
	}
	$self->addCustomFault("Invalid function argument - adapter.");
	return 0;
}

sub generateNetworkAdapterBackingInfo
{
	my ($self, $network) = @_;
	
	my $backing_info = VirtualEthernetCardNetworkBackingInfo->new( deviceName => $network->name(), network => $network->getView());
	
	if( $network->isa("vEasy::DistributedVirtualPortgroup") )
	{
		my $port_connection = DistributedVirtualSwitchPortConnection->new(portgroupKey => $network->getKey(), switchUuid => $network->getDistributedVirtualSwitch()->getUuid());
		$backing_info = VirtualEthernetCardDistributedVirtualPortBackingInfo->new(port => $port_connection);
	}
	return $backing_info;
}

sub addE1000NetworkAdapter
{
	my ($self, $network) = @_;
	
	my $backing_info = $self->generateNetworkAdapterBackingInfo($network);
	
	my $adapter = VirtualE1000->new(backing => $backing_info, key => -1);
	
	return $self->addNetworkAdapter($adapter);
}

sub addE1000eNetworkAdapter
{
	my ($self, $network) = @_;
	
	my $backing_info = $self->generateNetworkAdapterBackingInfo($network);
	
	my $adapter = VirtualE1000e->new(backing => $backing_info, key => -1);
	
	return $self->addNetworkAdapter($adapter);
}

sub addFlexibleNetworkAdapter
{
	my ($self, $network) = @_;
	
	my $backing_info = $self->generateNetworkAdapterBackingInfo($network);
	
	my $adapter = VirtualPCNet32->new(backing => $backing_info, key => -1);
	
	return $self->addNetworkAdapter($adapter);
}

sub addVmxnet3NetworkAdapter
{
	my ($self, $network) = @_;
	
	my $backing_info = $self->generateNetworkAdapterBackingInfo($network);
	
	my $adapter = VirtualVmxnet3->new(backing => $backing_info, key => -1);
	
	return $self->addNetworkAdapter($adapter);
}

sub setVirtualDiskMode
{
	my ($self, $diskname, $independent, $persistent) = @_;
	
	my $vdisk = $self->getVirtualDevice($diskname);
	if( $vdisk )
	{
		my $mode1 = "";
		my $mode2 = "persistent";
		
		if( $independent )
		{
			$mode1 = "independent_";
			
			if( not $persistent )
			{
				$mode2 = "nonpersistent"
			}
		}
		my $mode = "$mode1$mode2";
		
		$vdisk->{backing}->{diskMode} = $mode;	
		my $dev_conf_spec = VirtualDeviceConfigSpec->new(device => $vdisk, operation => VirtualDeviceConfigSpecOperation->new("edit") );

		my $vm_conf_spec = VirtualMachineConfigSpec->new(deviceChange => [$dev_conf_spec]);
		
		return $self->configure($vm_conf_spec);
	}
	$self->addCustomFault("Device not found - $diskname.");
	return 0;
}

sub setVirtualDiskModeToPersistent
{
	my ($self, $diskname) = @_;
	
	return $self->setVirtualDiskMode($diskname, 0, 0);
}

sub setVirtualDiskModeToIndependentPersistent
{
	my ($self, $diskname) = @_;
	
	return $self->setVirtualDiskMode($diskname, 1, 1);
}

sub setVirtualDiskModeToIndependentNonPersistent
{
	my ($self, $diskname) = @_;
	
	return $self->setVirtualDiskMode($diskname, 1, 0);
}

sub deleteVirtualDevice
{
	my ($self, $dev_name) = @_;
	
	my $device = $self->getVirtualDevice($dev_name);
	
	if( $device )
	{
		my $dev_conf_spec = VirtualDeviceConfigSpec->new(device => $device, fileOperation => VirtualDeviceConfigSpecFileOperation->new('destroy'), operation =>VirtualDeviceConfigSpecOperation->new('remove') );

		my $vm_conf_spec = VirtualMachineConfigSpec->new(deviceChange => [$dev_conf_spec]);

		return $self->configure($vm_conf_spec);
	}
	$self->addCustomFault("Device not found - $dev_name.");
	return 0;
}







1;