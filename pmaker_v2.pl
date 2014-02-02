#!/usr/bin/perl

use warnings;
use strict;
use Getopt::Long;

chomp(my $hname = `hostname --short`);
my $pdns = "";
my $eth = "";
my $help = "";

my $result = GetOptions ( "pdns" => \$pdns,
                          "eth"  => \$eth,
                          "help" => \$help,
                          );
                          
if ( $help ) { usage(); }
if ( $pdns ) { pgen(); }
if ( $eth  ) { eth(); }
                          
###---------------SUBS---------------###                          
                          
sub usage {
  print "Example: $0 --pdns\n";
  print "Example: $0 --eth\n";
}
                          
sub pgen {

my $pconfdir = '/etc/pdns';

my @pconf_files = qw{pdns.conf pdns-hm.conf pdns-rhosthm.conf pdns-fd.conf pdns-hg.conf pdns-hgsg.conf pdns-jh.conf pdns-nsiul.conf pdns-rhostbh.conf pdns-rhostfd.conf pdns-rhosthg.conf pdns-rhostjh.conf pdns-ul.conf};

print "   $hname: {\n";

foreach my $file ( @pconf_files ) {
    chdir $pconfdir or die "cannot chdir to $pconfdir: $1";
    print "     pdns::addpconf \{ \'$file\':\n";
    open CONFIG, "<", "$file";
        while(<CONFIG>) {
            my $line = $_;
            chomp($line);
                if ( $line =~ m/^#/ ) { next; }
                if ( $line =~ m/^gmysql-user=(\w+)/ ) { print "        gmysql_user => \'$1\',\n"; }
                if ( $line =~ m/^gmysql-password=(.+)/ ) { print "        gmysql_pass => \'$1\',\n"; }
                if ( $line =~ m/^gmysql-dbname=(.+)/ ) { print "        gmysql_db   => \'$1\',\n"; }
                if ( $line =~ m/(67\.20\.\d+\.\d+|10\.0\.\d+\.\d+)/ ) { print "        pdns_ip     => \'$1\',\n"; }
                if ( $line =~ m/(74\.220\.\d+\.\d+)/ ) { print "        pdns_ns     => \'$1\',\n"; }
                if ( $line =~ m/(69\.89\.\d+\.\d+)/ ) { print "        pdns_ns2    => \'$1\',\n"; }
                if ( $line =~ m/local-ipv6=(.+)/ ) { print "        pdns_ip6    => \'$1\',\n"; }
        }
        print "     }\n";
        close CONFIG;
}

print "   }\n\n";
print "Update modules/pdns/manifests/pconf.pp\n";
}

sub eth {

    my $ethdir = '/etc/sysconfig/network-scripts';
    
    my @eth_files = qw{eth0 eth0:jhip eth0:hmip eth0:fdip eth0:park1bh eth0:rhosthm eth0:rhostfd eth0:rhostbh eth0:park2bh eth0:rhostjh eth0:ns2hgsg eth0:ulip eth0:nsiulip eth0:rhosthg eth0:hgip};
    
    print "   $hname: {\n";
    
    foreach my $file ( @eth_files ) {
        if ( $file eq "eth0" ) {
            chdir $ethdir or die "cannot chdir to $ethdir: $1";
            print "         network::addifcfg { \'$file\':\n";
            open ETH, "<", "ifcfg-$file";
                while(<ETH>) {
                my $line = $_;
                chomp($line);
                    if ( $line =~ m/^DEVICE=(.+)/ ) { print "           device    => \'$1\',\n"; } 
                    if ( $line =~ m/^ONBOOT=(\w+)/ ) { print "           onboot    => \'$1\',\n"; }
                    if ( $line =~ m/^BOOTPROTO=(\w+)/ ) { print "           bootproto => \'$1\',\n"; }
                    if ( $line =~ m/^IPADDR=(.+)/ ) { print "           ip        => \'$1\',\n"; }
                    if ( $line =~ m/^NETMASK=(.+)/ ) { print "           netmask   => \'$1\',\n"; }
                    #if ( $line =~ m/^GATEWAY=(.+)/ ) { print "           gateway   => \'$1\',\n"; }
                    if ( $line =~ m/^IPV6INIT=(\w+)/ ) { print "           ip6init   => \'$1\',\n"; }
                    if ( $line =~ m/^IPV6ADDR=(.+)/ ) { print "           ip6       => \'$1\',\n"; }
                    if ( $line =~ m/^IPV6_DEFAULTGW=(.+)/ ) { print "           ip6defgw  => \'$1\',\n"; }
                    if ( $line =~ m/^IPV6ADDR_SECONDARIES=(.+)/ ) { print "           ip6secs   => \'$1\',\n"; }
                }
                print "           gateway   => '67.20.126.1',\n";
                print "           con_type  => 'Ethernet',\n";
                close ETH;
        } else {
          chdir $ethdir or die "cannot chdir to $ethdir: $1";
          print "         network::addvip { \'$file\':\n";
          open ETH, "<", "ifcfg-$file";
              while(<ETH>) {
                    my $line = $_;
                    chomp($line);
                    if ( $line =~ m/^DEVICE=(.+)/ ) { print "           device    => \'$1\',\n"; }
                    if ( $line =~ m/^ONBOOT=(\w+)/ ) { print "           onboot    => \'$1\',\n"; }
                    if ( $line =~ m/^BOOTPROTO=(\w+)/ ) { print "           bootproto => \'$1\',\n"; }
                    if ( $line =~ m/^IPADDR=(.+)/ ) { print "           ip        => \'$1\',\n"; }
                    if ( $line =~ m/^NETMASK=(.+)/ ) { print "           netmask   => \'$1\',\n"; }
              }
              close ETH;
      }
      print "         }\n";
    }
    print "   }\n";
    print "Update modules/network/manifests/ldns_eth_ifcfg.pp\n\n";
}
