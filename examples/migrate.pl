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

my $cluster_options = {
    'dl.corp' => {
        default_datastore => 'ds08-nfs',
        dvswitch => 'DSwitch-DL',
        dcname => 'DataLine',
    },
    'm77.corp' => {
        default_datastore => 'ds11-nfs-m77',
        dvswitch => 'DSwitch-M77',
        dcname => 'M77',
    },
};

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
    vmname => {
        type => "=s",
        help => "VM name",
        required => 0,
    },
    target => {
        type => "=s",
        help => "Target host",
        required => 1,
    },
    host => {
        type => "=s",
        help => "Migrate all VMs from host",
        required => 0,
    },
};

Opts::add_options(%$opts);
Opts::parse();
Opts::validate();

my $vsphere_host = Opts::get_option('vsphere_host');
my $vsphere_username = Opts::get_option('vsphere_username');
my $vsphere_password = Opts::get_option('vsphere_password');
my $vmname = Opts::get_option('vmname');
my $target = Opts::get_option('target');
my $all_from_host = Opts::get_option('host');

if (!$all_from_host and !$vmname) {
    print "vmname or host required\n";
    exit 1;
}

my $vim = vEasy::Connect->new($vsphere_host, $vsphere_username, $vsphere_password) or
                                die "Can't connect to vCenter\n";

if ($all_from_host and !$vmname) {
    my $host = vEasy::HostSystem->new($vim, $all_from_host);
    my @task_list = ();

    foreach my $vm (@{ $host->getVirtualMachines() }) {
        my $vmname = $vm->name();

        print "Add add $vmname to migrate queue...";
        my $task = migrate($vmname, $target);

        if ($task) {
            print "OK\n";

            push @task_list, {
                task => $task,
                vm => $vm,
                last_percentage => 0,
            };

#             if ($#task_list > 9) {
#                 wait_tasks(\@task_list);
#             }
        } else {
            my $cluster = $host->getCluster();
            print "Error 2: " . $cluster->getLatestFaultMessage() . "\n";
        }
    }
} elsif (!$all_from_host and $vmname) {
    migrate($vmname, $target);
} else {
    print "Only one, vmname or host required set\n";
    exit 1;
}

# sub wait_tasks {
#     my ($task_list) = @_;
#     my $term = {};
#
#     require Term::Cap;
#     my $t = Term::Cap->Tgetent;
#     print $t->Tputs('cl'); # Clear screen
#
#     my $col = 1;
#
#     foreach my $task (@$task_list) {
#         my $percentage = $task->{task}->getProgress();
#         my $print_str = sprintf("...%02d%%", $percentage) if $task->{last_percentage} < $percentage;








sub migrate {
    my ($vmname, $target) = @_;
    my $vm = vEasy::VirtualMachine->new($vim, $vmname) or die "VM not found\n";
    my $view = $vm->getView();
    my $rp = $view->resourcePool();

    my $host = vEasy::HostSystem->new($vim, $target) or die "target not found\n";
    my $task = $vm->migrate($host);

    unless ($task) {
        my $cluster = $host->getCluster();
        print "\nError 2: " . $cluster->getLatestFaultMessage() . "\n";
        return;
    }

    if ($all_from_host) {
        return $task;
    }

    if ($task) {
        my $last_percentage = -1;
        while (($task->getState() eq 'running') or ($task->getState() eq 'queued')) {
            if ($task->getState() eq 'running') {
                my $percentage = $task->getProgress();
                printf("...%02d%%", $percentage) if $last_percentage < $percentage;
                $last_percentage = $percentage;
            } else {
                print "Wait queue...\n";
            }

            sleep 2;
            $task->refresh();
        }
        if ($task->getState() eq 'success') {
            print "...100%" if $last_percentage < 100;
            print "...OK\n";
        } elsif ($task->getState() eq 'error') {
            printf("\nError: %s\n%s\n", $task->getFaultType(), $task->getFaultMessage());
        }
    }
}

sub input_ask {
    my @variants = @_;
    my $default = '';

    my $query = sub {
        my @print_variants;
        foreach (@variants) {
            my ($variant, $is_default) = split /=/;
            my ($text, $highlight) = split(/\|/, $variant);
            $text = highlight($text, $highlight) if $highlight;
            $text = "[$text]" if $is_default;
            push @print_variants, $text;
        }

        return "(" . join("|", @print_variants) . "): ";
    };

    print &$query;

    while (chomp(my $answer = <>)) {
        foreach (@variants) {
            my ($variant, $is_default) = split /=/;
            my @alternatives = split(/\|/, $variant);
            $default = $alternatives[0] if $is_default;
            foreach (@alternatives) {
                return $alternatives[0] if $_ eq $answer;
            }
        }
        return $default if $default;
        print &$query;
    }
}

sub highlight {
    my ($text, $highlight) = @_;
    $text =~ s/($highlight)/\033[1m$1\033[m/;
    return $text;
}

sub load_zabbix_config {
    my ($config_file) = @_;

    open my $config_file_h, "<", $config_file or die "Can't open $config_file: $!\n";
    my $config_raw = join("", <$config_file_h>);
    close $config_file_h;

    return Load($config_raw) if $config_raw;
}

sub ok {
    my $obj = shift;
    if ($obj) {
        info("OK\n");
    } else {
        info("Fail");
        my ($vim_err, $obj_error);
        eval { $obj_error = $obj->getLatestFaultMessage() };
        eval { $vim_err = $vim->getLatestFaultMessage() };

        if ($obj_error) {
            info(": " . Dumper($obj_error));
        } elsif ($vim_err) {
            info(": " . Dumper($vim_err));
        }

        exit 1;
    }
}

sub info {
    my ($msg) = @_;
    print $msg;
}
