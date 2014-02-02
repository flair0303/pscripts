#!/usr/bin/perl

use strict;
use warnings;
#use Data::Dumper;
#use IO::Socket;
use File::Slurp;
use IPC::Open3;

my $hostname = `hostname -s`;
chomp $hostname;

my $pdns_file = '/tmp/lastpdns';
my $pdns_stats = {};

read_current();
write_lastpdns();


    my $udp_queries_per_second = $pdns_stats->{current} - $pdns_stats->{previous};
    print "Previous udp stats: $pdns_stats->{previous}\n";
    print "Current udp stats: $pdns_stats->{current}\n";
    print "$udp_queries_per_second\n";
#   print $remote "LDNS.$hostname.pdns-bh.udp_queries_per_second $udp_queries_per_second $timestamp\n";

########### SUBS ###########

sub read_current {
  $pdns_stats->{previous} = read_file("$pdns_file");
}

sub write_lastpdns {

    my $pdns_stats->{current} = command("/usr/bin/pdns_control show udp-queries");
    if ($udpq->{retcode}) {
        print "Something went wrong running pdns_control!\n";
        exit(1);
    }

    open FH, ">", "$pdns_file" or die "Could not open $pdns_file: $!\n";;
    print FH "$pdns_stats->{current}";
    close FH;
}

sub command {
  my $cmd = shift;
  local(*HIS_IN, *HIS_OUT, *HIS_ERR);

  my $childpid = open3(*HIS_IN, *HIS_OUT, *HIS_ERR, $cmd);
  my @outlines = <HIS_OUT>;
  my @errlines = <HIS_ERR>;
  close HIS_OUT;
  close HIS_ERR;
  waitpid($childpid, 0);
  my $ret = $?;
  return { stdout  => \@outlines,
           stderr  => \@errlines,
           retcode => $ret,
  };
}
