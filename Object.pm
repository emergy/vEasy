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
# File: 	Object.pm
#
# Usage: 	my $obj = vEasy::Object->new($vim, $obj_view, "CustomFieldsManager");
# 			my $obj = vEasy::Object->new($vim, $obj_moref, "CustomFieldsManager");
#			
#			where $vim is vEasy::Connect object
#
# Purpose:	This file is part of vEase Automation Framework. This class is used to
#			create vEasy object from vSphere API object that are not Managed Entities.
#			This is mostly Internally by vEasy.
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

package vEasy::Object;

use strict;
use warnings;
use Data::Dumper;

# Constructor
sub new
{
	my ($class, $vim, $arg, $type) = @_;

	my $self = {vim => $vim, view => 0, type => $type};	
	
	if( $vim->isa("vEasy::Connect") )
	{
		if( $arg->isa($type) )
		{
			$self->{view} = $arg;
		}
		elsif( $arg->isa("ManagedObjectReference") )
		{
			my $view = $vim->getViewFromMoRef($arg);
			if( $view->isa($type) )
			{
				$self->{view} = $view;
			}
			else
			{
				return 0;
			}
		}
		else
		{
			return 0;
		}
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
	return $self->{view};
}

sub refresh
{
	my ($self) = @_;
	$self->{view}->update_view_data();
}	



1;