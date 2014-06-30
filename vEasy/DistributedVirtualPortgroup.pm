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
# File: 	DistributedVirtualPortgroup.pm
#
# Usage: 	my $dvpg = vEasy::DistributedVirtualPortgroup->new($vim, "PG_VLAN2392");
# 			my $dvpg = vEasy::DistributedVirtualPortgroup->new($vim, $dvpg_view);
# 			my $dvpg = vEasy::DistributedVirtualPortgroup->new($vim, $dvpg_moref);
#			
#			where $vim is vEasy::Connect object
#
# Purpose:	This file is part of vEase Automation Framework. This class represents 
#			Distributed Virtual Portgroup in VMware vSphere infrastructure. 
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

package vEasy::DistributedVirtualPortgroup;

use strict;
use warnings;
use Data::Dumper;

our @ISA = qw(vEasy::Network); 

# Constructor
sub new
{
	my ($class, $vim, $arg) = @_;
	
	my $self = $class->SUPER::new($vim, $arg, "DistributedVirtualPortgroup" );
	
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

sub getDistributedVirtualSwitch
{
	my ($self) = @_;
	
	return vEasy::DistributedVirtualSwitch->new($self->vim(), $self->getView()->config->distributedVirtualSwitch);
}

sub getKey
{
	my ($self) = @_;
	
	return $self->getView()->key;
}

sub getConfigProperty
{
	my ($self, $propertyname) = @_;
	
	if( $self->getView()->config->{$propertyname} )
	{
		return $self->getView()->config->{$propertyname};
	}
	$self->addCustomFault("Property not set - $propertyname.");
	return 0;	
}

sub getAutoExpandStatus
{
	my ($self) = @_;
	
	return $self->getConfigProperty("autoExpand");	
}

sub getConfigVersion
{
	my ($self) = @_;
	
	return $self->getConfigProperty("configVersion");	
}

sub getDescription
{
	my ($self) = @_;
	
	return $self->getConfigProperty("description");	
}

sub getPortAmount
{
	my ($self) = @_;
	
	return $self->getConfigProperty("numPorts");	
}

sub getPortNameFormat
{
	my ($self) = @_;
	
	return $self->getConfigProperty("portNameFormat");	
}

sub getPortBindingType
{
	my ($self) = @_;
	
	return $self->getConfigProperty("type");	
}

sub configure
{
	my ($self, $spec) = @_;

	if( $spec->isa("DVPortgroupConfigSpec") )
	{
		$self->refresh();
		
		$spec->{configVersion} = $self->getConfigVersion();
		
		my $task = 0;
		eval
		{
			$task = $self->getView()->ReconfigureDVPortgroup_Task(spec => $spec);
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

sub setDescription
{
	my ($self, $desc) = @_;
	
	my $spec = DVPortgroupConfigSpec->new(description => $desc);
	
	return $self->configure($spec);
}

sub setPortAmount
{
	my ($self, $ports) = @_;
	
	my $spec = DVPortgroupConfigSpec->new(numPorts => $ports);
	
	return $self->configure($spec);
}

sub setPortBindingTypeToStaticBinding
{
	my ($self) = @_;
	
	my $spec = DVPortgroupConfigSpec->new(type => "earlyBinding");
	
	return $self->configure($spec);
}

sub setPortBindingTypeToDynamicBinding
{
	my ($self) = @_;
	
	my $spec = DVPortgroupConfigSpec->new(type => "lateBinding");
	
	return $self->configure($spec);
}

sub setPortBindingTypeToEphemeral
{
	my ($self) = @_;
	
	my $spec = DVPortgroupConfigSpec->new(type => "ephemeral");
	
	return $self->configure($spec);
}

sub enableAutoExpand
{
	my ($self) = @_;
	
	my $spec = DVPortgroupConfigSpec->new(autoExpand => 1);
	
	return $self->configure($spec);
}

sub disableAutoExpand
{
	my ($self) = @_;
	
	my $spec = DVPortgroupConfigSpec->new(autoExpand => 0);
	
	return $self->configure($spec);
}

sub blockTrafficOnAllPorts
{
	my ($self) = @_;
	
	my $port_config = VMwareDVSPortSetting->new(blocked => BoolPolicy->new(value => 1, inherited => 0));
	my $spec = DVPortgroupConfigSpec->new(defaultPortConfig => $port_config);

	return $self->configure($spec);
}

sub unblockTrafficOnAllPorts
{
	my ($self) = @_;
	
	my $port_config = VMwareDVSPortSetting->new(blocked => BoolPolicy->new(value => 0, inherited => 0));
	my $spec = DVPortgroupConfigSpec->new(defaultPortConfig => $port_config);

	return $self->configure($spec);
}

sub addToNetworkResourcePool
{
	my ($self, $poolname) = @_;
	
	my $key = $self->getDistributedVirtualSwitch()->getNetworkResourcePoolKeyByName($poolname);
	my $policy = StringPolicy->new(value => $key, inherited => 0);
	my $port_config = VMwareDVSPortSetting->new(networkResourcePoolKey => $policy);
	my $spec = DVPortgroupConfigSpec->new(defaultPortConfig => $port_config);
	
	return $self->configure($spec);
}

sub removeFromNetworkResourcePool
{
	my ($self) = @_;
	
	my $policy = StringPolicy->new(value => "-1", inherited => 0);
	my $port_config = VMwareDVSPortSetting->new(networkResourcePoolKey => $policy);
	my $spec = DVPortgroupConfigSpec->new(defaultPortConfig => $port_config);
	
	return $self->configure($spec);
}

sub setVlanTypeToNone
{
	my ($self) = @_;
	
	my $vlan_spec = VmwareDistributedVirtualSwitchVlanIdSpec->new(inherited => 0, vlanId => 0);
	my $port_config = VMwareDVSPortSetting->new(vlan => $vlan_spec);
	my $spec = DVPortgroupConfigSpec->new(defaultPortConfig => $port_config);

	return $self->configure($spec);
}

sub setVlanId
{
	my ($self, $vlanid) = @_;
	
	my $vlan_spec = VmwareDistributedVirtualSwitchVlanIdSpec->new(inherited => 0, vlanId => $vlanid);
	my $port_config = VMwareDVSPortSetting->new(vlan => $vlan_spec);
	my $spec = DVPortgroupConfigSpec->new(defaultPortConfig => $port_config);

	return $self->configure($spec);
}

sub setVlanTypeToTrunk
{
	my ($self, $vlanids) = @_;

	my @ranges = ();
	for(my $i = 0; $i < @$vlanids; ++$i)
	{
		my $range = $vlanids->[$i];
		if( $range =~ m/^(\d+)\-(\d+)$/ )
		{
			push(@ranges, NumericRange->new(start => $1, end => $2) );
		}
		elsif( $range =~ m/^(\d+)$/ )
		{
			push(@ranges, NumericRange->new(start => $1, end => $1) );
		}
		else
		{
			$self->addCustomFault("Invalid vlanid (range) - $range");			
			return 0;
		}
	}
	
	my $vlan_spec = VmwareDistributedVirtualSwitchTrunkVlanSpec->new(inherited => 0, vlanId => \@ranges);
	my $port_config = VMwareDVSPortSetting->new(vlan => $vlan_spec);
	my $spec = DVPortgroupConfigSpec->new(defaultPortConfig => $port_config);

	return $self->configure($spec);
}

sub setVlanTypeToPrivateVlan
{
	my ($self, $secondary_pvlan) = @_;
	
	my $vlan_spec = VmwareDistributedVirtualSwitchPvlanSpec->new(inherited => 0, pvlanId => $secondary_pvlan);
	my $port_config = VMwareDVSPortSetting->new(vlan => $vlan_spec);
	my $spec = DVPortgroupConfigSpec->new(defaultPortConfig => $port_config);

	return $self->configure($spec);
}

sub setSecurityOptions
{
	my ($self, $option, $value) = @_;
	
	my $pool_policy = BoolPolicy->new(value => $value, inherited => 0);
	my $sec_policy = DVSSecurityPolicy->new($option => $pool_policy, inherited => 0);
	my $port_config = VMwareDVSPortSetting->new(securityPolicy => $sec_policy);
	my $spec = DVPortgroupConfigSpec->new(defaultPortConfig => $port_config);

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

sub setUplinkPortToActive
{
	my ($self, $uplink) = @_;

	my $active = $self->getView()->config->defaultPortConfig->uplinkTeamingPolicy->uplinkPortOrder->{activeUplinkPort};

	if( not grep(/^$uplink$/, @$active) )
	{
		my $standby = $self->getView()->config->defaultPortConfig->uplinkTeamingPolicy->uplinkPortOrder->{standbyUplinkPort};
		@$standby = grep(!/^$uplink$/, @$standby);
		
		push(@$active, $uplink);
		
		my $uplink_order_policy = VMwareUplinkPortOrderPolicy->new(standbyUplinkPort => $standby, activeUplinkPort => $active, inherited => 0);
		my $teaming_policy = VmwareUplinkPortTeamingPolicy->new(uplinkPortOrder => $uplink_order_policy, inherited => 0);
		my $port_config = VMwareDVSPortSetting->new(uplinkTeamingPolicy => $teaming_policy);
		my $spec = DVPortgroupConfigSpec->new(defaultPortConfig => $port_config);

		return $self->configure($spec);
	}
	$self->addCustomFault("Uplink port already an active adapter - $uplink.");			
	return 0;	
}

sub setUplinkPortToStandby
{
	my ($self, $uplink) = @_;
	
	my $standby = $self->getView()->config->defaultPortConfig->uplinkTeamingPolicy->uplinkPortOrder->{standbyUplinkPort};

	if( not grep(/^$uplink$/, @$standby) )
	{
		my $active = $self->getView()->config->defaultPortConfig->uplinkTeamingPolicy->uplinkPortOrder->{activeUplinkPort};
		@$active = grep(!/^$uplink$/, @$active);
		
		push(@$standby, $uplink);
		
		my $uplink_order_policy = VMwareUplinkPortOrderPolicy->new(standbyUplinkPort => $standby, activeUplinkPort => $active, inherited => 0);
		my $teaming_policy = VmwareUplinkPortTeamingPolicy->new(uplinkPortOrder => $uplink_order_policy, inherited => 0);
		my $port_config = VMwareDVSPortSetting->new(uplinkTeamingPolicy => $teaming_policy);
		my $spec = DVPortgroupConfigSpec->new(defaultPortConfig => $port_config);

		return $self->configure($spec);
	}
	$self->addCustomFault("Uplink port already a standby adapter - $uplink.");			
	return 0;
}

sub setPhysicalNicToUnused
{
	my ($self, $uplink) = @_;
	
	
	my $active = $self->getView()->config->defaultPortConfig->uplinkTeamingPolicy->uplinkPortOrder->{activeUplinkPort};
	@$active = grep(!/^$uplink$/, @$active);
	
	my $standby = $self->getView()->config->defaultPortConfig->uplinkTeamingPolicy->uplinkPortOrder->{standbyUplinkPort};
	@$standby = grep(!/^$uplink$/, @$standby);
	
	my $uplink_order_policy = VMwareUplinkPortOrderPolicy->new(standbyUplinkPort => $standby, activeUplinkPort => $active, inherited => 0);
	my $teaming_policy = VmwareUplinkPortTeamingPolicy->new(uplinkPortOrder => $uplink_order_policy, inherited => 0);
	my $port_config = VMwareDVSPortSetting->new(uplinkTeamingPolicy => $teaming_policy);
	my $spec = DVPortgroupConfigSpec->new(defaultPortConfig => $port_config);
	
	return $self->configure($spec);
}

# ==============================================================
# vSwitch Teaming Policy Options 
# ==============================================================

sub setTeamingPolicyOptions
{
	my ($self, $option, $value) = @_;
	
	my $teaming_policy = VmwareUplinkPortTeamingPolicy->new($option => $value, inherited => 0);
	my $port_config = VMwareDVSPortSetting->new(uplinkTeamingPolicy => $teaming_policy);
	my $spec = DVPortgroupConfigSpec->new(defaultPortConfig => $port_config);
	return $self->configure($spec);
}

sub enableNotifySwitches
{
	my ($self) = @_;
	
	return $self->setTeamingPolicyOptions("notifySwitches", BoolPolicy->new(value => 1, inherited => 0));
}

sub disableNotifySwitches
{
	my ($self) = @_;
	
	return $self->setTeamingPolicyOptions("notifySwitches", BoolPolicy->new(value => 0, inherited => 0));
}

sub enableUplinkPortFailback
{
	my ($self) = @_;
	
	return $self->setTeamingPolicyOptions("rollingOrder", BoolPolicy->new(value => 0, inherited => 0));
}

sub disableUplinkPortFailback
{
	my ($self) = @_;
	
	return $self->setTeamingPolicyOptions("rollingOrder", BoolPolicy->new(value => 1, inherited => 0));
}

sub setUplinkPortLoadBalacingToRouteBasedOnIpHash
{
	my ($self) = @_;

	return $self->setTeamingPolicyOptions("policy", StringPolicy->new(value => "loadbalance_ip", inherited => 0));
}

sub setUplinkPortLoadBalacingToRouteBasedOnSourceMacHash
{
	my ($self) = @_;
	
	return $self->setTeamingPolicyOptions("policy", StringPolicy->new(value => "loadbalance_srcmac", inherited => 0));
}

sub setUplinkPortLoadBalacingToRouteBasedOnSourcePortId
{
	my ($self) = @_;
	
	return $self->setTeamingPolicyOptions("policy", StringPolicy->new(value => "loadbalance_srcid", inherited => 0));
}

sub setUplinkPortLoadBalacingToUseRouteBasedOnPhysicalNicLoad
{
	my ($self) = @_;
	
	return $self->setTeamingPolicyOptions("policy", StringPolicy->new(value => "loadbalance_loadbased", inherited => 0));
}

sub setUplinkPortLoadBalacingToUseExplicitFailoverOrder
{
	my ($self) = @_;
	
	return $self->setTeamingPolicyOptions("policy", StringPolicy->new(value => "failover_explicit", inherited => 0));
}

1;