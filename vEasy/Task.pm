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
# File: 	Task.pm
#
# Purpose:	This file is part of vEase Automation Framework. This class represents 
#			Task in VMware vSphere infrastructure. Several functions of vEasy objects
#			return vEasy::Task objects.
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


package vEasy::Task;

use strict;
use warnings;

our @ISA = qw(vEasy::Object); 

# Constructor
sub new
{
	my ($class, $entity, $arg) = @_;
	
	my $self = $class->SUPER::new($entity->vim(), $arg, "Task" );

	if( $self )
	{
		$self->{vim} = $entity->vim();
		$self->{entity} = $entity;
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

sub getState
{
	my ($self) = @_;
	
	return $self->getView()->info->state->val;
}

sub getProgress
{
	my ($self) = @_;
	
	return $self->getView()->info->progress;
}

sub getStartTime
{
	my ($self) = @_;
	
	return $self->getView()->info->queueTime;
}

sub getDescription
{
	my ($self) = @_;
	
	return $self->getView()->info->descriptionId;
}

sub getCompleteTime
{
	my ($self) = @_;
	
	if( $self->getView()->info->completeTime )
	{
		return $self->getView()->info->completeTime;
	}
	return 0;
}

sub getFault
{
	my ($self) = @_;
	
	if( $self->getView()->info->error )
	{
		return $self->getView()->info->error;
	}
	return 0;
}

sub getFaultMessage
{
	my ($self) = @_;
	
	if( $self->getFault() )
	{
		return $self->getFault()->localizedMessage;
	}
	return 0;
}

sub getFaultType
{
	my ($self) = @_;
	
	if( $self->getFault() )
	{
		return ref($self->getFault()->fault);
	}
	return 0;
}

sub completedOk
{
	my ($self, $timeout) = @_;
	
	if( $self->waitToComplete($timeout) eq "success" )
	{
		return 1;
	}
	return 0;
}

sub completedFailed
{
	my ($self, $timeout) = @_;
	
	my $result = $self->waitToComplete($timeout);
	if( $result eq "error" or $result eq "timeouted" )
	{
		return 1;
	}
	return 0;
}

sub waitToComplete
{
	my ($self, $timeout) = @_;

	if( not $timeout )
	{
		$timeout = 1800;
	}
	
	for(my $i = 0; $i < $timeout; ++$i)
	{
		if( $self->getState() =~ m/(queued|running)/ )
		{	
			sleep(1);
			$self->refresh();
		}
		elsif( $self->getState() eq "success" )
		{
			return $self->getState();	
		}
		elsif( $self->getState() eq "error" )
		{
			my $fault = vEasy::Fault->new($self->getFault());
			$self->{entity}->addFault($fault);
			return $self->getState();	
		}
	}
	
	if( $self->cancel() )
	{
		$self->{entity}->addCustomFault("Task cancelled because it timeouted ($timeout secs}) - ".$self->getDescription());
	}
	else
	{
		$self->{entity}->addCustomFault("Task timeouted, cannot cancel ($timeout secs}) - ".$self->getDescription());
	}
	return 0;
}

sub cancel
{
	my ($self) = @_;
	
	eval
	{
		$self->getView()->CancelTask();
	};
	my $fault = vEasy::Fault->new($self->getFault());
	if( $fault )
	{
		$self->{entity}->addFault($fault);
		return 0;
	}
	return 1;
}

1;