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
# File: 	Connect.pm
#
# Usage: 	my $vim = vEasy::Connect->new($address, $username, $password);
#
# Purpose:	This file is part of vEase Automation Framework. This class is used to 
#			connect to VMware vSphere Infrastructure (vCenter server or directly to
#			a host). It's mandatory to have a vEasy::Connect object before you can 
#			create other vEasy objects.
#
# vEasy Documentation
# https://github.com/emergy/vEasy/wiki
#
# VMware vSphere API Reference:
# https://www.vmware.com/support/developer/vc-sdk/
# 
# VMware vSphere SDK for Perl Documentation:
# https://www.vmware.com/support/developer/viperltoolkit/
#
# ====================================================================================

package vEasy::Connect;

use strict;
use warnings;
use VMware::VIRuntime;
use VMware::VILib;

use vEasy::Object;
use vEasy::Entity;
use vEasy::Folder;
use vEasy::Network;
use vEasy::ResourcePool;

use vEasy::Cluster;
use vEasy::CustomValuesManager;
use vEasy::Datacenter;
use vEasy::Datastore;
use vEasy::DatastoreCluster;
use vEasy::DistributedVirtualPortgroup;
use vEasy::DistributedVirtualSwitch;
use vEasy::Fault;
use vEasy::HostSystem;
use vEasy::HostSystemNetworkManager;
use vEasy::StandardVirtualSwitch;
use vEasy::Task;
use vEasy::VirtualApp;
use vEasy::VirtualMachine;
use Data::Dumper;

sub new
{
	my ($class, $address, $username, $password) = @_;

	my $vimobj = Vim->new(service_url => "https://$address/sdk");
	my $si = 0;
	
	eval
	{
		$vimobj->login(user_name => $username, password => $password);
		$si = $vimobj->get_service_instance();
	};

	if( $si =~ m/ServiceInstance/ )
	{
		my $self = { vim => $vimobj, faults => []};
		
		bless ($self, $class);
		return $self;
	}
	
	return 0;
}

sub DESTROY
{
	my ($self) = @_;
    Util::disconnect();
}

# ============================================================================================
# GETs 
# ============================================================================================

sub getServiceContent
{
	my ($self) = @_;
	return $self->{vim}->get_service_content();
}

sub getConnectionObject
{
	my ($self) = @_;
	return $self->{vim};
}

sub checkIfConnectedToVcenter
{
	my ($self) = @_;
	
	if( $self->getServiceContent()->about->apiType eq "VirtualCenter" )
	{
		return 1;
	}
	return 0;
}

sub checkIfConnectedToHost
{
	my ($self) = @_;
	
	if( $self->getServiceContent()->about->apiType eq "HostAgent" )
	{
		return 1;
	}
	return 0;
}

sub getRootFolder
{
	my ($self) = @_;
	
	my $sc_view = $self->{vim}->get_service_content();
	my $folder_view = $self->getViewFromMoRef($sc_view->rootFolder);

	return vEasy::Folder->new($self, $folder_view);
}

sub findView
{
	my ($self, $type, $filter, $properties) = @_;

	if( $properties )
	{
		return $self->{vim}->find_entity_view(view_type => $type, filter => $filter, properties => $properties);
	}
	return $self->{vim}->find_entity_view(view_type => $type, filter => $filter);
}

sub findViews
{
	my ( $self, $type, $filter, $properties) = @_;
	
	if( $properties )
	{
		return $self->{vim}->find_entity_views(view_type => $type, filter => $filter, properties => $properties);
	}
	return $self->{vim}->find_entity_views(view_type => $type, filter => $filter);
}

sub getViewFromMoRef
{
	my ($self, $ref) = @_;		
	return $self->{vim}->get_view(mo_ref => $ref);
}

sub getCluster
{
	my ($self, $arg) = @_;		
	return vEasy::Cluster->new($self, $arg);	
}

sub getDatacenter
{
	my ($self, $arg) = @_;		
	return vEasy::Datacenter->new($self, $arg);	
}

sub getDatastore
{
	my ($self, $arg) = @_;		
	return vEasy::Datastore->new($self, $arg);	
}

sub getDatastoreCluster
{
	my ($self, $arg) = @_;		
	return vEasy::DatastoreCluster->new($self, $arg);	
}

sub getDistributedVirtualPortgroup
{
	my ($self, $arg) = @_;		
	return vEasy::DistributedVirtualPortgroup->new($self, $arg);	
}

sub getDistributedVirtualSwitch
{
	my ($self, $arg) = @_;		
	return vEasy::DistributedVirtualSwitch->new($self, $arg);	
}

sub getFolder
{
	my ($self, $arg) = @_;		
	return vEasy::Folder->new($self, $arg);	
}

sub getHostSystem
{
	my ($self, $arg) = @_;		
	return vEasy::HostSystem->new($self, $arg);	
}

sub getNetwork
{
	my ($self, $arg) = @_;		
	return vEasy::Network->new($self, $arg);	
}

sub getResourcePool
{
	my ($self, $arg) = @_;		
	return vEasy::ResourcePool->new($self, $arg);	
}

sub getVirtualApp
{
	my ($self, $arg) = @_;		
	return vEasy::VirtualApp->new($self, $arg);	
}

sub getVirtualMachine
{
	my ($self, $arg) = @_;		
	return vEasy::VirtualMachine->new($self, $arg);	
}

sub getClusters
{
    my ($self) = @_;
    my $cl_list = $self->{vim}->find_entity_views(view_type => 'ClusterComputeResource');
    my @cluster_list;

    foreach my $cl (@$cl_list) {
        my $cluster = vEasy::Cluster->new($self, $cl);
        push @cluster_list, $cluster;
    }

    return \@cluster_list;
}

sub getDatacenters
{
    my ($self) = @_;
    my $dc_list = $self->{vim}->find_entity_views(view_type => 'Datacenter');
    my @datacenter_list;

    foreach my $dc (@$dc_list) {
        my $datacenter = vEasy::Datacenter->new($self, $dc);
        push @datacenter_list, $datacenter;
    }

    return \@datacenter_list;
}

# ============================================================================================
# Fault Handling 
# ============================================================================================

sub getAllFaults
{
	my ($self) = @_;
	
	return $self->{faults};
}

sub getLatestFault
{
	my ($self) = @_;
	
	if( @{$self->{faults}} > 0 )
	{
		return $self->{faults}->[-1];
	}
	return 0;
}

sub getLatestFaultMessage
{
	my ($self) = @_;
	
	if( $self->getLatestFault() )
	{
		return $self->getLatestFault()->getMessage();
	}
	return 0;
}

sub addFault
{
	my ($self, $fault) = @_;

	if( $fault )
	{
		if( $fault->isa("vEasy::Fault") )
		{
			push(@{$self->{faults}}, $fault);
			return 1;
		}
	}
	return 0;
}

sub addCustomFault
{
	my ($self, $message) = @_;
	
	my $fault = vEasy::Fault->new($message);
	return $self->addFault($fault);
}

1;
