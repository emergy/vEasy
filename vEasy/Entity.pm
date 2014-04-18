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
# File: 	Entity.pm
#
# Usage: 	my $host = vEasy::Entity->new($vim, "host256", "HostSystem");
# 			my $host = vEasy::Entity->new($vim, $host_view, "HostSystem");
# 			my $host = vEasy::Entity->new($vim, $host_moref, "HostSystem");
#			
#			where $vim is vEasy::Connect object
#
# Purpose:	This file is part of vEase Automation Framework. This class is the base 
#			class for all Managed Entities and should not be used directly.  
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

package vEasy::Entity;

use strict;
use warnings;
use Data::Dumper;

# Constructor
sub new
{
	my ($class, $vim, $arg, $type) = @_;

	my $self = {vim => $vim, moref => 0, view => 0, type => $type, faults => [], tasks => [] };	
	
	if( $vim->isa("vEasy::Connect") )
	{
		if( \$arg =~ m/SCALAR/ )
		{
			$self->{view} = $vim->findView($type, { name => $arg });
			if( not $self->{view} ) 
			{
				$vim->addCustomFault("Entity not found.");
				return 0;
			}
		}
		elsif( $arg->isa($type) )
		{
			$self->{view} = $arg;
		}
		elsif( $arg->isa("ManagedObjectReference") )
		{
			if( $arg->{type} eq $type )
			{
				$self->{moref} = $arg;
			}

			else
			{
				$vim->addCustomFault("Invalid Entity Type in ManagedObjectReference.");
				return 0;
			}
		}
		else
		{
			$vim->addCustomFault("Invalid argument.");
			return 0;
		}
	}
	else
	{
		$vim->addCustomFault("Argument is not a vEasy::Connect object.");
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

# ============================================================================================
# GETs
# ============================================================================================

sub name
{
	my ($self) = @_;
	return $self->getView()->name;
}	

sub vim
{
	my ($self) = @_;
	return $self->{vim};
}	

sub getType
{
	my ($self) = @_;
	return $self->{type};
}

sub getView
{
	my ($self) = @_;
	
	if( not $self->{view} )
	{
		$self->{view} = $self->vim()->getViewFromMoRef($self->{moref});
	}
	return $self->{view};
}

sub getInventoryPath
{
	my ($self) = @_;
	
	return Util::get_inventory_path($self->getView(), $self->vim()->getConnectionObject());
}

sub getManagedObjectReference
{
	my ($self) = @_;
	return $self->getView()->{mo_ref};
}

sub getManagedObjectId
{
	my ($self) = @_;
	return $self->getView()->{mo_ref}->value;
}

sub getParent
{
	my ($self) = @_;
	
	if( $self->getView()->parent )
	{
		my $parent = $self->getView()->parent;

		if( $parent->type eq "Folder" )
		{
			return vEasy::Folder->new($self->vim(), $parent);
		}
		elsif( $parent->type eq "DatastoreCluster" )
		{
			return vEasy::DatastoreCluster->new($self->vim(), $parent);
		}
		elsif( $parent->type eq "ResourcePool" )
		{
			return vEasy::ResourcePool->new($self->vim(), $parent);
		}
		elsif( $parent->type eq "ClusterComputeResource" )
		{
			return vEasy::Cluster->new($self->vim(), $parent);
		}
	}
	$self->addCustomFault("Entity has no parent.");
	return 0;
}

sub getStatus
{
	my ($self) = @_;
	
	return $self->getView()->overallStatus->val;
}

sub refresh
{
	my ($self) = @_;

	$self->getView()->update_view_data();
	return 1;
}

# ============================================================================================
# Entity modification
# ============================================================================================

sub remove
{
	my ($self) = @_;

	my $task = 0;
	eval
	{
		$task = $self->getView()->Destroy_Task();
	};
	my $fault = vEasy::Fault->new($@);
	if( $fault )
	{
		$self->addFault($fault);
		return 0;
	}
	return vEasy::Task->new($self, $task);
}

sub rename
{
	my ($self, $newname) = @_;
	
	my $task = 0;
	eval
	{
		$task  = $self->getView()->Rename_Task(newName => $newname);
	};
	my $fault = vEasy::Fault->new($@);
	if( $fault )
	{
		$self->addFault($fault);
		return 0;
	}
	return vEasy::Task->new($self, $task);	
}

sub reload
{
	my ($self) = @_;
	
	eval
	{
		$self->getView()->Reload();	
	};
	my $fault = vEasy::Fault->new($@);
	if( $fault )
	{
		$self->addFault($fault);
		return 0;
	}
	return 1;
}


sub setCustomValue
{
	my ($self, $name, $value, $global) = @_;

	if( $self->vim()->checkIfConnectedToVcenter() )
	{
		my $custom_value_mgr = vEasy::CustomValuesManager->new($self->vim());
		
		my $type = undef;
		if( not $global )
		{
			$type = $self->getManagedObjectReference()->type;
		}
		if( $custom_value_mgr->addCustomValueField($name, $type) )
		{
			$custom_value_mgr->refresh();
			return $custom_value_mgr->setEntityCustomValue($self, $name, $value);
		}
	}
	$self->addCustomFault("Not connected to vCenter Server.");
	return 0;
}

sub getCustomValue
{
	my ($self, $name) = @_;	

	if( $self->vim()->checkIfConnectedToVcenter() )
	{	
		$self->refresh();
		my $custom_value_mgr = vEasy::CustomValuesManager->new($self->vim());
		return $custom_value_mgr->getEntityCustomValue($self, $name);
	}
	$self->addCustomFault("Not connected to vCenter Server.");
	return 0;
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