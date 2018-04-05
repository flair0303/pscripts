#!/usr/bin/env perl

use warnings;
use strict;
use File::Tail;
use YAML qw{ LoadFile };
use Data::Dumper;
use v5.10;
use Proc::PID::File; #uses /var/run/$0.pid
die "Already running!" if Proc::PID::File->running();

my $dove_log = '/var/log/maillog';
my $sending_ips = LoadFile('/root/br_list.yaml') or die $!;
my $debug = 0;

__PACKAGE__->main();
exit;

sub main {
    my $self = shift;

    die $! if ! -e $dove_log;

    print Dumper($sending_ips) if $debug;

    my $file=File::Tail->new($dove_log);
    while (defined(my $line=$file->read)) {
        if ( $line =~ m/.*user=<(.*)\@(.*)>,.*rip=(\d*\.\d*\.\d*\.\d*),/ ) {
            my $euser = $1;
            my $dom   = $2;
            my $rip   = $3;

            $self->process($euser, $dom, $rip) if exists $sending_ips->{$rip};
        }
    }

    return;
}

sub process {
    my $self = shift;
    my $euser = shift;
    my $dom   = shift;
    my $rip   = shift;
    #my $log   = "/var/log/$0.log";
    my $log   = '/var/log/dove_sniffer.log';

    open my $fh, '>>', $log or die $!;
    say $fh "$sending_ips->{$rip} $dom $euser\@$dom";
    close $fh;

    return;
}

__END__;

PURPOSE:
Script is designed to log all dovecot auth entries being proxied through $proxy servers

Requirements:
/root/br_list.yaml must exist and contain all sending ips used by $proxy
