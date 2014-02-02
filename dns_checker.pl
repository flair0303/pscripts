#!/usr/bin/perl
 
use strict;
use warnings;
use IPC::Run3;
use File::Slurp;
use Parallel::ForkManager;

# Skip Buffer, write immediatly to disk
$| = 1;

my $stdout;
my ($v2, $v3) = '';
my $ns = '10.0.148.8';
#my $park = '74.220.199.7';
my @domains_file = read_file("/admin/rchaudhry/pdns_fd-domains.txt");

Max N processes in parallel
my $pm = Parallel::ForkManager->new(50);

digger();

sub digger {

    foreach my $domain (@domains_file) {
        $pm->start and next;
        chomp($domain);
        my $cmd = "/usr/bin/dig $domain \+short \+time\=5 A \@127.0.0.1 | sort | head -1";
        my $cmd2 = "/usr/bin/dig $domain \+short \+retry=5 \+time\=5 A \@$ns | sort | head -1";

        # run3($cmd, $stdin, $stdout, $stderr, \%options)
        run3($cmd, undef, \$stdout);
        chomp($v3 = $stdout);
        run3($cmd2, undef, \$stdout);
        chomp($v2 = $stdout);

        unless ($v2 eq $v3) {
            print "$domain v2 = $v2\n";
            print "$domain v3 = $v3\n";
            print "FAIL: $domain\n\n";
        }
    $pm->finish;
    }
    $pm->wait_all_children;
}