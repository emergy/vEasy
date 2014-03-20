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
# File: 	DatastoreCluster.pm
#
# Usage: 	my $dsc = vEasy::DatastoreCluster->new($vim, "DatastoreCluster01");
# 			my $dsc = vEasy::DatastoreCluster->new($vim, $dsc_view);
# 			my $dsc = vEasy::DatastoreCluster->new($vim, $dsc_moref);
#			
#			where $vim is vEasy::Connect object
#
# Purpose:	This file is part of vEase Automation Framework. This class represents 
#			Datastore Cluster in VMware vSphere infrastructure.
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

package vEasy::DatastoreCluster;

use strict;
use warnings;
use Data::Dumper;

our @ISA = qw(vEasy::Folder); 

# Constructor
sub new
{
	my ($class, $vim, $arg) = @_;
	
	my $self = $class->SUPER::new($vim, $arg, "StoragePod");
	
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

sub getTotalCapacity
{
	my ($self) = @_;

	if( $self->getView()->summary )
	{
		return int($self->getView()->summary->capacity/1024/1024);
	}
	$self->addCustomFault("Capacity information not available.");
	return 0;
}

sub getFreeCapacity
{
	my ($self) = @_;

	if( $self->getView()->summary )
	{
		return int($self->getView()->summary->freeSpace/1024/1024);
	}
	$self->addCustomFault("Capacity information not available.");	
	return 0;
}

sub getUsedCapacity
{
	my ($self) = @_;
	
	if( $self->getView()->summary )
	{
		return $self->getTotalCapacity() - $self->getFreeCapacity();
	}
	$self->addCustomFault("Capacity information not available.");	
	return 0;
}

sub getSpaceUtilizationThreshold
{
	my ($self) = @_;
	
	if( $self->getView()->podStorageDrsEntry )
	{
		if( $self->getView()->podStorageDrsEntry->storageDrsConfig->podConfig->spaceLoadBalanceConfig->spaceUtilizationThreshold )
		{
			return $self->getView()->podStorageDrsEntry->storageDrsConfig->podConfig->spaceLoadBalanceConfig->spaceUtilizationThreshold;
		}
	}
	$self->addCustomFault("Property not set - spaceUtilizationThreshold.");	
	return 0;
}

sub getMinimumSpaceUtilizationDifference
{
	my ($self) = @_;
	
	if( $self->getView()->podStorageDrsEntry )
	{
		if( $self->getView()->podStorageDrsEntry->storageDrsConfig->podConfig->spaceLoadBalanceConfig->minSpaceUtilizationDifference )
		{
			return $self->getView()->podStorageDrsEntry->storageDrsConfig->podConfig->spaceLoadBalanceConfig->minSpaceUtilizationDifference;
		}
	}
	$self->addCustomFault("Property not set - minSpaceUtilizationDifference.");	
	return 0;
}

sub getIoLatencyThreshold
{
	my ($self) = @_;
	
	if( $self->getView()->podStorageDrsEntry )
	{
		if( $self->getView()->podStorageDrsEntry->storageDrsConfig->podConfig->ioLoadBalanceConfig )
		{
			return $self->getView()->podStorageDrsEntry->storageDrsConfig->podConfig->ioLoadBalanceConfig->ioLatencyThreshold;
		}
	}
	$self->addCustomFault("Property not set - ioLatencyThreshold.");	
	return 0;
}

sub getIoLoadImbalanceThreshold
{
	my ($self) = @_;
	
	if( $self->getView()->podStorageDrsEntry )
	{
		if( $self->getView()->podStorageDrsEntry->storageDrsConfig->podConfig->ioLoadBalanceConfig )
		{
			return $self->getView()->podStorageDrsEntry->storageDrsConfig->podConfig->ioLoadBalanceConfig->ioLoadImbalanceThreshold;
		}
	}
	$self->addCustomFault("Property not set - ioLoadImbalanceThreshold.");	
	return 0;
}

sub isStorageDrsEnabled
{
	my ($self) = @_;
	
	if( $self->getView()->podStorageDrsEntry )
	{
		return $self->getView()->podStorageDrsEntry->storageDrsConfig->podConfig->enabled;
	}
	$self->addCustomFault("Property not available.");	
	return 0;
}

sub isIoLoadBalancingEnabled
{
	my ($self) = @_;
	
	if( $self->getView()->podStorageDrsEntry )
	{
		return $self->getView()->podStorageDrsEntry->storageDrsConfig->podConfig->ioLoadBalanceEnabled;
	}
	$self->addCustomFault("Property not set - ioLoadBalanceEnabled.");	
	return 0;
}

sub getStorageDrsAutomationLevel
{
	my ($self) = @_;
	
	if( $self->getView()->podStorageDrsEntry )
	{
		return $self->getView()->podStorageDrsEntry->storageDrsConfig->podConfig->defaultVmBehavior;
	}
	$self->addCustomFault("Property not set - defaultVmBehavior.");	
	return 0;
}

sub addDatastore
{
	my ($self, $ds) = @_;
	
	if( $ds->isa("vEasy::Datastore") )
	{
		return $self->moveEntityToFolder($ds);
	}
	return 0;
}

sub configure
{
	my ($self, $spec) = @_;

	my $srm = $self->vim()->getViewFromMoRef($self->vim()->getServiceContent()->storageResourceManager);
	if( $spec->isa("StorageDrsConfigSpec") )
	{
		my $task = 0;
		eval
		{
			$task = $srm->ConfigureStorageDrsForPod_Task(pod => $self->getView(), spec => $spec, modify => 1);
		};
		my $fault = vEasy::Fault->new($@);
		if( $fault )
		{
			$self->addFault($fault);
			return 0;
		}
		return vEasy::Task->new($self, $task);
	}
	$self->addCustomFault("Function argument is not a StorageDrsConfigSpec.");
	return 0;
}

sub enableStorageDrs
{
	my ($self) = @_;
	
	my $podspec = StorageDrsPodConfigSpec->new(enabled => 1);
	my $spec = StorageDrsConfigSpec->new(podConfigSpec => $podspec);
	return $self->configure($spec);
}

sub disableStorageDrs
{
	my ($self) = @_;
	
	my $podspec = StorageDrsPodConfigSpec->new(enabled => 1);
	my $spec = StorageDrsConfigSpec->new(podConfigSpec => $podspec);
	
	return $self->configure($spec);
}

sub enableIoLoadBalancing
{
	my ($self) = @_;
	
	my $podspec = StorageDrsPodConfigSpec->new(ioLoadBalanceEnabled => 1);
	my $spec = StorageDrsConfigSpec->new(podConfigSpec => $podspec);
	
	return $self->configure($spec);
}

sub disableIoLoadBalancing
{
	my ($self) = @_;
	
	my $podspec = StorageDrsPodConfigSpec->new(ioLoadBalanceEnabled => 0);
	my $spec = StorageDrsConfigSpec->new(podConfigSpec => $podspec);
	
	return $self->configure($spec);
}

sub setStorageDrsAutomationLevelToAutomated
{
	my ($self) = @_;
	
	my $podspec = StorageDrsPodConfigSpec->new(defaultVmBehavior => "automated");
	my $spec = StorageDrsConfigSpec->new(podConfigSpec => $podspec);
	
	return $self->configure($spec);
}

sub setStorageDrsAutomationLevelToManual
{
	my ($self) = @_;
	
	my $podspec = StorageDrsPodConfigSpec->new(defaultVmBehavior => "manual");
	my $spec = StorageDrsConfigSpec->new(podConfigSpec => $podspec);
	
	return $self->configure($spec);
}

sub keepVirtualMachineDisksOnSameDatastore
{
	my ($self) = @_;
	
	my $podspec = StorageDrsPodConfigSpec->new(defaultIntraVmAffinity => 1);
	my $spec = StorageDrsConfigSpec->new(podConfigSpec => $podspec);
	
	return $self->configure($spec);
}

sub dontKeepVirtualMachinesDisksOnSameDatastore
{
	my ($self) = @_;
	
	my $podspec = StorageDrsPodConfigSpec->new(defaultIntraVmAffinity => 0);
	my $spec = StorageDrsConfigSpec->new(podConfigSpec => $podspec);
	
	return $self->configure($spec);
}	

sub setLoadBalanceInterval
{
	my ($self, $interval) = @_;
	
	my $podspec = StorageDrsPodConfigSpec->new(loadBalanceInterval => $interval);
	my $spec = StorageDrsConfigSpec->new(podConfigSpec => $podspec);
	
	return $self->configure($spec);
}	

sub setMinimumSpaceUtilizationDifference
{
	my ($self, $percentage) = @_;
	
	my $spaceconf = StorageDrsSpaceLoadBalanceConfig->new(minSpaceUtilizationDifference => $percentage);
	my $podspec = StorageDrsPodConfigSpec->new(spaceLoadBalanceConfig => $spaceconf);
	my $spec = StorageDrsConfigSpec->new(podConfigSpec => $podspec);
	
	return $self->configure($spec);
}

sub setSpaceUtilizationThreshold
{
	my ($self, $percentage) = @_;
	
	my $spaceconf = StorageDrsSpaceLoadBalanceConfig->new(spaceUtilizationThreshold => $percentage);
	my $podspec = StorageDrsPodConfigSpec->new(spaceLoadBalanceConfig => $spaceconf);
	my $spec = StorageDrsConfigSpec->new(podConfigSpec => $podspec);
	
	return $self->configure($spec);
}

sub setIoLatencyThreshold
{
	my ($self, $threshold) = @_;
	
	my $ioconf = StorageDrsIoLoadBalanceConfig->new(ioLatencyThreshold => $threshold);
	my $podspec = StorageDrsPodConfigSpec->new(ioLoadBalanceConfig => $ioconf);
	my $spec = StorageDrsConfigSpec->new(podConfigSpec => $podspec);
	
	return $self->configure($spec);
}

sub setIoLoadImbalanceThreshold 
{
	my ($self, $threshold) = @_; # 1-25, 1 = aggressive, 25 = conservative
	
	my $ioconf = StorageDrsIoLoadBalanceConfig->new(ioLoadImbalanceThreshold => $threshold);
	my $podspec = StorageDrsPodConfigSpec->new(ioLoadBalanceConfig => $ioconf);
	my $spec = StorageDrsConfigSpec->new(podConfigSpec => $podspec);
	
	return $self->configure($spec);
}

1;