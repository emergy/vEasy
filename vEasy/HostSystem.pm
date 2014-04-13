# Copyright (c) 2014, Risto Mäntylä
# All rights reserved.	
#
# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice, this
#   list of conditions and the following disclaimer in the documentation and/or
#   other materials provided with the distribution.
#
# * Neither the name of the author nor the names of its
#   contributors may be used to endorse or promote products derived from
#   this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
# ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


# ====================================================================================
# Author:	Risto Mäntylä 
#			aaremiz@gmail.com
#
# File: 	HostSystem.pm
#
# Usage: 	my $host = vEasy::HostSystem->new($vim, "host256");
# 			my $host = vEasy::HostSystem->new($vim, $host_view);
# 			my $host = vEasy::HostSystem->new($vim, $host_moref);
#			
#			where $vim is vEasy::Connect object
#
# Purpose:	This file is part of vEase Automation Framework. This class represents 
#			HostSystem in VMware vSphere infrastructure. 
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

package vEasy::HostSystem;

use strict;
use warnings;
use Data::Dumper;

our @ISA = qw(vEasy::Entity); 

# Constructor
sub new
{
	my ($class, $vim, $arg) = @_;
	
	my $self = $class->SUPER::new($vim, $arg, "HostSystem");
	
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

sub netMgr
{
	my ($self) = @_;
	
	return vEasy::HostSystemNetworkManager->new($self);
}
# ============================================================================================
# Get 
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

sub getVirtualMachines
{
	my ($self) = @_;

	my @vms = ();
	
	if( $self->getView()->vm )
	{
		for(my $i = 0; $i < scalar @{$self->getView()->vm}; ++$i)
		{
			push(@vms, vEasy::VirtualMachine->new($self->vim(), $self->getView()->vm->[$i])); 
		}
	}
	return \@vms;
}

sub getRootResourcePool
{
	my ($self) = @_;
	
	my $cluster = $self->getCluster();
	if( $cluster )
	{
		return $cluster->getRootResourcePool();
	}
	else
	{
		my $compute_resource_views = $self->vim()->findViews("ComputeResource", {name => $self->name()});
		
		for(my $i = 0; $i < @$compute_resource_views; ++$i)
		{
			my $host = $compute_resource_views->[$i]->host->[0];
			if( vEasy::HostSystem->new($self->vim(), $host)->getManagedObjectId() eq $self->getManagedObjectId() )
			{
				if( $compute_resource_views->[$i]->resourcePool )
				{
					return vEasy::ResourcePool->new($self->vim(), $compute_resource_views->[$i]->resourcePool);
				}
			}
		}
	}
	$self->addCustomFault("Couldn't find HostSystem's RootResourcePool.");
	return 0;
}

sub getCluster
{
	my ($self) = @_;

	my $parent = $self->getParent();
	if( $parent )
	{
		if( $parent->isa("vEasy::Cluster") )
		{
			return $parent;
		}
		else
		{
			$self->addCustomFault("HostSystem's parent is not a Cluster.");
		}
	}
	else
	{
		$self->addCustomFault("HostSystem has no parent.");
	}
	return 0;
}
sub getBootTime
{
	my ($self) = @_;

	if( $self->getView()->runtime->bootTime )
	{
		return $self->getView()->runtime->bootTime;
	}
	$self->addCustomFault("Couldn't get HostSystem parameter.");
	return 0;
}

sub getConnectionState
{
	my ($self) = @_;

	return $self->getView()->runtime->connectionState->val;
}

sub getPowerState
{
	my ($self) = @_;

	return $self->getView()->runtime->powerState->val;
}


sub getMaintenanceModeStatus
{
	my ($self) = @_;

	return $self->getView()->runtime->inMaintenanceMode;
}

sub getUptime
{
	my ($self) = @_;

	my $uptime = 0;
	eval
	{
		$uptime = $self->getView()->RetrieveHardwareUptime(); #secs
	};
	my $fault = vEasy::Fault->new($@);
	if( $fault )
	{
		$self->addFault($fault);
		return 0;
	}
	return $uptime;
}

sub getTotalMemoryCapacity
{
	my ($self) = @_;
	
	if( $self->getView()->summary->hardware )
	{
		return int($self->getView()->summary->hardware->memorySize / 1024 / 1024); #MB
	}
	$self->addCustomFault("Couldn't get HostSystem parameter.");
	return 0;
}

sub getMemoryUsage
{
	my ($self) = @_;
	
	if( $self->getView()->summary->quickStats->overallMemoryUsage / 1024 )
	{
		return $self->getView()->summary->quickStats->overallMemoryUsage;
	}
	$self->addCustomFault("Couldn't get HostSystem parameter.");
	return 0;
}

sub getTotalCpuCapacity
{
	my ($self) = @_;
	
	if( $self->getView()->summary->hardware )
	{
		my $ghz = $self->getView()->summary->hardware->cpuMhz * $self->getView()->summary->hardware->numCpuCores;
		return $ghz;
	}
	$self->addCustomFault("Couldn't get HostSystem parameter.");
	return 0;
}

sub getCpuUsageMhz
{
	my ($self) = @_;
	
	if( $self->getView()->summary->quickStats->overallCpuUsage )
	{
		return $self->getView()->summary->quickStats->overallCpuUsage;
	}
	$self->addCustomFault("Couldn't get HostSystem parameter.");
	return 0;
}

sub getVcenterAddress
{
	my ($self) = @_;
	
	if( $self->getView()->summary->managementServerIp )
	{
		return $self->getView()->summary->managementServerIp;
	}
	$self->addCustomFault("Couldn't get HostSystem parameter.");
	return 0;
}

# ============================================================================================
# Host State Operations
# ============================================================================================

sub enterMaintenanceMode
{
	my ($self, $evacuate, $timeout) = @_;

	if( not $evacuate )
	{
		$evacuate = 1;
	}
	
	if( not $timeout or $timeout < 0 )
	{
		$timeout = 0;
	}
	
	my $task = 0;
	eval
	{
		$task = $self->getView()->EnterMaintenanceMode_Task(evacuatePoweredOffVms => $evacuate, timeout => $timeout);
	};
	my $fault = vEasy::Fault->new($@);
	if( $fault )
	{
		$self->addFault($fault);
		return 0;
	}
	return vEasy::Task->new($self, $task);	
}

sub exitMaintenanceMode
{
	my ($self, $timeout) = @_;
	if( not $timeout or $timeout < 0 )
	{
		$timeout = 0;
	}
	my $task = 0;
	eval
	{
		$task = $self->getView()->ExitMaintenanceMode_Task(timeout => $timeout);
	};
	my $fault = vEasy::Fault->new($@);
	if( $fault )
	{
		$self->addFault($fault);
		return 0;
	}
	return vEasy::Task->new($self, $task);	

}

sub disconnect
{
	my ($self) = @_;

	my $task = 0;
	eval
	{
		$task = $self->getView()->DisconnectHost_Task();
	};
	my $fault = vEasy::Fault->new($@);
	if( $fault )
	{
		$self->addFault($fault);
		return 0;
	}
	return vEasy::Task->new($self, $task);
}

sub reconnect
{
	my ($self) = @_;
	
	my $task = 0;
	eval
	{
		$task = $self->getView()->ReconnectHost_Task();
	};
	my $fault = vEasy::Fault->new($@);
	if( $fault )
	{
		$self->addFault($fault);
		return 0;
	}
	return vEasy::Task->new($self, $task);	
}

sub reconfigureHighAvailability
{
	my ($self) = @_;

	my $task = 0;
	eval
	{
		$task = $self->getView()->ReconfigureHostForDAS_Task();
	};
	my $fault = vEasy::Fault->new($@);
	if( $fault )
	{
		$self->addFault($fault);
		return 0;
	}
	return vEasy::Task->new($self, $task);
}

# ============================================================================================
# Power status Operations
# ============================================================================================


sub reboot
{
	my ($self, $force) = @_;

	if( not $force )
	{
		$force = 0;
	}
	
	my $task = 0;
	eval 
	{ 
		$task = $self->getView()->RebootHost_Task(force => $force); 
	};
	my $fault = vEasy::Fault->new($@);
	if( $fault )
	{
		$self->addFault($fault);
		return 0;
	}
	return vEasy::Task->new($self, $task);	

}

sub shutdown
{
	my ($self, $force) = @_;

	if( not $force )
	{
		$force = 0;
	}
	my $task = 0;
	eval 
	{
		$task = $self->getView()->ShutdownHost_Task(force => $force);
	};
	my $fault = vEasy::Fault->new($@);
	if( $fault )
	{
		$self->addFault($fault);
		return 0;
	}
	return vEasy::Task->new($self, $task);	
}

sub standby
{
	my ($self, $timeout, $evacuate) = @_;

	if( not $evacuate )
	{
		$evacuate = 1;
	}
	
	my $task = 0;
	eval 
	{
		$task = $self->getView()->PowerDownHostToStandBy_Task(timeoutSec => $timeout, evacuatePoweredOffVms => $evacuate);
	};
	my $fault = vEasy::Fault->new($@);
	if( $fault )
	{
		$self->addFault($fault);
		return 0;
	}
	return vEasy::Task->new($self, $task);	

}

# ============================================================================================
# VM Operations
# ============================================================================================

sub createVirtualMachine
{
	my ($self, $name, $ds, $folder) = @_;
	
	if( $self->vim()->checkIfConnectedToHost() )
	{
		$folder = $self->vim()->getRootFolder()->getChildEntities()->[0]->getVmFolder();
	}
	 my $rp = $self->getRootResourcePool();
	
	my $cluster = $self->getCluster();
	if( $cluster )
	{
		$rp = $cluster->getRootResourcePool();
	}

	my $vm = $folder->createVirtualMachine($name, $rp, $ds);
	
	if( $vm )
	{
		return $vm;
	}
	else
	{
		$self->addFault($folder->getLatestFault());
	}
	return 0;
}

sub createVirtualApp
{
	my ($self, $name, $folder) = @_;
	
	if( $self->vim()->checkIfConnectedToHost() )
	{
		$folder = $self->vim()->getRootFolder()->getChildEntities()->[0]->getVmFolder();
	}
	
	my $rp = $self->getRootResourcePool();
	
	my $cluster = $self->getCluster();
	if( $cluster )
	{
		$rp = $cluster->getRootResourcePool();
	}

	my $vm = $rp->createVirtualApp($name, $folder);
	
	if( $vm )
	{
		return $vm;
	}
	else
	{
		$self->addFault($rp->getLatestFault());
	}
	return 0;
}

# ============================================================================================
# Storage Operations
# ============================================================================================

sub rescanStorageDevices
{
	my ($self) = @_;
	
	my $storage_sys_view = $self->vim()->getViewFromMoRef($self->getView()->configManager->storageSystem);

	eval
	{
		$storage_sys_view->RescanAllHba();
	};
	my $fault = vEasy::Fault->new($@);
	if( $fault )
	{
		$self->addFault($fault);
		return 0;
	}
	return 1;
}

sub rescanVmfsDatastores
{
	my ($self) = @_;
	
	my $storage_sys_view = $self->vim()->getViewFromMoRef($self->getView()->configManager->storageSystem);

	eval
	{
		$storage_sys_view->RescanVmfs();
	};
	my $fault = vEasy::Fault->new($@);
	if( $fault )
	{
		$self->addFault($fault);
		return 0;
	}
	return 1;
}

sub createVmfsDatastore
{
	my ($self, $device_path, $ds_name) = @_;

	my $ds_sys_view = $self->vim()->getViewFromMoRef($self->getView()->configManager->datastoreSystem);
	my $free_disks = $ds_sys_view->QueryAvailableDisksForVmfs();
	
	my $found = 0;
	for(my $i = 0; $i < scalar @$free_disks; ++$i)
	{
		if( $free_disks->[$i]->devicePath =~ m/$device_path$/i )
		{
			$device_path =  $free_disks->[$i]->devicePath;
			$found = 1;
			last;
		}
	}
	if( $found )
	{
		my $ds_opts = 0;
		eval
		{
			$ds_opts = $ds_sys_view->QueryVmfsDatastoreCreateOptions( devicePath => $device_path );
		};
		my $fault = vEasy::Fault->new($@);
		if( $fault )
		{
			$self->addFault($fault);
			return 0;
		}
		if( $ds_opts )
		{
			$ds_opts->[0]->spec->vmfs->volumeName($ds_name);
			
			my $ds_view = 0;
			eval
			{
				$ds_view = $ds_sys_view->CreateVmfsDatastore( spec => $ds_opts->[0]->spec );
			};
			my $fault = vEasy::Fault->new($@);
			if( $fault )
			{
				$self->addFault($fault);
				return 0;
			}
			return vEasy::Datastore->new($self->vim(), $ds_view);
		}
	}
	$self->addCustomFault("Device $device_path is not visible for this HostSystem.");
	return 0;
}

sub addNfsDatastore
{
	my ($self, $hostname, $path, $ds_name, $readonly) = @_;
	
	my $ds_sys_view = $self->vim()->getViewFromMoRef($self->getView()->configManager->datastoreSystem);
	
	my $mode = "readWrite";
	if( $readonly )
	{
		$mode = "readOnly";
	}
	my $nfs_spec = HostNasVolumeSpec->new(accessMode => $mode, localPath => $ds_name, remoteHost => $hostname, remotePath => $path);
	
	my $ds_view = 0;
	eval
	{
		$ds_view = $ds_sys_view->CreateNasDatastore( spec => $nfs_spec );
	};
	my $fault = vEasy::Fault->new($@);
	if( $fault )
	{
		$self->addFault($fault);
		return 0;
	}
	
	return vEasy::Datastore->new($self->vim(), $ds_view);
}

# ============================================================================================
# Network Operations
# ============================================================================================

sub getDnsServers
{
	my ($self) = @_;

	return $self->netMgr()->getDnsServers();
}

sub getHostName
{
	my ($self) = @_;

	return $self->netMgr()->getHostName();
}

sub getDomainName
{
	my ($self) = @_;

	return $self->netMgr()->getDomainName();
}

sub getDefaultGateway
{
	my ($self) = @_;

	return $self->netMgr()->getDefaultGateway();
}

sub getStandardVirtualSwitch
{
	my ($self, $name) = @_;	
	
	return vEasy::StandardVirtualSwitch->new($self, $name);
}

sub createStandardVirtualSwitch
{
	my ($self, $name, $ports) = @_;

	return $self->netMgr()->addStandardVirtualSwitch($name, $ports);
}



1;