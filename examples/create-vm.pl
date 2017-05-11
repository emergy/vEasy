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
    'sp.corp' => {
        default_datastore => 'N3',
        dcname => 'Office',
    },
};

my $opts = {
    hostname => {
        type => "=s",
        help => "Hostname in zabbix and ESXi",
        required => 1,
    },
    cpu => {
        type => "=s",
        help => "Configures CPU socket and cores per socket values to the virtual machine",
        default => "1:1",
    },
    mem => {
        type => "=s",
        help => "Memory size in megabytes",
        default => "512",
    },
    notes => {
        type => "=s",
        help => "Adds annotation note to the virtual machine",
    },
    cluster => {
        type => "=s",
        help => "ESXi claster",
        default => "m77.corp",
    },
    ds => {
        type => "=s",
        help => "Host datastore",
    },
    ip => {
        type => "=s",
        help => "VM IP address",
    },
    pool => {
        type => "=s",
        help => "ESXi resource pool",
    },
    app => {
        type => "=s",
        help => "ESXi virtual application name",
    },
    host => {
        type => "=s",
        help => "ESXi host",
    },
    vlan => {
        type => "=s",
        help => "ESXi port group name",
    },
    hdd => {
        type => "=s",
        help => "HDD size in gigabytes",
        default => "8",
    },
    os => {
        type => "=s",
        help => "OS dist for install after create VM",
        default => "c6r",
    },
    role => {
        type => "=s",
        help => "Server role",
        default => "vmware/default",
    },
    guest_os_identifier => {
        type => "=s",
        help => "https://www.vmware.com/support/developer/converter-sdk/conv61_apireference/vim.vm.GuestOsDescriptor.GuestOsIdentifier.html",
    },
    force => {
        type => "",
        help => "Overwrite exist VM",
        default => 0,
    },
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
    debug => {
        type => "=s",
        help => "Debug mode",
        required => 0,
    },
};

Opts::add_options(%$opts);
Opts::parse();
Opts::validate();

my $vsphere_host = Opts::get_option('vsphere_host');
my $vsphere_username = Opts::get_option('vsphere_username');
my $vsphere_password = Opts::get_option('vsphere_password');
my $cluster_name = Opts::get_option('cluster');
my $vm_hostname = Opts::get_option('hostname');
my $cpu_arg = Opts::get_option('cpu');
my $memory_size = Opts::get_option('mem');
my $guest_os_identifier = Opts::get_option('guest_os_identifier');
my $os = Opts::get_option('os');
my $role = Opts::get_option('role');
my $notes =  Opts::get_option('notes');
my $hdd = Opts::get_option('hdd');
my $vlan = Opts::get_option('vlan');
my $force = Opts::get_option('force');
my $ip = Opts::get_option('ip') || ask_ip();
my $esxi_host = Opts::get_option('host');
my $debug = Opts::get_option('debug');

if ($ip !~ /^(?:\d{1,3}\.){3}\d{1,3}$/) {
    print "IP address is not valid\n";
    exit 1;
}

info("Read zabbix config...");
my $zabbix_config = load_zabbix_config($ENV{HOME} . "/.zabbix");
ok($zabbix_config);

info("Connect to zabbix host [$zabbix_config->{url}]...");
my $zabbix = Net::Zabbix->new(
    $zabbix_config->{url},
    $zabbix_config->{username},
    $zabbix_config->{password},
);
ok($zabbix);

my $zhost = zabbix_search_host({ host => $vm_hostname });


if ($zhost) {
    print "Zabbix host $vm_hostname is exist!!! ";
    print "Zabbix host info:\n";
    zabbix_host_show_info($zhost);

    my $answer;
    if ($force) {
        $answer = 'delete';
    } else {
        $answer = input_ask("update|u", "delete|d=default", "cancel|c");
    }

    if ($answer eq 'delete') {
        info("\nDeleting zabbix host $vm_hostname...");
        my $responce = zabbix_responce($zabbix->delete('host', [ $zhost->{hostid} ]));
        ok($responce);
        $zhost = create_zabbix_host();
    } elsif ($answer eq 'cancel') {
        print "Cancel\n";
        exit 0;
    }
} else {
    $zhost = create_zabbix_host();
}

info("Connecting to vCenter...");
my $vim = vEasy::Connect->new($vsphere_host, $vsphere_username, $vsphere_password);
ok($vim);

info("Connect to cluster $cluster_name...");
my $cluster = $vim->getCluster($cluster_name);
ok($cluster);

my $host;
if ($esxi_host) {
    info("Search $esxi_host in $cluster_name...");
    $host = $vim->getHostSystem($esxi_host);
} else {
    info("Get free memory host...\n");
    $host = get_free_host($cluster);
}
ok($host);

info("Get datastore...\n");
my $ds = get_datastore($host);

info("Check VM $vm_hostname is exist...");
my $vm = chk_vm_exist($host, $vm_hostname);
if ($vm) {
    my $host = $vm->getHost()->name;
    info("already exist in $host\n");

    show_table({
        "Power state" => $vm->getPowerState(),
        "Powered on date" => $vm->getPowerOnDate(),
        "Memory size" => $vm->getMemory(),
        "vCPU sockets" => $vm->getCpuSockets(),
        "vCPU cores" => $vm->getCpuCores(),
        "OS type" => $vm->getGuestOperatingSystemType(),
        "Disk usage" => $vm->getTotalUsedDiskSize(),
        "Allocated disk size" => $vm->getTotalAllocatedDiskSize(),
        "IP address" => $vm->getGuestIpAddress(),
        "Notes" => $vm->getNotes(),
        "MAC address" => get_mac_address($vm),
    });

    if (!$force) {
        print "Delete $vm_hostname? ";
        if (input_ask("yes|y=default", "no|n") eq 'y') {
            exit 1;
        }
    }
    if ($vm->getPowerState() ne 'poweredOff') {
        info("Send power off for " . $vm->name() . "...");
        ok($vm->powerOff()->waitToComplete(60));
    }

    info("Remove from invertory...");
    ok($vm->remove()->waitToComplete(60));
} else {
    info("not exist\n");
}

info("Create VM $vm_hostname...");
$vm = createVM($host, $vm_hostname, $ds);
$vm->refresh();

info("Set CPU options...");
ok(set_cpu_options($vm));
$vm->refresh();

info("Set memory size [$memory_size]...");
ok(set_memory_size($vm, $memory_size));
$vm->refresh();

info("Configures operating system type of the virtual machine...");
ok(set_vm_guest_os_identifier($vm));
$vm->refresh();

if ($notes) {
    info("Set VM notes...");
    ok($vm->setNotes($notes)->waitToComplete(60));
    $vm->refresh();
}

info("Adding some SCSI controller...");
ok($vm->addLsiLogicScsiController(0)->waitToComplete(60));

info("Add virtual disk [$hdd Gb]...");
ok($vm->addThinVirtualDisk("SCSI controller 0", 0, $hdd)->waitToComplete(60));
$vm->refresh();

my $network = get_network($vlan);


info("Adding network adapters...");
ok($vm->addVmxnet3NetworkAdapter($network)->waitToComplete(60));
$vm->refresh();

my $vm_macaddress = get_mac_address($vm);

my $macros = [
    {
        macro => '{$PXE.MAC}',
        value => $vm_macaddress,
    },
    {
        macro => '{$PXE.OS}',
        value => $os,
    },
];

if ($role) {
    push @$macros, {
        macro => '{$PXE.ROLE}',
        value => $role,
    };
}

push @$macros, {
    macro => '{$PXE.STATUS}',
    value => 1,
};

update_macros($zhost, $macros);

reload_pxe();

info("Starting VM...");
ok($vm->powerOn()->waitToComplete(60));

print "\n";
vm_info($vm);
zabbix_host_show_info(zabbix_search_host({ host => $vm_hostname }));
print "\n";

sub zabbix_host_show_info {
    my ($zabbix_host) = @_;
    printf("%30s: %s\n", "Zabbix hostname", $zabbix_host->{host});
    printf("%30s: %s\n", "Monitoring status", $zabbix_host->{status} ? "disable" : "enable");
    printf("%30s: %s\n", "Interfaces", join(", ", map { $_ = $_->{ip} } @{ $zabbix_host->{interfaces} }));
    printf("%30s:\n", "Macros") if $zabbix_host->{macros} and $#{$zabbix_host->{macros}} >= 0;

    my $max_len = 0;
    foreach (@{ $zabbix_host->{macros} }) {
        my $current_len = length($_->{macro}) + 1;
        $max_len = $current_len if $current_len > $max_len;
    }
    foreach (@{ $zabbix_host->{macros} }) {
        print " "x32;
        printf("%-${max_len}s: %s\n", $_->{macro}, $_->{value});
    }
}

sub vm_info {
    my ($vm) = @_;

    show_table({
        "Power state" => $vm->getPowerState(),
        "Powered on date" => $vm->getPowerOnDate(),
        "Memory size" => $vm->getMemory(),
        "vCPU sockets" => $vm->getCpuSockets(),
        "vCPU cores" => $vm->getCpuCores(),
        "OS type" => $vm->getGuestOperatingSystemType(),
        "Disk usage" => $vm->getTotalUsedDiskSize(),
        "Allocated disk size" => $vm->getTotalAllocatedDiskSize(),
        "IP address" => $vm->getGuestIpAddress(),
        "Notes" => $vm->getNotes(),
        "MAC address" => get_mac_address($vm),
    });
}

sub ask_ip {
    my $default = '127.0.0.1';
    return $default if $force;
    my $message = "Enter VM IP address [127.0.0.1]: ";
    print $message;
    while (chomp(my $stdin = <>)) {
        return $default if $stdin eq '';
        if ($stdin =~ /(?:\d{1,3}\.){3}\d{1,3}/) {
            return $stdin;
        }
        print $message;
    }
}

sub reload_pxe {
    system("curl -s http://x.corp/pxe/reload.php >/dev/null");
}

sub createVM {
    my ($host, $name, $ds) = @_;
    my $pool = Opts::get_option('pool');
    my $app = Opts::get_option('app');
    my $host_name = $host->name();

#     my $folder = $ds->vim()->getRootFolder()->getChildEntities()->[0]->getVmFolder();
#     my $childs = $folder->getView()->childEntity;
#     foreach (@$childs) {
#         if ($_->type eq 'Folder') {
#             $folder = vEasy::Folder->new($folder->vim(), $_);
#         }
#     }
#     my $folder;
#     my $conn = $vim->getConnectionObject();
#     my $dcviews = $conn->find_entity_views(view_type => 'Datacenter',
#                                 properties => [ 'hostFolder', 'vmFolder' ]);
#     foreach my $dcview (@$dcviews) {
#         my $host = $conn->find_entity_view(begin_entity => $dcview->hostFolder,
#                     view_type => "HostSystem", filter => { name => $host_name });
#         if ($host) {
#             $folder = $conn->get_view(mo_refi => $dcview->vmFolder);
# #             my $childs = $folder->getView()->childEntity;
# #             foreach (@$childs) {
# #                 if ($_->type eq 'Folder') {
# #                     $folder = vEasy::Folder->new($folder->vim(), $_);
# #                     last;
# #                 }
# #             }
#         }
#     }

    my $dc_name = $cluster_options->{$cluster_name}->{dcname};
    my $dc = vEasy::Datacenter->new($cluster->{vim}, $dc_name);

    my $vm;

    if ($app) {
        my $vapp = vEasy::VirtualApp->new($cluster->{vim}, $app);

        if (!$vapp) {
            print "VirtualApp $app not found\n";
            exit 1;
        }

        $vm = $vapp->createVirtualMachine($name, $ds);

        if (!$vm) {
            print Dumper($vapp->getLatestFault());
            exit 1;
        } else {
            print "OK\n";
        }
    } else {
        my $rp = $cluster->getRootResourcePool();

        my $folder = $dc->getVmFolder();
        $vm = $folder->createVirtualMachine($name, $rp, $ds);

        if (!$vm) {
            print Dumper($folder->getLatestFault());
            exit 1;
        } else {
            print "OK\n";
        }

        $vm->refresh();

        if ($pool) {
            info("Move $name to ResourcePool '$pool'...");
            my $res_pool;
            my $pools = $rp->getChildResourcePools();
            foreach (@$pools) {
                if ($_->name() eq $pool) {
                    $res_pool = $_;
                }
            }
            ok($res_pool->moveEntityToResourcePool($vm));
        }

        if (!$rp) {
            print "ResourcePool $pool not found\n";
            exit 1;
        }
    }

    return $vm;
}

sub update_macros {
    my ($host, $macros) = @_;
    info("Update zabbix macros...");

    my $update_responce = $zabbix->update('host', {
        hostid => $host->{hostid},
        macros => $macros,
    });

    ok(zabbix_responce($update_responce));
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

sub create_zabbix_host {
    info("Create host [$vm_hostname] in zabbix...");
    my $zabbix_create = $zabbix->create('host', {
        host => $vm_hostname,
        interfaces => [
            {
                type => 1,
                main => 1,
                useip => 1,
                ip => $ip,
                dns => "",
                port => "10050",
            },
        ],
        groups => [
            {
                groupid => 89,
            }
        ],
#         templates => [
#             {
#                 templateid => 0,
#             }
#         ],
        inventory_mode => 0,
        inventory => {
            type => "vmware",
        },
    });

    my $responce = zabbix_responce($zabbix_create);
    my $created_hostid = $responce->{hostids}->[0];
    info("OK\n") if $created_hostid;
    return zabbix_search_host({ hostid => $created_hostid });
}

sub zabbix_search_host {
    my ($filter) = @_;
    my $search_obj = $zabbix->get('host', {
        selectMacros => 'extend',
        selectInventory => 'extend',
        selectInterfaces => 'extend',
        filter => $filter,
    });
    my $responce = zabbix_responce($search_obj);
    return $responce->[0] if $#$responce > -1;
}

sub zabbix_responce {
    my ($responce) = @_;

    if ($responce->{error}) {
        print $responce->{error}->{message} . ": ";
        print $responce->{error}->{data};
        exit 1;
    } else {
        return $responce->{result};
    }
}

sub load_zabbix_config {
    my ($config_file) = @_;

    open my $config_file_h, "<", $config_file or die "Can't open $config_file: $!\n";
    my $config_raw = join("", <$config_file_h>);
    close $config_file_h;

    return Load($config_raw) if $config_raw;
}

sub get_mac_address {
    my ($vm) = @_;

    my @nics = grep {
        $_->isa("VirtualEthernetCard")
    } @{ $vm->getView()->config->hardware->device };

    foreach my $nic (@nics) {
        return $nic->macAddress();
    }
}

sub get_network {
    my ($vlan) = @_;
    my $networks = $cluster->getNetworks();

    my @vlan_list;

    foreach my $network (@$networks) {
        my $name = $network->name();
        push @vlan_list, $name;
        return $network if ($vlan) and ($name eq $vlan);
    }

    print "VLAN list:\n\t" . join("\n\t", sort { $a cmp $b } @vlan_list) . "\n";
    print "Enter valid VLAN name: ";

    chomp(my $answer = <STDIN>);
    return get_network($answer);
}

sub show_table {
    my ($table) = @_;
    while (my ($key, $val) = each %$table) {
        info(sprintf "%30s:\t%s\n", $key, $val) if $val;
    }
}

sub set_vm_guest_os_identifier {
    my ($vm) = @_;
    if (!$guest_os_identifier) {
        if ($os and $os =~ /bsd/) {
            $guest_os_identifier = 'freebsd64Guest';
        } else {
            $guest_os_identifier = 'rhel6_64Guest';
        }
    }

    my $task = $vm->setGuestOperatingSystemType($guest_os_identifier);
    my $status = $task->completedOk(30);
    return $status;
}

sub set_memory_size {
    my ($vm, $memory_size) = @_;
    $memory_size = 512 if $memory_size !~ /\d+/;
    my $task = $vm->setMemory($memory_size);
    my $status = $task->completedOk(30);
    return $status;
}

sub set_cpu_options {
    my ($vm) = @_;
    my ($sockets, $cores) = split(/:/, $cpu_arg);
    $sockets = 1 if !$sockets or $sockets !~ /^\d+$/;
    $cores = 1 if !$cores or $cores !~ /^\d+$/;
    my $task = $vm->setCpusAndCores($sockets, $cores);
    my $status = $task->completedOk(30);
    return $status;
}

sub chk_vm_exist {
    my ($host, $vm_hostname) = @_;
    my $vm_list = $cluster->getVirtualMachines();
    foreach my $vm (@$vm_list) {
        return $vm if $vm->name() eq $vm_hostname;
    }
}

sub get_datastore {
    my ($host) = @_;
    my $ds_dict = {};
    my $cluster = $host->getCluster();
    my $default_ds = $cluster_options->{$cluster->name()}->{default_datastore};
    my $ds_arg = Opts::get_option('ds') || $default_ds;

    my $datastores = $host->getDatastores();

    print Dumper($datastores) if ${debug};

    info("Datastore list:\n");
    foreach my $datastore (@$datastores) {
        my $name = $datastore->name();
        my $fs_type = $datastore->getFilesystemType();
        my $free_space = $datastore->getFreeCapacity();
        info(sprintf "\t%20s %10s %s\n", $name, $fs_type, $free_space);

        if ($datastore->name() eq $ds_arg) {
            info("Use $ds_arg datastore\n\n");
            return $datastore;
        }
    }

    die "Datastore \"$ds_arg\" not found\n";
}

sub get_free_host {
    my ($cluster) = @_;
    my $hosts = $cluster->getHosts();

    my $host_dict = {
        free_memory => 0,
    };

    for (my $i = 0; $i < @$hosts; $i++) {
        my $host = $hosts->[$i];
        my $total_memory = int($host->getTotalMemoryCapacity());
        my $usage_memory = int($host->getMemoryUsage());
        my $free_memory = int($total_memory - $usage_memory);
        my $host_name = $host->name();

        info(sprintf "%40s\tFree memory size: %s MB\n", $host_name, $free_memory);

        if (! $host->getMaintenanceModeStatus() and ($host->getConnectionState() eq 'connected')) {
            if ($free_memory > $host_dict->{free_memory}) {
                $host_dict = {
                    free_memory => $free_memory,
                    obj => $host,
                    name => $host_name,
                };
            }
        }
    }

    info("Use host " . $host_dict->{name} . "\n\n");
    return $host_dict->{obj};
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
