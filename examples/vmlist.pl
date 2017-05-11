#!/usr/bin/env perl

use strict;
use warnings;
use vEasy::Connect;
use Net::Zabbix;
use Data::Dumper;
use Time::HiRes qw( usleep );
use YAML::XS;

$| = 1;
$Data::Dumper::Indent = 1;

my $opts = {
    vsphere_host => {
        type => "=s",
        help => "vSphere hostname or ip address",
        required => 0,
    },
    vsphere_username => {
        type => "=s",
        help => "vSphere username",
        required => 0,
    },
    vsphere_password => {
        type => "=s",
        help => "vSphere password",
        required => 0,
    },
    host => {
        type => "=s",
        help => "ESXi host",
        required => 0,
    },
};

Opts::add_options(%$opts);
Opts::parse();
Opts::validate();

my $vsphere_host = Opts::get_option('vsphere_host');
my $vsphere_username = Opts::get_option('vsphere_username');
my $vsphere_password = Opts::get_option('vsphere_password');
my $hostname = Opts::get_option('host');

my $vim = vEasy::Connect->new($vsphere_host, $vsphere_username, $vsphere_password) or
                                die "Can't connect to vCenter\n";

my $host = vEasy::HostSystem->new($vim, $hostname);

foreach my $vm (@{ $host->getVirtualMachines() }) {
    print $vm->name() . "\n";
}
