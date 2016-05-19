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
# File: 	Datacenter.pm
#
# Usage: 	my $dc = vEasy::Datacenter->new($vim, "GOLD_DS01");
# 			my $dc = vEasy::Datacenter->new($vim, $dc_view);
# 			my $dc = vEasy::Datacenter->new($vim, $dc_moref);
#			
#			where $vim is vEasy::Connect object
#
# Purpose:	This file is part of vEase Automation Framework. This class represents 
#			Datacenter in VMware vSphere infrastructure. 
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

package vEasy::Datacenter;

use strict;
use warnings;
use Data::Dumper;

our @ISA = qw(vEasy::Entity); 

# Constructor
sub new
{
	my ($class, $vim, $arg) = @_;
	
	my $self = $class->SUPER::new($vim, $arg, "Datacenter" );

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

sub getHostFolder
{
	my ($self) = @_;

	return vEasy::Folder->new($self->vim(), $self->getView()->hostFolder);
}

sub getVmFolder
{
	my ($self) = @_;

	return vEasy::Folder->new($self->vim(), $self->getView()->vmFolder);
}

sub getDatastoreFolder
{
	my ($self) = @_;

	return vEasy::Folder->new($self->vim(), $self->getView()->datastoreFolder);
}

sub getNetworkFolder
{
	my ($self) = @_;

	return vEasy::Folder->new($self->vim(), $self->getView()->networkFolder);
}

# ============================================================================================
# CREATEs 
# ============================================================================================

sub createChildFolder
{
	my ($self, $folder, $name) = @_;
	
	my $child = $folder->createFolder($name);
	if( $child )
	{
		return $child;
	}
	$self->addFault($folder->getLatestFault());
	return 0;
}

sub createVmFolder
{
	my ($self, $name) = @_;
	
	return $self->createChildFolder($self->getVmFolder(), $name);
}

sub createHostFolder
{
	my ($self, $name) = @_;
	
	return $self->createChildFolder($self->getHostFolder(), $name);
}

sub createDatastoreFolder
{
	my ($self, $name) = @_;
	
	return $self->createChildFolder($self->getDatastoreFolder(), $name);
}

sub createNetworkFolder
{
	my ($self, $name) = @_;
	
	return $self->createChildFolder($self->getNetworkFolder(), $name);
}

sub createCluster
{
	my ($self, $name) = @_;

	my $folder = $self->getHostFolder();
	my $cluster = $folder->createCluster($name);
	if( $cluster )
	{
		return $cluster;
	}
	$self->addFault($folder->getLatestFault());
	return 0;
}

1;