#!/usr/bin/env perl
# WANT_JSON

use strict;
use warnings;
use Data::Dumper;
use Encode;
use JSON;           # perl-JSON
use Net::SSH2;      # perl-Net-SSH2
use vEasy::Connect; # https://github.com/emergy/vEasy

$Data::Dumper::Indent = 1;
$| = 1;

my $opts = {
    vsphere_host => {
        type => "=s",
        help => "vSphere hostname or ip address",
        required => 1,
    },
    vsphere_username => {
        type => "=s",
        help => "vSphere username",
        required => 1,
    },
    vsphere_password => {
        type => "=s",
        help => "vSphere password",
        required => 1,
    },
    target_host => {
        type => "=s",
        help => "Target host",
        required => 1,
    },
    target_username => {
        type => "=s",
        help => "Target host username ",
        required => 1,
    },
    target_password => {
        type => "=s",
        help => "Target host password ",
        required => 1,
    },
    cluster => {
        type => "=s",
        help => " The cluster in which to add the host",
        required => 1,
    },
    debug => {
        type => "=s",
        help => "Debug mode",
        required => 0,
    },
    dvsname => {
        type => "=s",
        help => "DistributedVirtualSwitch name",
        required => 1,
    },
    vmnic_list => {
        type => "=s",
        help => "DistributedVirtualSwitch vmnic list",
        required => 1,
    },
    storage_list => {
        type => "=s",
        help => "[storage1_name=]storage1_address:/volume,[storage2_name=]storage2_address:/volume,...",
        required => 0,
    },
    ntp_server_list => {
        type => "=s",
        help => "Server list for NTPD",
        required => 0,
    }
};


my $vsphere_config_file = $ENV{HOME} . "/.visdkrc";

if (-e $vsphere_config_file) {
    open my $vsphere_config_file_h, "<", $vsphere_config_file ||
                    die "Can't open $vsphere_config_file: $!\n";
    while (<$vsphere_config_file_h>) {
        chomp;
        s/["']//g;
        next if /^[#;]/;
        my ($key, $value) = split(/\s*=\s*/);
        if ($key eq "VI_SERVER") {
            $opts->{vsphere_host}->{default} = $value;
            $opts->{vsphere_host}->{required} = 0;
        }
        if ($key eq "VI_USERNAME") {
            $opts->{vsphere_username}->{default} = $value;
            $opts->{vsphere_username}->{required} = 0;
        }
        if ($key eq "VI_PASSWORD") {
            $opts->{vsphere_password}->{default} = $value;
            $opts->{vsphere_password}->{required} = 0;
        }
    }
}

Opts::add_options(%$opts);
Opts::parse();
Opts::validate();

my $vsphere_host = Opts::get_option('vsphere_host');
my $vsphere_username = Opts::get_option('vsphere_username');
my $vsphere_password = Opts::get_option('vsphere_password');
my $debug = Opts::get_option('debug');
my $target_host = Opts::get_option('target_host');
my $target_username = Opts::get_option('target_username');
my $target_password = Opts::get_option('target_password');
my $cluser_name = Opts::get_option('cluster');
my $dvsname = Opts::get_option('dvsname');
my $vmnic_list = Opts::get_option('vmnic_list');
my $storage_list = Opts::get_option('storage_list');
my $ntp_server_list_arg = Opts::get_option('ntp_server_list');

my @ntp_server_list = split(/[, ]/, $ntp_server_list_arg);

my $target_ssh_options = build_ssh_options({
    UserKnownHostsFile => '/dev/null',
    StrictHostKeyChecking => 'no',
    User => $target_username,
});

debug("Connecting to $vsphere_host...");
my $vim = vEasy::Connect->new($vsphere_host, $vsphere_username, $vsphere_password);


if ($vim) {
    debug("OK\n");

    debug("Connect to cluster $cluser_name...");
    my $cluster = $vim->getCluster($cluser_name);
    if ($cluster) {
        debug("OK\n");

        my $host;
        debug("Check host $target_host exist in cluster $cluser_name\n");
        $host = $vim->getHostSystem($target_host);

        if ($host) {
            debug("Host $target_host exist in cluster\n");
        } else {
            debug("Add host $target_host to cluster $cluser_name\n");
            $host = $cluster->addHost($target_host,
                                      $target_username,
                                      $target_password);
            if ($host) {
                debug("Host added to cluster: ".$host->name() . "\n");
            } else {
                debug($vim->getLatestFaultMessage() . "\n");
            }
        }

        if ($host) {
            if ($storage_list) {
                foreach my $storage (split(/,/, $storage_list)) {
                    if ($storage =~ /^(?:([^=]+)=)?([^:]+):(.+)$/) {
                        my $label = $1;
                        my $address = $2;
                        my $volume = $3;

                        mount_storage($host, $label, $address, $volume);
                    }
                }
            }

            debug("Check host $target_host exist in DistributedVirtualSwitch $dvsname\n");
            my $dvs = $vim->getDistributedVirtualSwitch($dvsname);

            if ($dvs) {
                if (check_host_in_dvs($dvs, $target_host)) {
                    debug("Host $target_host exist in DistributedVirtualSwitch $dvsname\n");
                } else {
                    debug("Add host $target_host to DistributedVirtualSwitch $dvsname...");

                    if ($dvs->addHostToDvs($vim->getHostSystem($target_host))->waitToComplete(60)) {
                        debug("OK\n");
                    } else {
                        debug($dvs->getLatestFaultMessage()."\n");
                    }
                }

                sleep 5;

                if ($vmnic_list) {
                    foreach my $vmnic (split(/[, ]/, $vmnic_list)) {
                        $dvs = $vim->getDistributedVirtualSwitch($dvsname);
                        debug("Add $vmnic to DistributedVirtualSwitch $dvsname\n");
                        my $host = $vim->getHostSystem($target_host);
                        if ($dvs->addHostPhysicalNicToDvs($host, $vmnic)->waitToComplete(60)) {
                            debug("$vmnic added to DistributedVirtualSwitch $dvsname\n");
                        } else {
                            debug($dvs->getLatestFaultMessage()."\n");
                        }
                    }
                }
            } else {
                debug($vim->getLatestFaultMessage() . "\n");
            }
        }

        debug("Reconfigure StandardVirtualSwitch...");
        reconfigure_StandardVirtualSwitch();
        debug("OK\n");

        if ($#ntp_server_list >= 0) {
            debug("Reconfigure NTPD...");
            reconfigure_ntpd($target_host, \@ntp_server_list);
        }
    } else {
        debug($vim->getLatestFaultMessage() . "\n");
    }
}

sub reconfigure_ntpd {
    my ($target_host, $ntp_server_list) = @_;
    my $host = $vim->getHostSystem($target_host);
    my $date_time_system = $vim->{vim}->get_view(mo_ref => $host->getView->configManager->dateTimeSystem);
    my $ntp_config = HostNtpConfig->new(server => $ntp_server_list);
    my $time_config = HostDateTimeConfig->new(ntpConfig => $ntp_config, timeZone => "UTC");
    eval { $date_time_system->UpdateDateTimeConfig(config => $time_config); };
    warn("UpdateDateTimeConfig: " . $@ . "\n") if ($@);
    my $service_system = $vim->{vim}->get_view(mo_ref => $host->getView->configManager->serviceSystem);
    eval { $service_system->StartService(id => "ntpd"); } ;
    warn("StartService(ntp): " . $@ . "\n") if ($@);
}

sub reconfigure_StandardVirtualSwitch {
    my ($vSwitch_name, $vmk) = ("vSwitch0", "vmk0");
    my $host = $vim->getHostSystem($target_host);
    my $vSwitch = $host->getStandardVirtualSwitch($vSwitch_name);
    my $IpAddress = $vSwitch->getVmkInterfaceIpAddress($vmk);
    my $VmkInterfaceNetmask = $vSwitch->getVmkInterfaceNetmask($vmk);
    $vSwitch->setVmkInterfaceIpAddress($vmk, $IpAddress, $VmkInterfaceNetmask);
    $vSwitch->enableVmkInterfaceForManagement($vmk);
    $vSwitch->enableVmkInterfaceForVmotion($vmk);
    $vSwitch->enableVmkInterfaceForFaultTolerance($vmk);
    #$vSwitch->enableVmkInterfaceForVsan($vmk);
}

sub check_host_in_dvs {
    my ($dvs, $target_host) = @_;
    my $return = 0;
    my $hosts = $dvs->getHosts();
    for (my $i = 0; $i < @$hosts; ++$i) {
        $return = 1 if $hosts->[$i]->name() eq $target_host;
    }
    return $return;
}

sub mount_storage {
    my ($host, $label, $address, $volume) = @_;
    my $skip = 0;

    eval {
        my $datastores = $host->getDatastores();
        for (my $i = 0; $i < @$datastores; ++$i) {
            if ($label eq $datastores->[$i]->name()) {
                debug("$label already is mouted\n");
                $skip = 1;
            }
        }
    };

    if (!$skip) {
        debug("Mounting $label=$address:$volume\n");
        my $datastore = $host->addNfsDatastore($address, $volume, $label);
        unless ($datastore) {
            print Dumper($host->getLatestFault());
            exit 1;
        } else {
            my $free_space = $datastore->getFreeCapacity();
            my $total_space = $datastore->getTotalCapacity();
            debug("$free_space Mb Free\n");
            debug("$total_space Mb Total\n");
        }
    }
}

sub _mount_storage {
    my ($label, $address, $volume) = @_;

    my $error_message = check_is_mounted($address, $volume);
    if ($error_message) {
        debug($error_message . "\n");
    } else {
        debug("Mounting $address:$volume");
        debug("as $label") if $label;
        debug("\n");

        my $ssh2 = Net::SSH2->new();
        $ssh2->connect($target_host) or die $!;
        if ($ssh2->auth_keyboard($target_username, $target_password)) {
            my $chan = $ssh2->channel();
            my $cmd = "esxcfg-nas -a -o $address -s $volume";
            $cmd .= " $label" if $label;
            print "Execute: $cmd\n" if $debug;
            $chan->exec($cmd);
            while (<$chan>) {
                debug($_);
            }
            $ssh2->disconnect();
        } else {
            my $error = $!;
            utf8::decode($error);
            die "$error\n";
        }
    }
}

sub check_is_mounted {
    my ($address, $volume) = @_;
    my $ret = 0;

    debug("Check $address:$volume is mounted\n");

    my $ssh2 = Net::SSH2->new();
    $ssh2->connect($target_host) or die $!;

    if ($ssh2->auth_keyboard($target_username, $target_password)) {
        my $chan = $ssh2->channel();
        $chan->exec('esxcfg-nas -l');
        while(<$chan>) {
            if (/$volume from $address mounted available/) {
                $ret = $_;
            }
        }
        $ssh2->disconnect();
    } else {
        my $error = $!;
        utf8::decode($error);
        die "$error\n";
    }
    return $ret;
}

sub build_ssh_options {
    my ($hash) = @_;
    my $return = '';
    while (my ($key, $value) = each %$hash) {
        $return .= "-o$key=$value ";
    }
    return $return;
}

sub debug {
    my ($line) = @_;
    my $log_file = '/var/log/vmware-add-host.log';
    open my $log_file_h, ">>", $log_file || die "Can't open $log_file: $!\n";
    print $log_file_h $line;
    print $line if $debug;
    close $log_file;
}
