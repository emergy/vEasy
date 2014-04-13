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
# File: 	VirtualApp.pm
#
# Usage: 	my $vapp = vEasy::VirtualApp->new($vim, "MyWebApp");
# 			my $vapp = vEasy::VirtualApp->new($vim, $vapp_view);
# 			my $vapp = vEasy::VirtualApp->new($vim, $vapp_moref);
#			
#			where $vim is vEasy::Connect object
#
# Purpose:	This file is part of vEase Automation Framework. This class represents 
#			VirtualApp in VMware vSphere infrastructure.
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


package vEasy::VirtualApp;

use strict;
use warnings;
use Data::Dumper;
use vEasy::ResourcePool;

our @ISA = qw(vEasy::ResourcePool); 

# Constructor
sub new
{
	my ($class, $vim, $arg) = @_;
	
	my $self = $class->SUPER::new($vim, $arg, "VirtualApp" );
	
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

sub getParentVirtualApp
{
	my ($self) = @_;
	
	if( $self->getView()->parentVApp )
	{
		return vEasy::VirtualApp->new($self->vim(), $self->getView()->parentVApp);
	}
	$self->addCustomFault("Parent vApp is not avalaible, this is root vApp.");	
	return 0;
}

sub getParentFolder
{
	my ($self) = @_;
	
	my $parentvapp = $self->getParentVirtualApp();
	if( $parentvapp )
	{
		return vEasy::Folder->new($self->vim(), $parentvapp->getView()->parentFolder);
	}
	return vEasy::Folder->new($self->vim(), $self->getView()->parentFolder);
}

sub getNotes
{
	my ($self) = @_;
	
	if( $self->getView()->vAppConfig )
	{
		return $self->getView()->vAppConfig->annotation;
	}
	$self->addCustomFault("vApp config not available.");
	return 0;
}

sub getUuid
{
	my ($self) = @_;
	
	if( $self->getView()->vAppConfig )
	{
		if( $self->getView()->vAppConfig->instanceUuid )
		{
			return $self->getView()->vAppConfig->instanceUuid;
		}
	}
	$self->addCustomFault("vApp config not available.");
	return 0;
}

sub getProductApplicationUrl
{
	my ($self) = @_;

	if( $self->getView()->summary->product )
	{
		if( $self->getView()->summary->product->appUrl )
		{
			return $self->getView()->summary->product->appUrl;
		}
	}
	$self->addCustomFault("vApp parameter not available - appUrl.");
	return 0;
}

sub getProductFullVersion
{
	my ($self) = @_;
	
	if( $self->getView()->summary->product )
	{
		if( $self->getView()->summary->product->fullVersion )
		{
			return $self->getView()->summary->product->fullVersion;
		}
	}
	$self->addCustomFault("vApp parameter not available - fullVersion.");
	return 0;
}

sub getProductName
{
	my ($self) = @_;
	
	if( $self->getView()->summary->product )
	{
		if( $self->getView()->summary->product->name )
		{
			return $self->getView()->summary->product->name;
		}
	}
	$self->addCustomFault("vApp parameter not available - name.");
	return 0;
}

sub getProductUrl
{
	my ($self) = @_;
	
	if( $self->getView()->summary->product )
	{
		if( $self->getView()->summary->product->productUrl )
		{
			return $self->getView()->summary->product->productUrl;
		}
	}
	$self->addCustomFault("vApp parameter not available - productUrl.");
	return 0;
}

sub getProductVendor
{
	my ($self) = @_;
	
	if( $self->getView()->summary->product )
	{
		if( $self->getView()->summary->product->vendor )
		{
			return $self->getView()->summary->product->vendor;
		}
	}
	$self->addCustomFault("vApp parameter not available - vendor.");
	return 0;
}

sub getProductVendorUrl
{
	my ($self) = @_;
	
	if( $self->getView()->summary->product )
	{
		if( $self->getView()->summary->product->vendorUrl )
		{
			return $self->getView()->summary->product->vendorUrl;
		}
	}
	$self->addCustomFault("vApp parameter not available - vendorUrl.");
	return 0;
}

sub getProductVersion
{
	my ($self) = @_;
	
	if( $self->getView()->summary->product )
	{
		if( $self->getView()->summary->product->version )
		{
			return $self->getView()->summary->product->version;
		}
	}
	$self->addCustomFault("vApp parameter not available - version.");
	return 0;
}

sub powerOn
{
	my ($self) = @_;
	
	my $task = 0;
	eval
	{
		$task = $self->getView()->PowerOnVApp_Task();
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
	my ($self, $force) = @_;
	
	if( not $force )
	{
		$force = 0;
	}
	
	my $task = 0;
	eval
	{
		$task = $self->getView()->PowerOffVApp_Task(force => $force);
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
		$task = $self->getView()->SuspendVApp_Task();
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
	
	my $task = 0;
	eval
	{
		$task = $self->getView()->unregisterVApp_Task();
	};
	my $fault = vEasy::Fault->new($@);
	if( $fault )
	{
		$self->addFault($fault);
		return 0;
	}
	return vEasy::Task->new($self, $task);
}

sub addChildEntity
{
	my ($self, $entity) = @_;	

	if( $entity->isa("vEasy::VirtualMachine") or $entity->isa("vEasy::VirtualApp") )
	{
		return $self->moveEntityToResourcePool($entity);
	}
	$self->addCustomFault("Invalid function parameter - entity.");
	return 0;
}

sub createVirtualMachine
{
	my ($self, $name, $ds) = @_;

	if( $ds->isa("vEasy::Datastore") )
	{	
		my $vmpath = "[".$ds->name()."] $name/$name.vmx";

		my $files_info = VirtualMachineFileInfo->new(vmPathName => $vmpath);
		
		my $vm_conf_spec = VirtualMachineConfigSpec->new(name => $name, numCPUs => 1, numCoresPerSocket => 1, memoryMB => 32, files => $files_info, guestId => "winNetStandardGuest");	
		
		my $vm = 0;
		eval
		{
			$vm = $self->getView()->CreateChildVM(config => $vm_conf_spec);
		};
		my $fault = vEasy::Fault->new($@);
		if( $fault )
		{
			$self->addFault($fault);
			return 0;
		}
		
		return vEasy::VirtualMachine->new($self->vim(), $vm);
	}
	$self->addCustomFault("Invalid function arguments.");
	return 0;
}

sub configure
{
	my ($self, $spec) = @_;

	if( $spec->isa("VAppConfigSpec") )
	{
		eval
		{
			$self->getView()->UpdateVAppConfig(spec => $spec);
		};
		my $fault = vEasy::Fault->new($@);
		if( $fault )
		{
			$self->addFault($fault);
			return 0;
		}
		return 1;
	}
	$self->addCustomFault("Invalid function argument - spec");
	return 0;
}

sub setNotes
{
	my ($self, $notes) = @_;
	
	my $spec = VAppConfigSpec->new(annotation => $notes);
	
	return $self->configure($spec);
}

sub configureProductSpecs
{
	my ($self, $key, $value) = @_;

	my $product_info = 	VAppProductInfo->new($key => $value, key => 0);
	my $product_spec = VAppProductSpec->new(info => $product_info, operation => ArrayUpdateOperation->new("edit"));
	my $spec = VAppConfigSpec->new(product => [$product_spec]);	
	
	return $self->configure($spec);	
}

sub setProductFullVersion
{
	my ($self, $version) = @_;
	
	return $self->configureProductSpecs("fullVersion", $version);
}

sub setProductVersion
{
	my ($self, $version) = @_;
	
	return $self->configureProductSpecs("version", $version);
}

sub setProductName
{
	my ($self, $name) = @_;
	
	return $self->configureProductSpecs("name", $name);
}

sub setProductVendor
{
	my ($self, $vendor) = @_;
	
	return $self->configureProductSpecs("vendor", $vendor);
}

sub setProductUrl
{
	my ($self, $url) = @_;
	
	return $self->configureProductSpecs("productUrl", $url);
}

sub setProductVendorUrl
{
	my ($self, $url) = @_;
	
	return $self->configureProductSpecs("vendorUrl", $url);
}

sub setProductApplicationUrl
{
	my ($self, $url) = @_;
	
	return $self->configureProductSpecs("appUrl", $url);
}

sub configureChildSpecs
{
	my ($self, $entity, $key, $value) = @_;
	
	if( $entity->isa("vEasy::VirtualMachine") or $entity->isa("vEasy::VirtualApp") )
	{
		if( $self->getView()->vAppConfig )
		{
			my $childspecs = $self->getView()->vAppConfig->entityConfig;

			if( $childspecs )
			{
				for(my $i = 0; $i < @$childspecs; ++$i)
				{
					my $child = vEasy::Entity->new($self->vim(), $childspecs->[$i]->key, $childspecs->[$i]->key->type);
					if( $entity->getManagedObjectId() eq $child->getManagedObjectId() )
					{
						$childspecs->[$i]->{$key} = $value;
						my $spec = VAppConfigSpec->new(entityConfig => $childspecs);
						return $self->configure($spec);					
					}
				}
				$self->addCustomFault("Entity is not child of this VirtualApp.");
				return 0;
			}
			else
			{
				$self->addCustomFault("VirtualApp doesn't have child VirtualMachines/VirtualApps.");
				return 0;
			}
		}
		else
		{
			$self->addCustomFault("Failed to get VirtualApp child configuration.");
			return 0;		
		}
	}
	$self->addCustomFault("Invalid function parameter - entity.");
	return 0;
}

sub setChildStartupOrder
{
	my ($self, $entity, $order) = @_;
	
	return $self->configureChildSpecs($entity, "startOrder", $order);
}

sub setChildStartActionToPowerOn
{
	my ($self, $entity) = @_;
	
	return $self->configureChildSpecs($entity, "startAction", "powerOn");
}

sub setChildStartActionToNone
{
	my ($self, $entity) = @_;
	
	return $self->configureChildSpecs($entity, "startAction", "none");
}

sub setChildStopActionToPowerOff
{
	my ($self, $entity) = @_;
	
	return $self->configureChildSpecs($entity, "stopAction", "powerOff");
}

sub setChildStopActionToNone
{
	my ($self, $entity) = @_;
	
	return $self->configureChildSpecs($entity, "stopAction", "none");
}

sub setChildStopActionToShutdown
{
	my ($self, $entity) = @_;
	
	return $self->configureChildSpecs($entity, "stopAction", "guestShutdown");
}

sub setChildStopActionToSuspend
{
	my ($self, $entity) = @_;
	
	return $self->configureChildSpecs($entity, "stopAction", "suspend");
}

sub setChildStartupDelay
{
	my ($self, $entity, $delay) = @_;
	
	return $self->configureChildSpecs($entity, "startDelay", $delay);
}

sub setChildShutdownDelay
{
	my ($self, $entity, $delay) = @_;
	
	return $self->configureChildSpecs($entity, "stopDelay", $delay);
}

sub enableWaitForToolsRunning
{
	my ($self, $entity) = @_;
	
	return $self->configureChildSpecs($entity, "waitingForGuest", 1);
}

sub disableWaitForToolsRunning
{
	my ($self, $entity) = @_;
	
	return $self->configureChildSpecs($entity, "waitingForGuest", 0);
}
1;