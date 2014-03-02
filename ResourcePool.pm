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
# File: 	ResourcePool.pm
#
# Usage: 	my $pool = vEasy::ResourcePool->new($vim, "Pool01");
# 			my $pool = vEasy::ResourcePool->new($vim, $pool_view);
# 			my $pool = vEasy::ResourcePool->new($vim, $pool_moref);
#			
#			where $vim is vEasy::Connect object
#
# Purpose:	This file is part of vEase Automation Framework. This class represents 
#			ResourcePool in VMware vSphere infrastructure.
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

package vEasy::ResourcePool;

use strict;
use warnings;
use Data::Dumper;

our @ISA = qw(vEasy::Entity); 

# Constructor
sub new
{
	my ($class, $vim, $arg, $type) = @_;

	if( not $type ) 
	{
		$type = "ResourcePool";
	}	
	my $self = $class->SUPER::new($vim, $arg, $type);
	
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

sub getMemoryLimit
{
	my ($self) = @_;
	
	if( $self->getView()->config->memoryAllocation->limit )
	{
		return $self->getView()->config->memoryAllocation->limit; #MB
	}
	$self->addCustomFault("Couldn't get ResourcePool parameter.");
	return 0;
}

sub getMemoryReservation
{
	my ($self) = @_;
	
	if( $self->getView()->config->memoryAllocation->reservation )
	{
		return $self->getView()->config->memoryAllocation->reservation; #MB
	}
	$self->addCustomFault("Couldn't get ResourcePool parameter.");
	return 0;
}

sub getMemoryShares
{
	my ($self) = @_;
	
	if( $self->getView()->config->memoryAllocation->shares )
	{
		return $self->getView()->config->memoryAllocation->shares->shares;
	}
	$self->addCustomFault("Couldn't get ResourcePool parameter.");
	return 0;
}

sub getMemorySharesLevel
{
	my ($self) = @_;
	
	if( $self->getView()->config->memoryAllocation->shares )
	{
		return $self->getView()->config->memoryAllocation->shares->level->val;
	}
	$self->addCustomFault("Couldn't get ResourcePool parameter.");
	return 0;
}

sub isExpandableMemoryReservationEnabled
{
	my ($self) = @_;
	if( $self->getView()->config->memoryAllocation->expandableReservation )
	{
		return $self->getView()->config->memoryAllocation->expandableReservation;
	}
	$self->addCustomFault("Couldn't get ResourcePool parameter.");
	return 0;
}

sub getTotalRuntimeMemoryUsage
{
	my ($self) = @_;
	
	return $self->getView()->runtime->memory->overallUsage/1024/1024; #MB
}

sub getCpuLimit
{
	my ($self) = @_;
	
	if( $self->getView()->config->cpuAllocation->limit )
	{
		return $self->getView()->config->cpuAllocation->limit;
	}
	$self->addCustomFault("Couldn't get ResourcePool parameter.");
	return 0;
}

sub getCpuReservation
{
	my ($self) = @_;
	
	if( $self->getView()->config->cpuAllocation->reservation )
	{
		return $self->getView()->config->cpuAllocation->reservation;
	}
	$self->addCustomFault("Couldn't get ResourcePool parameter.");
	return 0;
}

sub getCpuShares
{
	my ($self) = @_;
	
	if( $self->getView()->config->cpuAllocation->shares )
	{
		return $self->getView()->config->cpuAllocation->shares->shares;
	}
	$self->addCustomFault("Couldn't get ResourcePool parameter.");
	return 0;
}

sub getCpuSharesLevel
{
	my ($self) = @_;

	if( $self->getView()->config->cpuAllocation->shares )
	{	
		return $self->getView()->config->cpuAllocation->shares->level->val;
	}
	$self->addCustomFault("Couldn't get ResourcePool parameter.");
	return 0;
}

sub isExpandableCpuReservationEnabled
{
	my ($self) = @_;
	
	if( $self->getView()->config->cpuAllocation->expandableReservation )
	{
		return $self->getView()->config->cpuAllocation->expandableReservation;
	}
	$self->addCustomFault("Couldn't get ResourcePool parameter.");
	return 0;
}

sub getTotalRuntimeCpuUsage
{
	my ($self) = @_;
	
	return $self->getView()->runtime->cpu->overallUsage;
}

sub getTotalAllocatedMemory
{
	my ($self) = @_;
	
	if( $self->getView()->summary->configuredMemoryMB )
	{
		return $self->getView()->summary->configuredMemoryMB; #MB
	}
	$self->addCustomFault("Couldn't get ResourcePool parameter.");
	return 0;
}

sub getChildResourcePools
{
	my ($self) = @_;

	my @pools = ();
	
	if( $self->getView()->resourcePool )
	{
		for(my $i = 0; $i < scalar @{$self->getView()->resourcePool}; ++$i)
		{
			push(@pools, vEasy::ResourcePool->new($self->vim(), $self->getView()->resourcePool->[$i])); 
		}
	}
	return \@pools;
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

sub getOwner
{
	my ($self) = @_;
	
	if( $self->getView()->owner->type eq "ClusterComputeResource" )
	{
		return vEasy::Cluster->new($self->vim(), $self->getView()->owner);
	}
	return vEasy::HostSystem->new($self->vim(), $self->vim()->getViewFromMoRef($self->getView()->owner)->host->[0]);
}

sub checkIfChildResourcePoolExists
{
	my ($self, $poolname) = @_;

	my $child_pools = $self->getChildResourcePools();

	for(my $i = 0; $i < scalar @$child_pools; ++$i)
	{
		if( $child_pools->[$i]->name() eq $poolname )
		{
			return $child_pools->[$i];
		}
	}
	return 0;
}

sub createChildResourcePool
{
	my ($self, $poolname) = @_;
	
	my $shares = SharesInfo->new(level=>SharesLevel->new('normal'), shares => 0);
	my $allocinfo = ResourceAllocationInfo->new(limit => -1, expandableReservation => 1, reservation => 0, shares => $shares);
											
	my $resource_spec = ResourceConfigSpec->new( cpuAllocation => $allocinfo, memoryAllocation => $allocinfo);
	
	my $rpool = 0;
	eval
	{
		$rpool = $self->getView()->CreateResourcePool(name => $poolname, spec => $resource_spec);
	};
	my $fault = vEasy::Fault->new($@);
	if( $fault )
	{
		$self->addFault($fault);
		return 0;
	}		
	return vEasy::ResourcePool->new($self->vim(), $rpool);
}

sub createVirtualMachine
{
	my ($self, $name, $folder, $ds) = @_;
	
	if( $folder->isa("vEasy::Folder") and $ds->isa("vEasy::Datastore"))
	{
		my $vm = $folder->createVirtualMachine($name, $self, $ds);
		
		if( $vm )
		{
			return $vm;
		}
		else
		{
			$self->addFault($folder->getLatestFault());
		}
	}
	$self->addCustomFault("Invalid function arguments.");
	return 0;
}

sub moveEntityToResourcePool
{
	my ($self, $entity) = @_;
	
	if( $entity->isa("vEasy::ResourcePool") or $entity->isa("vEasy::VirtualMachine") or $entity->isa("vEasy::VirtualApp") )
	{
		eval
		{
			$self->getView()->MoveIntoResourcePool(list => [$entity->getView()]);
		};
		my $fault = vEasy::Fault->new($@);
		if( $fault )
		{
			$self->addFault($fault);
			return 0;
		}
		return 1;
	}
	$self->addCustomFault("Invalid function argument.");
	return 0;
}

sub configure
{
	my ($self, $spec) = @_;

	if( $spec->isa("ResourceConfigSpec") )
	{
		eval
		{
			$self->getView()->UpdateConfig(config => $spec);
		};
		my $fault = vEasy::Fault->new($@);
		if( $fault )
		{
			$self->addFault($fault);
			return 0;
		}
		return 1;
	}
	$self->addCustomFault("Function argument is not a ResourceConfigSpec.");
	return 0;
}
sub setMemoryLimit
{
	my ($self, $limit) = @_;
	
	if( $limit =~ m/(-1|\d+)/ )
	{
		my $allocinfo = ResourceAllocationInfo->new(limit => $limit);
												
		my $resource_spec = ResourceConfigSpec->new( cpuAllocation => ResourceAllocationInfo->new(), 
													 memoryAllocation => $allocinfo);
													 
		return $self->configure($resource_spec);
	}
	$self->addCustomFault("Invalid function argument. limit");
	return 0;
}

sub setMemoryReservation
{
	my ($self, $reservation) = @_;
	
	if( $reservation =~ m/(-1|\d+)/ )
	{
		my $allocinfo = ResourceAllocationInfo->new(reservation => $reservation);
												
		my $resource_spec = ResourceConfigSpec->new( cpuAllocation => ResourceAllocationInfo->new(), 
													 memoryAllocation => $allocinfo);
													 
		return $self->configure($resource_spec);
	}
	$self->addCustomFault("Invalid function argument. reservation");
	return 0;
}

sub setExpandableMemoryReservation
{
	my ($self, $enabled) = @_;
	
	if( $enabled =~ m/^(0|1)$/ )
	{
		my $allocinfo = ResourceAllocationInfo->new(expandableReservation => $enabled);
												
		my $resource_spec = ResourceConfigSpec->new( cpuAllocation => ResourceAllocationInfo->new(), 
													 memoryAllocation => $allocinfo);
													 
		return $self->configure($resource_spec);
	}
	$self->addCustomFault("Invalid function argument. enabled");
	return 0;
}

sub enableExpandableMemoryReservation
{
	my ($self) = @_;
	
	return $self->setExpandableMemoryReservation(1);
}

sub disableExpandableMemoryReservation
{
	my ($self) = @_;
	
	return $self->setExpandableMemoryReservation(0);
}

sub setMemoryShares
{
	my ($self, $level, $custom) = @_;
	
	if( $level =~ m/^(low|normal|high|custom)$/ )
	{
		if( not $custom )
		{
			$custom = 0;
		}
		my $shares = SharesInfo->new(level=>SharesLevel->new($level), shares => $custom);
		my $allocinfo = ResourceAllocationInfo->new(shares => $shares);
												
		my $resource_spec = ResourceConfigSpec->new( cpuAllocation => ResourceAllocationInfo->new(), 
													 memoryAllocation => $allocinfo);
													 
		return $self->configure($resource_spec);
	}
	$self->addCustomFault("Invalid function argument. level");
	return 0;
}

sub removeMemoryLimit
{
	my ($self) = @_;
	
	return $self->setMemoryLimit(-1);
}

sub removeMemoryReservation
{
	my ($self) = @_;
	
	return $self->setMemoryReservation(0);
}

sub setCpuLimit
{
	my ($self, $limit) = @_;
	
	if( $limit =~ m/(-1|\d+)/ )
	{
		my $allocinfo = ResourceAllocationInfo->new(limit => $limit);
												
		my $resource_spec = ResourceConfigSpec->new( cpuAllocation => $allocinfo, 
													 memoryAllocation => ResourceAllocationInfo->new());
													 
		return $self->configure($resource_spec);
	}
	$self->addCustomFault("Invalid function argument. limit");
	return 0;
}

sub setCpuReservation
{
	my ($self, $reservation) = @_;
	
	if( $reservation =~ m/(-1|\d+)/ )
	{
		my $allocinfo = ResourceAllocationInfo->new(reservation => $reservation);
												
		my $resource_spec = ResourceConfigSpec->new( cpuAllocation => $allocinfo, 
													 memoryAllocation => ResourceAllocationInfo->new());
													 
		return $self->configure($resource_spec);
	}
	$self->addCustomFault("Invalid function argument. reservation");
	return 0;
}

sub setExpandableCpuReservation
{
	my ($self, $enabled) = @_;
	
	if( $enabled =~ m/^(0|1)$/ )
	{
		my $allocinfo = ResourceAllocationInfo->new(expandableReservation => $enabled);
												
		my $resource_spec = ResourceConfigSpec->new( cpuAllocation => $allocinfo, 
													 memoryAllocation => ResourceAllocationInfo->new());
													 
		return $self->configure($resource_spec);
	}
	$self->addCustomFault("Invalid function argument. enabled");
	return 0;
}

sub enableExpandableCpuReservation
{
	my ($self) = @_;
	
	return $self->setExpandableCpuReservation(1);
}

sub disableExpandableCpuReservation
{
	my ($self) = @_;
	
	return $self->setExpandableCpuReservation(0);
}

sub setCpuShares
{
	my ($self, $level, $custom) = @_;
	
	if( $level =~ m/^(low|normal|high|custom)$/ )
	{
		if( not $custom )
		{
			$custom = 0;
		}
		my $shares = SharesInfo->new(level=>SharesLevel->new($level), shares => $custom);
		my $allocinfo = ResourceAllocationInfo->new(shares => $shares);
												
		my $resource_spec = ResourceConfigSpec->new( cpuAllocation => $allocinfo, 
													 memoryAllocation => ResourceAllocationInfo->new());
													 
		return $self->configure($resource_spec);
	}
	$self->addCustomFault("Invalid function argument. level");
	return 0;
}

sub removeCpuLimit
{
	my ($self) = @_;
	
	return $self->setCpuLimit(-1);
}

sub removeCpuReservation
{
	my ($self) = @_;
	
	return $self->setCpuReservation(0);
}
1;