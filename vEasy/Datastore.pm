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
# File: 	Datastore.pm
#
# Usage: 	my $ds = vEasy::Datastore->new($vim, "GOLD_DS01");
# 			my $ds = vEasy::Datastore->new($vim, $ds_view);
# 			my $ds = vEasy::Datastore->new($vim, $ds_moref);
#			
#			where $vim is vEasy::Connect object
#
# Purpose:	This file is part of vEase Automation Framework. This class represents 
#			Datastore in VMware vSphere infrastructure. 
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

package vEasy::Datastore;

use strict;
use warnings;
use Data::Dumper;

our @ISA = qw(vEasy::Entity); 

# Constructor
sub new
{
	my ($class, $vim, $arg) = @_;
	
	my $self = $class->SUPER::new($vim, $arg, "Datastore" );
	
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
			push(@hostsystems, vEasy::HostSystem->new($self->vim(), $self->getView()->host->[$i]->key)); 
		}
	}
	return \@hostsystems;
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

sub getTotalCapacity
{
	my ($self) = @_;
	
	return int($self->getView()->summary->capacity/1024/1024); #MB
}

sub getFreeCapacity
{
	my ($self) = @_;
	
	return int($self->getView()->summary->freeSpace/1024/1024); #MB
}

sub getUsedCapacity
{
	my ($self) = @_;
	
	return $self->getTotalCapacity() - $self->getFreeCapacity(); #MB
}

sub getAllocatedCapacity
{
	my ($self) = @_;
	
	if( $self->getView()->summary->uncommitted )
	{
		return int($self->getView()->summary->uncommitted/1024/1024); #MB
	}
	return 0;
}

sub getFilesystemType
{
	my ($self) = @_;
	
	return $self->getView()->summary->type;
}

sub getVmfsVersion
{
	my ($self) = @_;
	
	if( $self->getView()->info->isa("VmfsDatastoreInfo") )
	{
		return $self->getView()->info->vmfs->majorVersion;
	}
	$self->addCustomFault("Not a VMFS datastore.");
	return 0;
}

sub getVmfsUuid
{
	my ($self) = @_;
	
	if( $self->getView()->info->isa("VmfsDatastoreInfo") )
	{
		return $self->getView()->info->vmfs->uuid;
	}
	$self->addCustomFault("Not a VMFS datastore.");
	return 0;
}

sub getDiskNames
{
	my ($self) = @_;
	
	if( $self->getView()->info->isa("VmfsDatastoreInfo") )
	{
		my $extents = $self->getView()->info->vmfs->extent;
		my @disk_names = ();
		
		for(my $i = 0; $i < @$extents; ++$i)
		{
			push(@disk_names, $self->getView()->info->vmfs->extent->[$i]->diskName);
		}
		return \@disk_names;
	}
	$self->addCustomFault("Not a VMFS datastore.");
	return 0;
}

sub getNfsAddress
{
	my ($self) = @_;
	
	if( $self->getView()->info->isa("HostNasVolume") )
	{
		return $self->getView()->info->nas->remoteHost;
	}
	$self->addCustomFault("Not a NAS datastore.");
	return 0;
}

sub getNfsPath
{
	my ($self) = @_;
	
	if( $self->getView()->info->isa("HostNasVolume") )
	{
		return $self->getView()->info->nas->remotePath;
	}
	$self->addCustomFault("Not a NAS datastore.");
	return 0;
}

sub getNfsUser
{
	my ($self) = @_;
	
	if( $self->getView()->info->isa("HostNasVolume") )
	{
		return $self->getView()->info->nas->userName;
	}
	$self->addCustomFault("Not a NAS datastore.");
	return 0;
}

sub refreshStorageInfo
{
	my ($self) = @_;
	
	eval
	{
		$self->getView()->RefreshDatastoreStorageInfo();
	};
	my $fault = vEasy::Fault->new($@);
	if( $fault )
	{
		$self->addFault($fault);
		return 0;
	}
	return 1;
}

sub remove
{
	my ($self) = @_;
	
	my $host = $self->getHosts()->[0];
	my $ds_system = $self->vim()->getViewFromMoRef($host->getView()->configManager->datastoreSystem);
	
	eval
	{
		$ds_system->RemoveDatastore( datastore => $self->getView() );
	};
	my $fault = vEasy::Fault->new($@);
	if( $fault )
	{
		$self->addFault($fault);
		return 0;
	}
	$self->{view} = undef;
	return 1;
}

sub expand
{
	my ($self) = @_;

	my $host = $self->getHosts()->[0];
	my $ds_sys_view = $self->vim()->getViewFromMoRef($host->getView()->configManager->datastoreSystem);

	my $ds_opts = 0;
	eval
	{
		$ds_opts = $ds_sys_view->QueryVmfsDatastoreExpandOptions( datastore => $self->getView() );
	};
	my $fault = vEasy::Fault->new($@);
	if( $fault )
	{
		$self->addFault($fault);
		return 0;
	}

	if( @$ds_opts )
	{
		eval
		{
			$ds_sys_view->ExpandVmfsDatastore( datastore => $self->getView(), spec => $ds_opts->[0]->spec );
		};
		my $fault = vEasy::Fault->new($@);
		if( $fault )
		{
			$self->addFault($fault);
			return 0;
		}
		return 1;
	}
	$self->addCustomFault("Couldn't get datastore expand options.");
	return 0;
}


1;