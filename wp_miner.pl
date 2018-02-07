#!/usr/bin/env perl

use strict;
use warnings;
use v5.10;
use Data::Dumper;
use Term::ANSIColor;

my $debug = 0;
my $counter = 0;
my $updates_supported_counter = 0;
my $updates_enabled = 0;

__PACKAGE__->main();
exit;

sub main {
    my $self = shift;

    my $doc_roots = $self->droots();
    print Dumper($doc_roots) if $debug;

    # Check all document roots
    foreach my $doc_root ( sort keys %$doc_roots ){
        my $wpconfig = "$doc_root\/wp-config.php";
        #$self->php_convert($htaccess) if -e $htaccess;
        if (-e $wpconfig) {
            say $wpconfig if $debug;

            my $ver = $self->ver_check($doc_root) || 0.0;
            say "$wpconfig : version = $ver" if $debug;

            # version 3.7 or higher support auto updates
            next if $ver < 3.7;

            $self->wp_check($wpconfig, $ver);
            $counter++;
        }
    }

    say "";
    say "$counter wordpress installations found";
    say "$updates_supported_counter wordpress installations support core updates";
    say "$updates_enabled wordpress installations have core updates enabled";
    say "";

    return;
}

sub droots {
    my $self = shift;

    my $aconf = do {
        if (-e '/etc/apache2/conf/httpd.conf') {'/etc/apache2/conf/httpd.conf';}
        else                                   {'/etc/httpd/conf/httpd.conf';}
    };

    open my $fh, "<", "$aconf" or die "Apache Config undetected: $!";
    my @aconf = <$fh>;
    close $fh;

    my $doc_roots = {};

    foreach my $line (@aconf) {
        chomp $line;
        $doc_roots->{$1} = $2 if $line =~ m/DocumentRoot\ (\/home\d?\/(\w+)\/.+$)/;
    }

    return $doc_roots;
}

sub wp_check {
    my $self = shift;
    my $wpconfig = shift;
    my $ver = shift;

    open my $fh, "<", $wpconfig or die $!;
    my @contents = <$fh>;
    close $fh;

    if (grep(m/WP_AUTO_UPDATE_CORE.*true/, @contents)) {
        printf "%-90s %-25s %4g\n", "$wpconfig", colored("Core updates enabled    ", 'green'), "$ver";
        $updates_enabled++;
    }
    else {
        printf "%-90s %-25s %4g\n", "$wpconfig", colored("Core updates not enabled", 'red'), "$ver";
        $updates_supported_counter++;
    }

    return;
}

sub ver_check {
    my $self = shift;
    my $droot = shift;

    my $cmd = "wp core version --path=$droot --allow-root 2>/dev/null";
    say $cmd if $debug;
    chomp(my $ver = qx{$cmd});

    my $version = $1 if $ver =~ m/(\d\.\d)\./ || 0.0;
    return $version;
}

__END__;

#wp core version --path=/home2/willicp8/public_html/ --allow-root
