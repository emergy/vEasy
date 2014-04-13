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
# File: 	Cluster.pm
#
# Usage: 	my $cluster = vEasy::Cluster->new($vim, "Cluster01");
# 			my $cluster = vEasy::Cluster->new($vim, $cluster_view);
# 			my $cluster = vEasy::Cluster->new($vim, $cluster_moref);
#			
#			where $vim is vEasy::Connect object
#
# Purpose:	This file is part of vEase Automation Framework. This class represents 
#			Cluster in VMware vSphere infrastructure.
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

package vEasy::Cluster;

use strict;
use warnings;
use Data::Dumper;

our @ISA = qw(vEasy::Entity); 

# Constructor
sub new
{
	my ($class, $vim, $arg) = @_;
	
	my $self = $class->SUPER::new($vim, $arg, "ClusterComputeResource");
	
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

sub getHosts
{
	my ($self) = @_;
	
	my @hostsystems = ();
	
	if( $self->getView()->host )
	{	
		for(my $i = 0; $i < scalar @{$self->getView()->host}; ++$i)
		{
			push(@hostsystems, vEasy::HostSystem->new($self->vim(), $self->getView()->host->[$i])); 
		}
	}
	return \@hostsystems;
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

sub getVirtualMachines
{
	my ($self) = @_;

	my @vms = ();
	my $hosts = $self->getHosts();

	for(my $i = 0; $i < scalar @$hosts; ++$i)
	{
		my $hostvms = $hosts->[$i]->getVirtualMachines();
		@vms = (@vms, @$hostvms); 
	}

	return \@vms;
}

sub getRootResourcePool
{
	my ($self) = @_;
	
	return vEasy::ResourcePool->new($self->vim(), $self->getView()->resourcePool);
}

sub getTotalAllocatedMemory
{
	my ($self) = @_;
	
	return $self->getRootResourcePool()->getTotalAllocatedMemory();
}

sub getTotalRuntimeMemoryUsage
{
	my ($self) = @_;
	
	return $self->getRootResourcePool()->getTotalRuntimeMemoryUsage();
}

sub getEffectiveMemoryCapacity
{
	my ($self) = @_;
	
	return $self->getView()->summary->effectiveMemory; #MB
}

sub getTotalMemory
{
	my ($self) = @_;
	
	return int($self->getView()->summary->totalMemory/1024/1024); #MB
}

sub getTotalRuntimeCpuUsage
{
	my ($self) = @_;
	
	return $self->getRootResourcePool()->getTotalRuntimeCpuUsage();
}

sub getEffectiveCpuCapacity
{
	my ($self) = @_;
	
	return $self->getView()->summary->effectiveCpu; #Mhz
}

sub getTotalCpuCapacity
{
	my ($self) = @_;
	
	return $self->getView()->summary->totalCpu; #Mhz
}

sub getTotalCpuCoreAmount
{
	my ($self) = @_;
	
	return $self->getView()->summary->numCpuCores; 
}

sub getTotalCpuThreadAmount
{
	my ($self) = @_;
	
	return $self->getView()->summary->numCpuThreads; 
}

sub getEffectiveHostAmount
{
	my ($self) = @_;
	
	return $self->getView()->summary->numEffectiveHosts; 
}

sub getHostAmount
{
	my ($self) = @_;
	
	return $self->getView()->summary->numHosts; 
}

sub isHaEnabled
{
	my ($self) = @_;
	
	if( $self->getView()->configuration->dasConfig->enabled )
	{
		return $self->getView()->configuration->dasConfig->enabled;
	}
	return 0;
}

sub isDrsEnabled
{
	my ($self) = @_;
	
	if( $self->getView()->configuration->drsConfig->enabled )
	{
		return $self->getView()->configuration->drsConfig->enabled; 
	}
	return 0;
}

sub configure
{
	my ($self, $spec) = @_;

	if( $spec->isa("ClusterConfigSpecEx") )
	{
		my $task = 0;
		eval
		{
			$task = $self->getView()->ReconfigureComputeResource_Task( spec => $spec, modify => 1 );
		};
		my $fault = vEasy::Fault->new($@);
		if( $fault )
		{
			$self->addFault($fault);
			return 0;
		}
		return vEasy::Task->new($self, $task);
	}
	$self->addCustomFault("Argument is not ClusterConfigSpecEx.");
	return 0;
}

sub enableDrs
{
	my ($self) = @_;
	
	my $drs_behavior = DrsBehavior->new("fullyAutomated");
		
	my $drs_info = ClusterDrsConfigInfo->new( defaultVmBehavior => $drs_behavior, enabled => 1, vmotionRate => 3);
	my $config_spec = ClusterConfigSpecEx->new(drsConfig => $drs_info);
			
	return $self->configure($config_spec);
}

sub disableDrs
{
	my ($self) = @_;
	
	my $drs_info = ClusterDrsConfigInfo->new( enabled => 0);
	my $config_spec = ClusterConfigSpecEx->new(drsConfig => $drs_info);
	
	return $self->configure($config_spec);
}

sub setDrsMigrationRate
{
	my ($self, $level) = @_;
	
	my $drs_info = ClusterDrsConfigInfo->new(vmotionRate => $level);
	my $config_spec = ClusterConfigSpecEx->new(drsConfig => $drs_info);
				
	return $self->configure($config_spec);
}

sub setDrsMode
{
	my ($self, $mode) = @_;
	
	my $drs_behavior = DrsBehavior->new($mode);
		
	my $drs_info = ClusterDrsConfigInfo->new(defaultVmBehavior => $drs_behavior);
	my $config_spec = ClusterConfigSpecEx->new(drsConfig => $drs_info);
			
	return $self->configure($config_spec);
}

sub setDrsModeToFullyAutomated
{
	my ($self) = @_;
	
	return $self->setDrsMode("fullyAutomated");
}

sub setDrsModeToPartiallyAutomated
{
	my ($self) = @_;
	
	return $self->setDrsMode("partiallyAutomated");
}

sub setDrsModeToManual
{
	my ($self) = @_;
	
	return $self->setDrsMode("manual");
}

sub enableHa
{
	my ($self, $ac_enable, $hostmonitoring_enable) = @_;
	
	my $hostmon = "enabled";
	if( not $hostmonitoring_enable )
	{
		$hostmon = "disabled";
	}
	if( not $ac_enable )
	{
		$ac_enable = 1;
	}
	my $ha_info = ClusterDasConfigInfo->new( enabled => 1, admissionControlEnabled => $ac_enable, hostMonitoring => $hostmon );
	
	my $config_spec = ClusterConfigSpecEx->new(dasConfig => $ha_info);
	
	return $self->configure($config_spec);
}

sub disableHa
{
	my ($self) = @_;
	
	my $ha_info = ClusterDasConfigInfo->new(enabled => 0);
	my $config_spec = ClusterConfigSpecEx->new(dasConfig => $ha_info);
	
	return $self->configure($config_spec);
}

sub setAdmissionControlFailOverHost
{
	my ($self, $host) = @_;
	
	if( $host->isa("vEasy::HostSystem") )
	{	
		my $ac_policy = ClusterFailoverHostAdmissionControlPolicy->new(failoverHosts => [$host->getView()]);
		my $ha_info = ClusterDasConfigInfo->new(admissionControlPolicy => $ac_policy);
		my $config_spec = ClusterConfigSpecEx->new(dasConfig => $ha_info);
		
		return $self->configure($config_spec);
	}
	$self->addCustomFault("Argument is not vEasy::HostSystem.");
	return 0;
}

sub setAdmissionControlFailOverLevel
{
	my ($self, $level) = @_;
	
	my $ac_policy = ClusterFailoverLevelAdmissionControlPolicy->new(failoverLevel => $level);
	my $ha_info = ClusterDasConfigInfo->new( admissionControlPolicy => $ac_policy );
	my $config_spec = ClusterConfigSpecEx->new(dasConfig => $ha_info);
	
	return $self->configure($config_spec);
}

sub setAdmissionControlFailOverResources
{
	my ($self, $cpu, $mem) = @_;
	
	my $ac_policy = ClusterFailoverResourcesAdmissionControlPolicy->new(cpuFailoverResourcesPercent => $cpu, memoryFailoverResourcesPercent => $mem);
	my $ha_info = ClusterDasConfigInfo->new( admissionControlPolicy => $ac_policy );
	my $config_spec = ClusterConfigSpecEx->new(dasConfig => $ha_info);
	
	return $self->configure($config_spec);
}

sub addHost
{
	my ($self, $address, $username, $password) = @_;
	
	my $ssl_cert = qx(echo "" | openssl s_client -connect $address:443 2> /dev/null 1> /tmp/cert);
	
	if( -e "/tmp/cert" )
	{
		my $fingerprint = qx(/usr/bin/openssl x509 -in /tmp/cert -fingerprint -sha1 -noout);
		
		if( $fingerprint =~ m/SHA1 Fingerprint=(.*)/ )
		{
			$fingerprint = $1; 
			my $connect_spec = HostConnectSpec->new(force => 0, hostName => $address, userName => $username, password => $password, sslThumbprint => $fingerprint );
			
			my $host = 0;
			eval
			{
				$host = $self->getView()->AddHost(spec => $connect_spec, asConnected => 1);
			};
			
			my $fault = vEasy::Fault->new($@);
			if( $fault )
			{
				$self->addFault($fault);
				return 0;
			}
			return vEasy::HostSystem->new($self->vim(), $host);
			# my $task = 0;
			# eval
			# {
				# $task = $self->getView()->AddHost_Task(spec => $connect_spec, asConnected => 1);
			# };
			# $task = vEasy::Task->new($self, $task);
			
			# my $fault = vEasy::Fault->new($@);
			# if( $fault )
			# {
				# $self->addFault($fault);
				# return 0;
			# }

			# if( $task->completedOk() )
			# {
				# return vEasy::HostSystem->new($self->vim(), $address);
			# }
			# else
			# {
				# $self->addCustomFault("Adding host to cluster failed.");
			# }
		}
		else
		{
			$self->addCustomFault("Couldn't get SHA1 Fingerprint from host certificate.");
		}
	}
	else
	{
		$self->addCustomFault("Host certficate could not be downloaded/saved.");
	}
	return 0;
}

sub createChildResourcePool
{
	my ($self, $poolname) = @_;
	
	my $rootrp = $self->getRootResourcePool();
	
	my $child = $rootrp->createChildResourcePool($poolname);
	if( $child )
	{
		return $child;
	}
	$self->addFault($rootrp->getLatestFault());
	return 0;
}

sub createVirtualMachine
{
	my ($self, $name, $folder, $ds) = @_;
	
	my $vm = $folder->createVirtualMachine($name, $self->getRootResourcePool(), $ds);
	
	if( $vm )
	{
		return $vm;
	}
	$self->addFault($folder->getLatestFault());
	return 0;
}

sub createVirtualApp
{
	my ($self, $name, $folder) = @_;
	
	my $rp = $self->getRootResourcePool();
	my $vm = $rp->createVirtualApp($name, $folder);
	
	if( $vm )
	{
		return $vm;
	}
	$self->addFault($rp->getLatestFault());
	return 0;
}

sub rescanStorageDevices
{
	my ($self) = @_;
	
	my $hosts = $self->getHosts();
	if( $hosts )
	{
		for(my $i = 0; $i < @$hosts; ++$i)
		{
			if( not $hosts->[$i]->rescanStorageDevices() )
			{
				$self->addFault($hosts->[$i]->getLatestFault());
			}
		}
		return 1;
	}
	$self->addCustomFault("No hosts in cluster.");
}

sub rescanVmfsDatastores
{
	my ($self) = @_;
	
	my $hosts = $self->getHosts();
	if( $hosts )
	{
		for(my $i = 0; $i < @$hosts; ++$i)
		{
			if( not $hosts->[$i]->rescanVmfsDatastores() )
			{
				$self->addFault($hosts->[$i]->getLatestFault());
			}
		}
		return 1;
	}
	$self->addCustomFault("No hosts in cluster.");
}


1;