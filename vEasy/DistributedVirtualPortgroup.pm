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
1;