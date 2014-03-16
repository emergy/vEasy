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
# File: 	Folder.pm
#
# Usage: 	my $folder = vEasy::Folder->new($vim, "Production VMs");
# 			my $folder = vEasy::Folder->new($vim, $folder_view);
# 			my $folder = vEasy::Folder->new($vim, $folder_moref);
#			
#			where $vim is vEasy::Connect object
#
# Purpose:	This file is part of vEase Automation Framework. This class represents 
#			Folder in VMware vSphere infrastructure. 
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

package vEasy::Folder;

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
		$type = "Folder";
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

# ============================================================================================
# GETs 
# ============================================================================================

sub getChildEntities
{
	my ($self) = @_;
	my $childs = $self->getView()->childEntity;
	
	my @return = ();
	
	if( $childs )
	{
		for(my $i = 0; $i < scalar @$childs; ++$i)
		{
			my $child_type = $childs->[$i]->type;

			if( $child_type eq "Folder" )
			{
				push(@return, vEasy::Folder->new($self->vim(), $childs->[$i]));
			}
			elsif( $child_type eq "Datacenter" )
			{
				push(@return, vEasy::Datacenter->new($self->vim(), $childs->[$i]));
			}
			elsif( $child_type eq "ClusterComputeResource" )
			{
				push(@return, vEasy::Cluster->new($self->vim(), $childs->[$i]));
			}
			elsif( $child_type eq "ComputeResource" )
			{
				my $hostref = ($self->vim()->getViewFromMoRef($childs->[$i]))->host->[0];
				push(@return, vEasy::HostSystem->new($self->vim(), $hostref));
			}
			elsif( $child_type eq "VirtualMachine" )
			{
				push(@return, vEasy::VirtualMachine->new($self->vim(), $childs->[$i]));
			}
			elsif( $child_type eq "VirtualApp" )
			{
				push(@return, vEasy::VirtualApp->new($self->vim(), $childs->[$i]));
			}
			elsif( $child_type eq "Network" )
			{
				push(@return, vEasy::Network->new($self->vim(), $childs->[$i]));
			}
			elsif( $child_type eq "DistributedVirtualPortgroup" )
			{
				push(@return, vEasy::DistributedVirtualPortgroup->new($self->vim(), $childs->[$i]));
			}
			elsif( $child_type eq "VmwareDistributedVirtualSwitch" )
			{
				push(@return, vEasy::DistributedVirtualSwitch->new($self->vim(), $childs->[$i]));
			}
			elsif( $child_type eq "Datastore" )
			{
				push(@return, vEasy::Datastore->new($self->vim(), $childs->[$i]));
			}
			elsif( $child_type eq "DatastoreCluster" )
			{
				push(@return, vEasy::DatastoreCluster->new($self->vim(), $childs->[$i]));
			}
			else
			{
				$self->addCustomFault("Unknown child entity type: $child_type")
			}
		}
		
	}
	return \@return;
}

sub getValidChildTypes
{
	my ($self) = @_;
	
	if( $self->getView()->childType )
	{
		return $self->getView()->childType;
	}
	$self->addCustomFault("Couldn't get Folder child types.");
	return 0;
}

sub checkIfSubEntityExists
{
	my ($self, $name) = @_;
	
	my $childs = $self->getChildEntities();
	for(my $i = 0; $i < @$childs; ++$i)
	{
		if( $childs->[$i]->name eq $name )
		{
			return $childs->[$i];
		}
	}
	return 0;
}

sub isEntityValidChildType
{
	my ($self, $type) = @_;

	my $valid_types = $self->getValidChildTypes();
	for(my $i = 0; $i < scalar @$valid_types; ++$i)
	{
		if( $type eq "HostSystem" or $type eq "ClusterComputeResource" )
		{
			$type = "ComputeResource";
		}
		
		if( $valid_types->[$i] =~ m/$type/i )
		{
			return 1;
		}
		
	}
	return 0;
}

# ============================================================================================
# SETSs 
# ============================================================================================

sub createVirtualMachine
{
	my ($self, $name, $rp, $ds) = @_;

	if( $rp->isa("vEasy::ResourcePool") and $ds->isa("vEasy::Datastore") )
	{	
		my $vmpath = "[".$ds->name()."] $name/$name.vmx";

		my $files_info = VirtualMachineFileInfo->new(vmPathName => $vmpath);
		
		my $vm_conf_spec = VirtualMachineConfigSpec->new(name => $name, numCPUs => 1, numCoresPerSocket => 1, memoryMB => 32, files => $files_info, guestId => "winNetStandardGuest");	
		
		my $task = 0;
		eval
		{
			$task = vEasy::Task->new($self, $self->getView()->CreateVM_Task(config => $vm_conf_spec, pool => $rp->getView()));
		};
		my $fault = vEasy::Fault->new($@);
		if( $fault )
		{
			$self->addFault($fault);
			return 0;
		}
		
		if( $task->completedOk() )
		{
			$self->refresh();
			return $self->checkIfSubEntityExists($name);
		}
		else
		{
			$fault = vEasy::Fault->new($task->getFault());
			if( $fault )
			{
				$self->addFault($fault);
				return 0;
			}			
		}
	}
	$self->addCustomFault("Invalid function arguments.");
	return 0;
}

sub createDatacenter
{
	my ($self, $name) = @_;
	
	my $dc = 0;
	eval 
	{
		$dc = $self->getView()->CreateDatacenter(name => $name);
	};
	my $fault = vEasy::Fault->new($@);
	if( $fault )
	{
		$self->addFault($fault);
		return 0;
	}
	return vEasy::Datacenter->new($self->vim(), $dc);

}

sub createFolder
{
	my ($self, $name) = @_;
	
	my $folder = 0;
	eval
	{
		$folder = $self->getView()->CreateFolder(name => $name);
	};
	my $fault = vEasy::Fault->new($@);
	if( $fault )
	{
		$self->addFault($fault);
		return 0;
	}	
	return vEasy::Folder->new($self->vim(), $folder);
}

sub createCluster
{
	my ($self, $name) = @_;
	
	if( $self->isEntityValidChildType("ClusterComputeResource") )
	{
		my $cluster_conf_spec = ClusterConfigSpecEx->new();
		my $cluster = 0;
		eval
		{
			$cluster = $self->getView()->CreateClusterEx(name => $name, spec => $cluster_conf_spec);
		};
		my $fault = vEasy::Fault->new($@);
		if( $fault )
		{
			$self->addFault($fault);
			return 0;
		}				
		return vEasy::Cluster->new($self->vim(), $cluster);
	}
	$self->addCustomFault("Cluster is not a valid child type for this Folder.");
	return 0;
}

sub addHost
{
	my ($self, $address, $username, $password) = @_;
	
	if( $self->isEntityValidChildType("HostSystem") )
	{
		my $ssl_cert = qx(echo "" | openssl s_client -connect $address:443 2> /dev/null 1> /tmp/cert);
		my $fingerprint = qx(openssl x509 -in /tmp/cert -fingerprint -sha1 -noout);
		
		if( $fingerprint =~ m/SHA1 Fingerprint=(.*)/ )
		{
			$fingerprint = $1; 
			my $connect_spec = HostConnectSpec->new(force => 0, hostName => $address, userName => $username, password => $password, sslThumbprint => $fingerprint );
			
			my $task = 0;
			eval
			{
				$task = vEasy::Task->new($self, $self->getView()->AddStandaloneHost_Task(spec => $connect_spec, addConnected => 1));
			};
			my $fault = vEasy::Fault->new($@);
			if( $fault )
			{
				$self->addFault($fault);
				return 0;
			}				

			if( $task->completedOk() )
			{
				return vEasy::HostSystem->new($self->vim(), $address);
			}
		}
	}
	$self->addCustomFault("HostSystem is not a valid child type for this Folder.");
	return 0;
}

sub createDatastoreCluster
{
	my ($self, $name) = @_;
	
	my $folder = 0;
	eval
	{
		$folder = $self->getView()->CreateStoragePod(name => $name);
	};
	my $fault = vEasy::Fault->new($@);
	if( $fault )
	{
		$self->addFault($fault);
		return 0;
	}	
	return vEasy::DatastoreCluster->new($self->vim(), $folder);
}

sub createDistributedVirtualSwitch
{
	my ($self, $name) = @_;
	
	return 0;
}

sub moveEntityToFolder
{
	my ($self, $entity) = @_;
	
	if( $self->isEntityValidChildType($entity->getType()) )
	{
		my $task = 0;
		eval
		{
			$task = $self->getView()->MoveIntoFolder_Task(list => [$entity->getView()]);
		};
		my $fault = vEasy::Fault->new($@);
		if( $fault )
		{
			$self->addFault($fault);
			return 0;
		}
		return vEasy::Task->new($self, $task);
	}
	$self->addCustomFault($entity->getType()." is not a valid child type for this Folder.");
	return 0;
}


1;