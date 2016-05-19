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
# File: 	CustomValuesManager.pm
#
# Purpose:	This file is part of vEase Automation Framework. This class is meant only 
#			for internal usage of this Framework. 
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

package vEasy::CustomValuesManager;

use strict;
use warnings;
use Data::Dumper;

our @ISA = qw(vEasy::Object); 

# Constructor
sub new
{
	my ($class, $vim) = @_;
	
	my $self = $class->SUPER::new($vim, $vim->getServiceContent()->customFieldsManager, "CustomFieldsManager" );
	
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

sub checkIfCustomValueFieldExists
{
	my ($self, $name) = @_;
	
	my $custom_values = $self->getView()->field;

	if( $custom_values )
	{
		my $key = 0;
		for(my $i = 0; $i < scalar @$custom_values; ++$i) 
		{
			if($custom_values->[$i]->name eq $name)
			{
				return $custom_values->[$i]->key;
			}
		}
	}
	return 0;
}

sub getEntityCustomValue
{
	my ($self, $entity, $name) = @_;	
	
	my $key = $self->checkIfCustomValueFieldExists($name);
	
	my $entity_customvalues = $entity->getView()->customValue;
	
	if( $entity_customvalues )
	{
		for(my $i = 0; $i < scalar @$entity_customvalues; ++$i) 
		{
			if($entity_customvalues->[$i]->key eq $key)
			{
				return $entity_customvalues->[$i]->value;
			}
		}
	}
	return 0;
}

sub addCustomValueField
{
	my ($self, $name, $type) = @_;	
	
	my $key = $self->checkIfCustomValueFieldExists($name);
	if( not $key )
	{
		if( not $type )
		{
			$key = $self->getView()->AddCustomFieldDef(name => $name)->key;
		}
		else
		{
			$key = $self->getView()->AddCustomFieldDef(name => $name, moType => $type)->key;
		}
	}
	return $key;
}

sub setEntityCustomValue
{
	my ($self, $entity, $name, $value) = @_;
	
	my $key = $self->checkIfCustomValueFieldExists($name);
	if( $key )
	{
		eval
		{
			$self->getView()->SetField(entity => $entity->getView(), key => $key, value => $value);
		};
		my $fault = vEasy::Fault->new($@);
		if( $fault )
		{
			$entity->addFault($fault);
			return 0;
		}		
		return 1;
	}
	$entity->addCustomFault("Custom value field does not exists.");
	return 0;
}

sub deleteCustomValueField
{
	my ($self, $name) = @_;
	
	my $key = $self->checkIfCustomValueFieldExists($name);
	if( $key )
	{
		$self->getView()->RemoveCustomFieldDef(key => $key);
		return 1;
	}
	return 0;
}