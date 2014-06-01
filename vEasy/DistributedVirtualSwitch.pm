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
# File: 	DistributedVirtualSwitch.pm
#
# Usage: 	my $dvs = vEasy::DistributedVirtualSwitch->new($vim, "DVS_01");
# 			my $dvs = vEasy::DistributedVirtualSwitch->new($vim, $dvs_view);
# 			my $dvs = vEasy::DistributedVirtualSwitch->new($vim, $dvs_moref);
#			
#			where $vim is vEasy::Connect object
#
# Purpose:	This file is part of vEase Automation Framework. This class represents 
#			Distributed Virtual Switch in VMware vSphere infrastructure. 
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

package vEasy::DistributedVirtualSwitch;

use strict;
use warnings;
use Data::Dumper;

our @ISA = qw(vEasy::Entity); 

# Constructor
sub new
{
	my ($class, $vim, $arg) = @_;
	
	my $self = $class->SUPER::new($vim, $arg, "VmwareDistributedVirtualSwitch" );
	
	bless ($self, $class);
	return $self;
}

# Destructor
sub DESTROY 
{
	my ($self) = @_;
	
}

sub getHosts
{
	my ($self) = @_;
	
	my @hostsystems = ();
	
	if( $self->getView()->summary->hostMember )
	{	
		for(my $i = 0; $i < scalar @{$self->getView()->summary->hostMember}; ++$i)
		{
			push(@hostsystems, vEasy::HostSystem->new($self->vim(), $self->getView()->summary->hostMember->[$i])); 
		}
	}
	return \@hostsystems;
}

sub getVirtualMachines
{
	my ($self) = @_;

	my @vms = ();
	
	if( $self->getView()->summary->vm )
	{
		for(my $i = 0; $i < scalar @{$self->getView()->summary->vm}; ++$i)
		{
			push(@vms, vEasy::VirtualMachine->new($self->vim(), $self->getView()->summary->vm->[$i])); 
		}
	}
	return \@vms;
}

sub getDistributedVirtualPortgroups
{
	my ($self) = @_;
	
	my @dvportgroups = ();
	
	if( $self->getView()->portgroup )
	{
		for(my $i = 0; $i < scalar @{$self->getView()->portgroup}; ++$i)
		{
			push(@dvportgroups, vEasy::DistributedVirtualPortgroup->new($self->vim(), $self->getView()->portgroup->[$i])); 
		}
	}
	return \@dvportgroups;
}

sub getNetworkResourcePoolKeyByName
{
	my ($self, $name) = @_;
	
	my $pools = $self->getView()->networkResourcePool;

	my @pool = grep { $_->{name} eq $name} @$pools;
	
	if( @pool )
	{
		return $pool[0]->key;
	}
	$self->addCustomFault("NetworkResourcePool does not exist - $name.");
	return 0;	
}

sub getContactPersonName
{
	my ($self) = @_;
	
	if( $self->getView()->config->contact->name )
	{
		return $self->getView()->config->contact->name;
	}
	$self->addCustomFault("Entity parameter is not available - contact name.");
	return 0;
}

sub getContactInformation
{
	my ($self) = @_;
	
	if( $self->getView()->config->contact->contact )
	{
		return $self->getView()->config->contact->contact;
	}
	$self->addCustomFault("Entity parameter is not available - contact information.");
	return 0;
}

sub getNotes
{
	my ($self) = @_;
	
	if( $self->getView()->summary->description )
	{
		return $self->getView()->summary->description;
	}
	$self->addCustomFault("Entity parameter is not available - description.");
	return 0;
}

sub getPortAmount
{
	my ($self) = @_;

	return $self->getView()->config->numPorts;
}

sub getMaxPortAmount
{
	my ($self) = @_;

	return $self->getView()->config->maxPorts;
}

sub getVersion
{
	my ($self) = @_;
	
	if( $self->getView()->config->productInfo->version)
	{
		return $self->getView()->config->productInfo->version;
	}
	$self->addCustomFault("Entity parameter is not available - version.");
	return 0;
}

sub getCreationDate
{
	my ($self) = @_;

	return $self->getView()->config->createTime;
}

sub getUuid
{
	my ($self) = @_;
	
	return $self->getView()->uuid;
}

sub isNetworkIoControlEnabled
{
	my ($self) = @_;
	
	return $self->getView()->config->networkResourceManagementEnabled;
}

sub getUsedVlans
{
	my ($self) = @_;
	
	my $vlans = [];
	eval
	{
		$vlans = $self->getView()->QueryUsedVlanIdInDvs();
	};
	my $fault = vEasy::Fault->new($@);
	if( $fault )
	{
		$self->addFault($fault);
		return 0;
	}
	return $vlans;
}

sub checkIfHostIsMemberOfTheDvs
{
	my ($self, $host) = @_;
	
	my $hosts = $self->getView()->config->host;
	
	if( $hosts )
	{
		for(my $i = 0; $i < @$hosts; ++$i)
		{
			my $member = $hosts->[$i]->config->host;
			
			if( $member->value eq $host->getManagedObjectId() )
			{
				return $hosts->[$i]->config;
			}
		}
	}
	return 0;
}

sub checkIfHostPhysicalNicIsAddedToTheDvs
{
	my ($self, $host, $vmnic) = @_;
	
	my $member = $self->checkIfHostIsMemberOfTheDvs($host);
	if( $member )
	{
		my $pnic_spec = $member->backing->pnicSpec;
		
		if( $pnic_spec )
		{
			for(my $i = 0; $i < @$pnic_spec; ++$i)
			{
				if( $pnic_spec->[$i]->pnicDevice eq $vmnic )
				{
					return 1;
				}
			}
		}
	}
	return 0;
}

sub createDistributedVirtualPortgroup
{
	my ($self, $name) = @_;
	
	my $dvportgroup = 0;
	my $spec = DVPortgroupConfigSpec->new(name => $name, type => "earlyBinding", numPorts => 128);
	eval
	{
		$dvportgroup = $self->getView()->CreateDVPortgroup(spec => $spec);
	};
	my $fault = vEasy::Fault->new($@);
	if( $fault )
	{
		$self->addFault($fault);
		return 0;
	}	
	return vEasy::DistributedVirtualPortgroup->new($self->vim(), $dvportgroup);
}


sub createNetworkResourcePool
{
	my ($self, $name) = @_;
	
	my $spec = DVSNetworkResourcePoolConfigSpec->new(name => $name, key => 0);
	eval
	{
		$self->getView()->AddNetworkResourcePool(configSpec => [$spec]);
	};
	my $fault = vEasy::Fault->new($@);
	if( $fault )
	{
		$self->addFault($fault);
		return 0;
	}	
	return 1;
}

sub removeNetworkResourcePool
{
	my ($self, $name) = @_;

	my $key = undef;
	my $nrp = $self->getView()->networkResourcePool;
	for(my $i = 0; $i < @$nrp; ++$i)
	{
		if( $nrp->[$i]->name eq $name )
		{
			$key = $nrp->[$i]->key;
		}
	}
	
	if( $key )
	{
		eval
		{
			$self->getView()->RemoveNetworkResourcePool(key => [$key]);
		};
		my $fault = vEasy::Fault->new($@);
		if( $fault )
		{
			$self->addFault($fault);
			return 0;
		}	
		return 1;
	}
	$self->addCustomFault("Network resource pool not found - $name");
	return 0;
}

sub enableNetworkIoControl
{
	my ($self) = @_;
	
	eval
	{
		$self->getView()->EnableNetworkResourceManagement(enable => 1);
	};
	my $fault = vEasy::Fault->new($@);
	if( $fault )
	{
		$self->addFault($fault);
		return 0;
	}	
	return 1;
}

sub disableNetworkIoControl
{
	my ($self) = @_;

	eval
	{
		$self->getView()->EnableNetworkResourceManagement(enable => 0);
	};
	my $fault = vEasy::Fault->new($@);
	if( $fault )
	{
		$self->addFault($fault);
		return 0;
	}	
	return 1;
}

sub updateDvsConfigsToHosts
{
	my ($self) = @_;
	
	if( scalar @{$self->getHosts()} > 0 )
	{
		my $dvs_manager = $self->vim()->getViewFromMoRef($self->vim()->getServiceContent()->dvSwitchManager);
		my $task = 0;
		eval
		{
			$task = $dvs_manager->RectifyDvsOnHost_Task(hosts => $self->getView()->summary->hostMember);
		};
		my $fault = vEasy::Fault->new($@);
		if( $fault )
		{
			$self->addFault($fault);
			return 0;
		}	
		return vEasy::Task->new($self, $task);
	}
	$self->addCustomFault("No hosts defined in this DVS.");
	return 0;
}

sub configure
{
	my ($self, $spec) = @_;

	if( $spec->isa("VMwareDVSConfigSpec") )
	{
		$self->refresh();
		$spec->{configVersion} = $self->getView()->config->configVersion;
		
		my $task = 0;
		eval
		{
			$task = $self->getView()->ReconfigureDvs_Task(spec => $spec);
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

sub setNotes
{
	my ($self, $notes) = @_;
	
	my $spec = VMwareDVSConfigSpec->new(description => $notes);
	
	return $self->configure($spec);
}

sub setContactPersonName
{
	my ($self, $name) = @_;
	
	my $contactinfo = $self->getView()->config->contact;
	$contactinfo->{name} = $name;

	my $spec = VMwareDVSConfigSpec->new(contact => $contactinfo);
	
	return $self->configure($spec);
}

sub setContactInformation
{
	my ($self, $information) = @_;
	
	my $contactinfo = $self->getView()->config->contact;
	$contactinfo->{contact} = $information;

	my $spec = VMwareDVSConfigSpec->new(contact => $contactinfo);
	
	return $self->configure($spec);
}

sub addHostToDvs
{
	my ($self, $host) = @_;
	
	if( $host->isa("vEasy::HostSystem") )
	{		
		my $pnic_backing = DistributedVirtualSwitchHostMemberPnicBacking->new();

		my $member_config_spec = DistributedVirtualSwitchHostMemberConfigSpec->new(backing => $pnic_backing, host => $host->getView(), operation => "add");		
		
		my $spec = VMwareDVSConfigSpec->new(host => [$member_config_spec]);
		
		return $self->configure($spec);
	}
	$self->addCustomFault("Invalid function argument - host");	
	return 0;
}

sub removeHostFromDvs
{
	my ($self, $host) = @_;
	
	if( $host->isa("vEasy::HostSystem") )
	{		
		my $pnic_backing = DistributedVirtualSwitchHostMemberPnicBacking->new();

		my $member_config_spec = DistributedVirtualSwitchHostMemberConfigSpec->new(backing => $pnic_backing, host => $host->getView(), operation => "remove");		
		
		my $spec = VMwareDVSConfigSpec->new(host => [$member_config_spec]);
		
		return $self->configure($spec);
	}
	$self->addCustomFault("Invalid function argument - host");	
	return 0;
}

sub addHostPhysicalNicToDvs
{
	my ($self, $host, $vmnic) = @_;
	
	if( $host->isa("vEasy::HostSystem") )
	{
		my $member = $self->checkIfHostIsMemberOfTheDvs($host);
		if( $member )
		{
			my $pnic_spec = DistributedVirtualSwitchHostMemberPnicSpec->new(pnicDevice => $vmnic);
				
			my $pnic_specs = [$pnic_spec];
			
			if( $member->backing )
			{
				if( $member->backing->pnicSpec )
				{
					$pnic_specs = $member->backing->pnicSpec;
					push(@$pnic_specs, $pnic_spec);
				}
			}

			my $pnic_backing = DistributedVirtualSwitchHostMemberPnicBacking->new(pnicSpec => $pnic_specs);

			my $member_config_spec = DistributedVirtualSwitchHostMemberConfigSpec->new(backing => $pnic_backing, host => $host->getView(), operation => "edit");		
			
			my $spec = VMwareDVSConfigSpec->new(host => [$member_config_spec]);
			
			return $self->configure($spec);
		}
	$self->addCustomFault("Host is not a member in this DVS.");	
	return 0;		
	}
	$self->addCustomFault("Invalid function argument - host");	
	return 0;
}

sub removeHostPhysicalNicFromDvs
{
	my ($self, $host, $vmnic) = @_;
	
	if( $host->isa("vEasy::HostSystem") )
	{
		my $member = $self->checkIfHostIsMemberOfTheDvs($host);
		if( $member )
		{
			if( $member->backing )
			{
				if( $member->backing->pnicSpec )
				{
					my $pnic_specs = $member->backing->pnicSpec;

					@$pnic_specs = grep { $_->{pnicDevice} ne $vmnic } @$pnic_specs;
					
					my $pnic_backing = DistributedVirtualSwitchHostMemberPnicBacking->new(pnicSpec => $pnic_specs);

					my $member_config_spec = DistributedVirtualSwitchHostMemberConfigSpec->new(backing => $pnic_backing, host => $host->getView(), operation => "edit");		
					
					my $spec = VMwareDVSConfigSpec->new(host => [$member_config_spec]);
					
					return $self->configure($spec);
				}
			}
			$self->addCustomFault("No uplinks added from this host.");	
			return 0;		
		}
		$self->addCustomFault("Host is not a member in this DVS.");	
		return 0;		
	}
	$self->addCustomFault("Invalid function argument - host");	
	return 0;
}

1;