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
# File: 	StandardVirtualSwitch.pm
#
# Usage: 	my $vswitch = $host->getStandardVirtualSwitch("vSwitch0");
#
#			where $host is vEasy::HostSystem object
#
# Purpose:	This file is part of vEase Automation Framework. This class represents 
#			HostSystem's Standard Virtual Switch in VMware vSphere infrastructure.
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

package vEasy::StandardVirtualSwitch;

use strict;
use warnings;

# Constructor
sub new
{
	my ($class, $host, $vswitch_name) = @_;

	my $self = {host => 0, name => 0};	
	
	if( $host->isa("vEasy::HostSystem") )
	{
		if( $host->netMgr()->getStandardVirtualSwitchApiObject($vswitch_name) )
		{
			$self->{host} = $host;
			$self->{name} = $vswitch_name;
		}
		else
		{
			$host->addCustomFault("StandardVirtualSwitch does not exists.");
			return 0;
		}
	}
	else
	{
		$host->addCustomFault("Invalid argument - host.");
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

sub name
{
	my ($self) = @_;
	
	return $self->{name};
}

sub getSpec
{
	my ($self) = @_;
	
	return $self->{host}->netMgr()->getStandardVirtualSwitchApiObject($self->{name})->spec;
}

sub remove
{
	my ($self) = @_;
	
	eval
	{
		$self->{host}->netMgr()->netSys()->RemoveVirtualSwitch(vswitchName => $self->name());
	};
	my $fault = vEasy::Fault->new($@);
	if( $fault )
	{
		$self->{host}->addFault($fault);
		return 0;
	}
	return 1;
}

sub configure
{
	my ($self, $spec) = @_;
	
	if( $spec->isa("HostVirtualSwitchSpec") )
	{
		eval
		{
			$self->{host}->netMgr()->netSys()->UpdateVirtualSwitch(vswitchName => $self->{name}, spec => $spec);
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

sub setNumberOfPorts
{
	my ($self, $ports) = @_;
	
	my $spec = $self->getSpec();	
	$spec->{numPorts} = $ports;

	return $self->configure($spec);
}

sub setMtuValue
{
	my ($self, $mtu) = @_;
	
	my $spec = $self->getSpec();	
	$spec->{mtu} = $mtu;

	return $self->configure($spec);
}

# ==============================================================
# Physical NIC Operations
# ==============================================================

sub addPhysicalNic
{
	my ($self, $pnic) = @_;
	
	my $spec = $self->getSpec();
	
	if( not $spec->bridge )
	{
		$spec->{bridge} = HostVirtualSwitchBondBridge->new(nicDevice => []);
	}
	if( $spec->bridge->isa("HostVirtualSwitchBondBridge") )
	{
		my $existing = $spec->bridge->nicDevice;
		push(@$existing, $pnic);
		$spec->bridge->{nicDevice} = $existing;
		
		return $self->configure($spec);
	}
	$self->{host}->addCustomFault("Invalid VirtualSwitchType.");
	return 0;
}

sub removePhysicalNic
{
	my ($self, $pnic) = @_;
	
	my $spec = $self->getSpec();

	if( not $spec->bridge )
	{
		$spec->{bridge} = HostVirtualSwitchBondBridge->new(nicDevice => []);
	}
	
	if( $spec->bridge->isa("HostVirtualSwitchBondBridge") )
	{
		my $existing = $spec->bridge->nicDevice;
		@$existing = grep(!/^$pnic$/, @$existing);
		$spec->bridge->{nicDevice} = $existing;
		
		if( not @$existing )
		{	
			delete $spec->{bridge};
		}
		
		return $self->configure($spec);
	}
	$self->{host}->addCustomFault("Invalid VirtualSwitchType.");
	return 0;
}

sub setPhysicalNicToActive
{
	my ($self, $pnic) = @_;
	
	my $spec = $self->getSpec();
	my $standby = $spec->policy->nicTeaming->nicOrder->{standbyNic};
	@$standby = grep(!/^$pnic$/, @$standby);
	$spec->policy->nicTeaming->nicOrder->{standbyNic} = $standby;
	
	my $active = $spec->policy->nicTeaming->nicOrder->{activeNic};
	push(@$active, $pnic);
	$spec->policy->nicTeaming->nicOrder->{activeNic} = $active;
	
	return $self->configure($spec);
}

sub setPhysicalNicToStandby
{
	my ($self, $pnic) = @_;
	
	my $spec = $self->getSpec();
	my $active = $spec->policy->nicTeaming->nicOrder->{activeNic};
	@$active = grep(!/^$pnic$/, @$active);
	$spec->policy->nicTeaming->nicOrder->{active} = $active;
	
	my $standby = $spec->policy->nicTeaming->nicOrder->{standbyNic};
	push(@$standby, $pnic);
	$spec->policy->nicTeaming->nicOrder->{standbyNic} = $standby;
	
	return $self->configure($spec);
}

sub setPhysicalNicToUnused
{
	my ($self, $pnic) = @_;
	
	my $spec = $self->getSpec();
	
	my $active = $spec->policy->nicTeaming->nicOrder->{activeNic};
	@$active = grep(!/^$pnic$/, @$active);
	$spec->policy->nicTeaming->nicOrder->{active} = $active;
	
	my $standby = $spec->policy->nicTeaming->nicOrder->{standbyNic};
	@$standby = grep(!/^$pnic$/, @$standby);
	$spec->policy->nicTeaming->nicOrder->{standbyNic} = $standby;
	
	return $self->configure($spec);
}


# ==============================================================
# vSwitch Teaming Policy Options 
# ==============================================================

sub setTeamingPolicyOptions
{
	my ($self, $option, $value) = @_;
	
	my $spec = $self->getSpec();	
	$spec->policy->nicTeaming->{$option} = $value;

	return $self->configure($spec);
}

sub enableNotifySwitches
{
	my ($self) = @_;
	
	return $self->setTeamingPolicyOptions("notifySwitches", 1)
}

sub disableNotifySwitches
{
	my ($self) = @_;
	
	return $self->setTeamingPolicyOptions("notifySwitches", 0)
}

sub enableFailback
{
	my ($self) = @_;
	
	return $self->setTeamingPolicyOptions("rollingOrder", 0)
}

sub disableFailback
{
	my ($self) = @_;
	
	return $self->setTeamingPolicyOptions("rollingOrder", 1)
}

sub setPhysicalNicLoadBalacingToRouteBasedOnIpHash
{
	my ($self) = @_;
	
	return $self->setTeamingPolicyOptions("policy", "loadbalance_ip");
}

sub setPhysicalNicLoadBalacingToRouteBasedOnSourceMacHash
{
	my ($self) = @_;
	
	return $self->setTeamingPolicyOptions("policy", "loadbalance_srcmac");
}

sub setPhysicalNicLoadBalacingToRouteBasedOnSourcePortId
{
	my ($self) = @_;
	
	return $self->setTeamingPolicyOptions("policy", "loadbalance_srcid");
}

sub setPhysicalNicLoadBalacingToUseExplicitFailoverOrder
{
	my ($self) = @_;
	
	return $self->setTeamingPolicyOptions("policy", "failover_explicit");
}



# ==============================================================
# vSwitch Security Options 
# ==============================================================

sub setSecurityOptions
{
	my ($self, $option, $value) = @_;
	
	my $spec = $self->getSpec();	
	$spec->policy->security->{$option} = $value;

	return $self->configure($spec);
}

sub enablePromiscuousMode
{
	my ($self) = @_;
	
	return $self->setSecurityOptions("allowPromiscuous", 1);
}

sub disablePromiscuousMode
{
	my ($self) = @_;
	
	return $self->setSecurityOptions("allowPromiscuous", 0);
}

sub enableMacAddressChanges
{
	my ($self) = @_;
	
	return $self->setSecurityOptions("macChanges", 1);
}

sub disableMacAddressChanges
{
	my ($self) = @_;
	
	return $self->setSecurityOptions("macChanges", 0);
}

sub enableForgedTransmits
{
	my ($self) = @_;
	
	return $self->setSecurityOptions("forgedTransmits", 1);
}

sub disableForgedTransmits
{
	my ($self) = @_;
	
	return $self->setSecurityOptions("forgedTransmits", 0);
}

# ==============================================================
# PortGroup operations
# ==============================================================

sub addPortGroup
{
	my ($self, $name, $vlan) = @_;
	
	if( not $vlan )
	{
		$vlan = 0;
	}
	
	my $pg_policy_spec = HostNetworkPolicy->new();
	my $portgroup_spec = HostPortGroupSpec->new(name => $name, vlanId => $vlan, vswitchName => $self->{name}, policy => $pg_policy_spec);
	
	eval
	{
		$self->{host}->netMgr()->netSys()->AddPortGroup(portgrp => $portgroup_spec);
	};
	my $fault = vEasy::Fault->new($@);
	if( $fault )
	{
		$self->{host}->addFault($fault);
		return 0;
	}
	return 1;
}

sub removePortGroup
{
	my ($self, $name) = @_;
	
	if( $self->{host}->netMgr()->checkIfPortgroupIsInStandardVirtualSwitch($name, $self->name()) )
	{
		return $self->{host}->netMgr()->removePortGroup($name);
	}
	$self->{host}->addCustomFault("PortGroup not found from this vSwitch.");
	return 0;
}

sub setPortGroupVlanId
{
	my ($self, $name, $vlanid) = @_;
	
	if( $self->{host}->netMgr()->checkIfPortgroupIsInStandardVirtualSwitch($name, $self->name()) )
	{	
		return $self->{host}->netMgr()->setPortGroupVlanId($name, $vlanid);
	}
	$self->{host}->addCustomFault("PortGroup not found from this vSwitch.");
	return 0;
}

# ==============================================================
# VMKernel port operations
# ==============================================================

sub getVmkInterfaceIpAddress
{
	my ($self, $vmk) = @_;

	if( $self->{host}->netMgr()->checkIfVmkInterfaceIsInStandardVirtualSwitch($vmk, $self->name()) )
	{
		return $self->{host}->netMgr()->getVmkInterfaceIpAddress($vmk);
	}
	$self->{host}->addCustomFault("VMKernel Port not found from this vSwitch.");
	return 0;
}

sub getVmkInterfaceNetmask
{
	my ($self, $vmk) = @_;
	if( $self->{host}->netMgr()->checkIfVmkInterfaceIsInStandardVirtualSwitch($vmk, $self->name()) )
	{
		return $self->{host}->netMgr()->getVmkInterfaceNetmask($vmk);
	}
	$self->{host}->addCustomFault("VMKernel Port not found from this vSwitch.");
	return 0;
}

sub addVmkInterface
{
	my ($self, $pgname, $vlan, $ip, $mask) = @_;
	
	if( $self->addPortGroup($pgname, $vlan) )
	{
		my $dhcp_enable = 0;
		if( not $ip and not $mask )
		{
			$dhcp_enable = 1;
		}
		my $ip_spec = HostIpConfig->new(dhcp => $dhcp_enable, ipAddress => $ip, subnetMask => $mask);
		my $vnic_spec = HostVirtualNicSpec->new(ip => $ip_spec);
		
		eval
		{
			$self->{host}->netMgr()->netSys()->AddVirtualNic(portgroup => $pgname, nic => $vnic_spec);
		};
		my $fault = vEasy::Fault->new($@);
		if( $fault )
		{
			$self->{host}->addFault($fault);
			return 0;
		}
		return $self->{host}->netMgr()->getVmkInterfaceApiObjectByPortGroupName($pgname)->device;
	}
	return 0;
}


sub removeVmkInterface
{
	my ($self, $vmk) = @_;
	if( $self->{host}->netMgr()->checkIfVmkInterfaceIsInStandardVirtualSwitch($vmk, $self->name()) )
	{	
		return $self->{host}->netMgr()->removeVmkInterface($vmk);
	}
	$self->{host}->addCustomFault("VMKernel Port not found from this vSwitch.");
	return 0;
}

sub setVmkInterfaceIpAddress
{
	my ($self, $vmk, $ip, $netmask) = @_;
	if( $self->{host}->netMgr()->checkIfVmkInterfaceIsInStandardVirtualSwitch($vmk, $self->name()) )
	{	
		return $self->{host}->netMgr()->setVmkInterfaceIpAddress($vmk, $ip, $netmask);
	}
	$self->{host}->addCustomFault("VMKernel Port not found from this vSwitch.");
	return 0;
}

sub enableVmkInterfaceForManagement
{
	my ($self, $vmk) = @_;
	
	if( $self->{host}->netMgr()->checkIfVmkInterfaceIsInStandardVirtualSwitch($vmk, $self->name()) )
	{		
		return $self->{host}->netMgr()->setVmkInterfaceType($vmk, "management", 1);
	}
	$self->{host}->addCustomFault("VMKernel Port not found from this vSwitch.");
	return 0;	
}

sub enableVmkInterfaceForVmotion
{
	my ($self, $vmk) = @_;
	
	if( $self->{host}->netMgr()->checkIfVmkInterfaceIsInStandardVirtualSwitch($vmk, $self->name()) )
	{		
		return $self->{host}->netMgr()->setVmkInterfaceType($vmk, "vmotion", 1);
	}
	$self->{host}->addCustomFault("VMKernel Port not found from this vSwitch.");
	return 0;	
}

sub enableVmkInterfaceForFaultTolerance
{
	my ($self, $vmk) = @_;

	if( $self->{host}->netMgr()->checkIfVmkInterfaceIsInStandardVirtualSwitch($vmk, $self->name()) )
	{		
		return $self->{host}->netMgr()->setVmkInterfaceType($vmk, "faultToleranceLogging", 1);
	}
	$self->{host}->addCustomFault("VMKernel Port not found from this vSwitch.");
	return 0;		
}

sub enableVmkInterfaceForVsan
{
	my ($self, $vmk) = @_;
	
	if( $self->{host}->netMgr()->checkIfVmkInterfaceIsInStandardVirtualSwitch($vmk, $self->name()) )
	{		
		return $self->{host}->netMgr()->setVmkInterfaceType($vmk, "vsan", 1);
	}
	$self->{host}->addCustomFault("VMKernel Port not found from this vSwitch.");
	return 0;	
}

sub disableVmkInterfaceForManagement
{
	my ($self, $vmk) = @_;
	
	if( $self->{host}->netMgr()->checkIfVmkInterfaceIsInStandardVirtualSwitch($vmk, $self->name()) )
	{		
		return $self->{host}->netMgr()->setVmkInterfaceType($vmk, "management", 0);
	}
	$self->{host}->addCustomFault("VMKernel Port not found from this vSwitch.");
	return 0;	
}

sub disableVmkInterfaceForVmotion
{
	my ($self, $vmk) = @_;
	
	if( $self->{host}->netMgr()->checkIfVmkInterfaceIsInStandardVirtualSwitch($vmk, $self->name()) )
	{		
		return $self->{host}->netMgr()->setVmkInterfaceType($vmk, "vmotion", 0);
	}
	$self->{host}->addCustomFault("VMKernel Port not found from this vSwitch.");
	return 0;	
}

sub disableVmkInterfaceForFaultTolerance
{
	my ($self, $vmk) = @_;
	
	if( $self->{host}->netMgr()->checkIfVmkInterfaceIsInStandardVirtualSwitch($vmk, $self->name()) )
	{		
		return $self->{host}->netMgr()->setVmkInterfaceType($vmk, "faultToleranceLogging", 0);
	}
	$self->{host}->addCustomFault("VMKernel Port not found from this vSwitch.");
	return 0;	
}

sub disableVmkInterfaceForVsan
{
	my ($self, $vmk) = @_;
	
	if( $self->{host}->netMgr()->checkIfVmkInterfaceIsInStandardVirtualSwitch($vmk, $self->name()) )
	{		
		return $self->{host}->netMgr()->setVmkInterfaceType($vmk, "vsan", 0);
	}
	$self->{host}->addCustomFault("VMKernel Port not found from this vSwitch.");
	return 0;	
}

sub migrateVmkInterfaceToDistributedVirtualPortgroup
{
	my ($self, $vmk, $network) = @_;
	
	if( $network->isa("vEasy::DistributedVirtualPortgroup") )
	{
		my $port_connection = DistributedVirtualSwitchPortConnection->new(portgroupKey => $network->getKey(), switchUuid => $network->getDistributedVirtualSwitch()->getUuid());
		
		my $vmknic_spec = HostVirtualNicSpec->new(distributedVirtualPort => $port_connection);
		eval
		{	
			my $netsys = $self->{host}->vim()->getViewFromMoRef($self->{host}->getView()->configManager->networkSystem);
			$netsys->UpdateVirtualNic(device => $vmk, nic => $vmknic_spec);
		};
		my $fault = vEasy::Fault->new($@);
		if( $fault )
		{
			$self->{host}->addFault($fault);
			return 0;
		}
		return 1;
	}
	$self->addCustomFault("Invalid function argument - portgroup");
	return 0;
}


1;
