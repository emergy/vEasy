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
# File: 	HostSystemNetworkManager.pm
#
# Purpose:	This file is part of vEase Automation Framework. This class is meant only 
#			for internal usage of this Framework. It's purporse is to tackle the 
#			complexities of HostSystem Networking in vSphere API.
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

package vEasy::HostSystemNetworkManager;

use strict;
use warnings;
use vEasy::HostSystem;
use vEasy::StandardVirtualSwitch;
use vEasy::Fault;
use Data::Dumper;

# Constructor
sub new
{
	my ($class, $host) = @_;

	my $self = {host => 0, netsys => 0, vnicsys => 0};	
	
	if( $host->isa("vEasy::HostSystem") )
	{
		$self->{host} = $host;
		$self->{netsys} = $host->vim()->getViewFromMoRef($host->getView()->configManager->networkSystem);
		$self->{vnicsys} = $host->vim()->getViewFromMoRef($host->getView()->configManager->virtualNicManager);
		
	}
	else
	{
		return 0;
	}

	bless ($self, $class);
	return $self;
}

# Destructor
sub DESTROY 
{
	my ($self) = @_;
	
}

sub refresh
{
	my ($self) = @_;

	$self->{host}->refresh();
	$self->netSys()->update_view_data();
	$self->vnicSys()->update_view_data();
	
	return 1;
}

sub netSys
{
	my ($self) = @_;

	return $self->{netsys};
}

sub vnicSys
{
	my ($self) = @_;

	return $self->{vnicsys};
}

# ============================================================================================
# Network specs
# ============================================================================================

sub getDnsServers
{
	my ($self) = @_;
	
	if( $self->netSys()->dnsConfig )
	{
		if( $self->netSys()->dnsConfig->address )
		{
			return $self->netSys()->dnsConfig->address;
		}
	}
	$self->{host}->addCustomFault("Couldn't get HostSystem parameter.");
	return 0;
}

sub getHostName
{
	my ($self) = @_;
	
	if( $self->netSys()->dnsConfig )
	{
		return $self->netSys()->dnsConfig->hostName;
	}
	$self->{host}->addCustomFault("Couldn't get HostSystem parameter.");
	return 0;
}

sub getDomainName
{
	my ($self) = @_;
	
	if( $self->netSys()->dnsConfig )
	{
		return $self->netSys()->dnsConfig->domainName;
	}
	$self->{host}->addCustomFault("Couldn't get HostSystem parameter.");
	return 0;
}

sub getDefaultGateway
{
	my ($self) = @_;
	
	if( $self->netSys()->ipRouteConfig )
	{
		if( $self->netSys()->ipRouteConfig->defaultGateway )
		{
			return $self->netSys()->ipRouteConfig->defaultGateway;
		}
	}
	$self->{host}->addCustomFault("Couldn't get HostSystem parameter.");
	return 0;
}


# ============================================================================================
# Get API objects to networking devices
# ============================================================================================

sub getPhysicalNicApiObject
{
	my ($self, $name) = @_;
	
	if( $self->netSys()->networkInfo )
	{
		if( $self->netSys()->networkInfo->pnic )
		{
			for(my $i = 0; $i < @{$self->netSys()->networkInfo->pnic}; ++$i)
			{
				if( $self->netSys()->networkInfo->pnic->[$i]->device eq $name )
				{
					return $self->netSys()->networkInfo->pnic->[$i];
				}
			}
		}
	}
	$self->{host}->addCustomFault("Physical Nic does not exist.");
	return 0;
}

sub getStandardVirtualSwitchApiObject
{
	my ($self, $name) = @_;
	
	if( $self->netSys()->networkInfo )
	{
		if( $self->netSys()->networkInfo->vswitch )
		{
			for(my $i = 0; $i < @{$self->netSys()->networkInfo->vswitch}; ++$i)
			{
				if( $self->netSys()->networkInfo->vswitch->[$i]->name eq $name )
				{
					return $self->netSys()->networkInfo->vswitch->[$i];
				}
			}
		}
	}
	$self->{host}->addCustomFault("StandardVirtualSwitch does not exist.");
	return 0;
}

sub getPortGroupApiObject
{
	my ($self, $name) = @_;
	
	if( $self->netSys()->networkInfo )
	{
		if( $self->netSys()->networkInfo->portgroup )
		{
			for(my $i = 0; $i < @{$self->netSys()->networkInfo->portgroup}; ++$i)
			{
				if( $self->netSys()->networkInfo->portgroup->[$i]->spec->name eq $name )
				{
					return $self->netSys()->networkInfo->portgroup->[$i];
				}
			}
		}
	}
	$self->{host}->addCustomFault("PortGroup does not exist.");
	return 0;
}

sub getVmkInterfaceApiObject
{
	my ($self, $name) = @_;
	
	if( $self->netSys()->networkInfo )
	{
		if( $self->netSys()->networkInfo->vnic )
		{
			for(my $i = 0; $i < @{$self->netSys()->networkInfo->vnic}; ++$i)
			{
				if( $self->netSys()->networkInfo->vnic->[$i]->device eq $name )
				{
					return $self->netSys()->networkInfo->vnic->[$i];
				}
			}
		}
	}
	$self->{host}->addCustomFault("VMKernel Port does not exist.");
	return 0;
}

sub getVmkInterfaceApiObjectByPortGroupName
{
	my ($self, $name) = @_;
	
	if( $self->netSys()->networkInfo )
	{
		if( $self->netSys()->networkInfo->vnic )
		{
			for(my $i = 0; $i < @{$self->netSys()->networkInfo->vnic}; ++$i)
			{
				if( $self->netSys()->networkInfo->vnic->[$i]->portgroup eq $name )
				{
					return $self->netSys()->networkInfo->vnic->[$i];
				}
			}
		}
	}
	$self->{host}->addCustomFault("VMKernel Port does not exist.");
	return 0;
}

sub checkIfPortgroupIsInStandardVirtualSwitch
{
	my ($self, $pg_name, $vswitch_name) = @_;
	
	my $pgobj = $self->getPortGroupApiObject($pg_name);
	if( $pgobj )
	{
		if( $pgobj->{vswitch} =~ m/$vswitch_name$/ )
		{
			return 1;
		}
	}
	return 0;
}

sub checkIfVmkInterfaceIsInStandardVirtualSwitch
{
	my ($self, $vmk, $vswitch_name) = @_;
	
	my $vmkobj = $self->getVmkInterfaceApiObject($vmk);
	if( $vmkobj )
	{
		my $pgobj = $self->getPortGroupApiObject($vmkobj->portgroup);
		if( $pgobj )
		{
			if( $pgobj->{vswitch} =~ m/$vswitch_name$/ )
			{
				return 1;
			}
		}
	}
	return 0;
}

sub addStandardVirtualSwitch
{
	my ($self, $name, $ports) = @_;
	
	if( not $ports )
	{
		$ports = 128;
	}

	my $vswitch_spec = HostVirtualSwitchSpec->new(numPorts => $ports);
		
	eval
	{
		$self->netSys()->AddVirtualSwitch(vswitchName => $name, spec => $vswitch_spec);
	};
	my $fault = vEasy::Fault->new($@);
	if( $fault )
	{
		$self->{host}->addFault($fault);
		return 0;
	}

	return vEasy::StandardVirtualSwitch->new($self->{host}, $name);
}

# ============================================================================================
# PortGroup Operations
# ============================================================================================

sub removePortGroup
{
	my ($self, $name) = @_;
	
	eval
	{
		$self->netSys()->RemovePortGroup(pgName => $name);
	};
	my $fault = vEasy::Fault->new($@);
	if( $fault )
	{
		$self->{host}->addFault($fault);
		return 0;
	}
	return 1;
}

sub configurePortGroup
{
	my ($self, $spec) = @_;
	
	if( $spec->isa("HostPortGroupSpec") )
	{
		eval
		{
			$self->netSys()->UpdatePortGroup(pgName => $spec->name, portgrp => $spec);
		};
		my $fault = vEasy::Fault->new($@);
		if( $fault )
		{
			$self->{host}->addFault($fault);
			return 0;
		}
		return 1;
	}
	$self->{host}->addCustomFault("Invalid function argument - spec.");
	return 0;
}

sub setPortGroupVlanId
{
	my ($self, $pgname, $vlanid) = @_;
	
	my $pg = $self->getPortGroupApiObject($pgname);
	if( $pg )
	{
		$pg->spec->{vlanId} = $vlanid;
		print $pg->spec->name."\n";
		return $self->configurePortGroup($pg->spec);
	}
	$self->{host}->addCustomFault("PortGroup not found.");
	return 0;
}

# ============================================================================================
# VMkernel Port Operations
# ============================================================================================

sub getVmkInterfaceIpAddress
{
	my ($self, $vmk) = @_;
	
	my $vnic = $self->getVmkInterfaceApiObject($vmk);
	if( $vnic )
	{
		if( $vnic->spec->ip->ipAddress )
		{
			return $vnic->spec->ip->ipAddress;
		}
		else
		{
			$self->{host}->addCustomFault("No IPv4 address set for $vmk");
		}
	}
	$self->{host}->addCustomFault("VMKernel Port not found.");
	return 0;
}

sub getVmkInterfaceNetmask
{
	my ($self, $vmk) = @_;
	
	my $vnic = $self->getVmkInterfaceApiObject($vmk);
	if( $vnic )
	{
		if( $vnic->spec->ip->subnetMask )
		{
			return $vnic->spec->ip->subnetMask;
		}
		else
		{
			$self->{host}->addCustomFault("No netmask set for $vmk");
		}
	}
	$self->{host}->addCustomFault("VMKernel Port not found.");
	return 0;
}

sub removeVmkInterface
{
	my ($self, $vmk) = @_;

	my $vnic = $self->getVmkInterfaceApiObject($vmk);
	if( $vnic )
	{
		eval
		{
			$self->netSys()->RemoveVirtualNic(device => $vmk);
		};
		my $fault = vEasy::Fault->new($@);
		if( $fault )
		{
			$self->{host}->addFault($fault);
			return 0;
		}

		if( $self->removePortGroup($vnic->{portgroup}) )
		{
			return 1;	
		}
	}
	$self->{host}->addCustomFault("VMKernel Port not found.");
	return 0;
}

sub setVmkInterfaceIpAddress
{
	my ($self, $vmk, $ip, $netmask) = @_;

	my $vnic = $self->getVmkInterfaceApiObject($vmk);
	if( $vnic )
	{
		my $spec = $vnic->spec;
		
		$spec->ip->{ipAddress} = $ip;
		$spec->ip->{subnetMask} = $netmask;
		$spec->ip->{dhcp} = 0;

		eval
		{
			$self->netSys()->UpdateVirtualNic(device => $vmk, nic => $spec);
		};
		my $fault = vEasy::Fault->new($@);
		if( $fault )
		{
			$self->{host}->addFault($fault);
			return 0;
		}
		return 1;
	}
	$self->{host}->addCustomFault("VMKernel Port not found.");
	return 0;
}

sub setVmkInterfaceType
{
	my ($self, $vmk, $type, $enable) = @_;

	eval
	{
		if( $enable )
		{
			$self->vnicSys()->SelectVnicForNicType(device => $vmk, nicType => $type);
		}
		else
		{
			$self->vnicSys()->DeselectVnicForNicType(device => $vmk, nicType => $type);
		}
	};
	my $fault = vEasy::Fault->new($@);
	if( $fault )
	{
		$self->{host}->addFault($fault);
		return 0;
	}
	return 1;	
}




1;
