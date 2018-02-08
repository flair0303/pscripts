#!/usr/bin/env perl

use warnings;
use strict;
use v5.10;
use Data::Dumper;

my $debug = 0;

__PACKAGE__->main();
exit;

sub main {
    my $self = shift;
    my $droots = {};

    my $user_domains_file = '/etc/userdomains';
    open my $fh, "<", $user_domains_file or die $!;
    my @user_domains = <$fh>;
    close $fh;

    #my @user_domains = ("teamabsi.com: nodiceus");
    #my @user_domains = ("chowdachowda.net: chowdach");

    foreach my $line (@user_domains) {
        #next if $line =~ m/^\*/;

        # escape wildcards
        $line =~ s/\*/\\*/;
        my $domain = $1 if $line =~ m/(^.*):/;
        my $droot = $self->get_docroot($domain);
        $domain =~ s/\\//;
        $droots->{$domain} = "$droot";
    }

    #print Dumper($dominfo);

    foreach my $domain ( sort keys %$droots ){
        #say "$domain $droots->{$domain}";
        next if $domain eq '*';
        my $phpver = $self->phpsniff($domain, $droots->{$domain}) || 'unknown';
        say "$domain | phpver: ${phpver}";
    }

    return;
}

sub phpsniff {
    my $self = shift;
    my $d = shift;
    my $droot = shift;
    my $phpver;
    my $user = $1 if $droot =~ m/\/home\d?\/(\w+)\/.+$/;
    say "user = $user droot = $droot domain = $d" if $debug;
    my ($login,$pass,$uid,$gid) = getpwnam($user) or die "$user not in passwd file";
    my $phpinfo = 'php52_sniffer.php';

    open my $fh, '>', "$droot/$phpinfo" or die $!;
    my $phpinfo_string = q{<?php phpinfo(); ?>};
    say $fh "$phpinfo_string";
    close $fh;

    chown $uid, $gid, "$droot/$phpinfo";

    use LWP::UserAgent;

    my $ua = LWP::UserAgent->new;
    $ua->timeout(10);
    $ua->agent("MyApp/0.1");

    my $req = HTTP::Request->new(GET => "http://$d/$phpinfo");
    $req->content_type('application/json');
    my $res = $ua->request($req);

    # Check the outcome of the response
    if ($res->is_success) {
        #print $res->content;
        $phpver = do {
            if    (grep(/PHP Version 5\.2/, $res->content))  {'5.2'}
            elsif (grep(/PHP Version 5\.4/, $res->content))  {'5.4'}
            elsif (grep(/PHP Version 5\.6/, $res->content))  {'5.6'}
            elsif (grep(/PHP Version 7\.0/, $res->content))  {'7.0'}
            else                                             {'unknown'}
        };
    } else {
        #print $res->status_line, "http://$d/$phpinfo";
        #say $res->status_line, " httpd://$d/$phpinfo" if $debug;
        say $res->status_line, " httpd://$d/$phpinfo";
    }

    unlink "$droot/$phpinfo" || die $!;

    return $phpver;
}

sub get_docroot {
    my $self = shift;
    my $domain = shift;
    my $aconf = do {
        if (-e '/etc/apache2/conf/httpd.conf') {'/etc/apache2/conf/httpd.conf';}
        else                                   {'/etc/httpd/conf/httpd.conf';}
    };

    # real	0m51.758s box391
    my $cmd = qq{perl -00 -wnl -e "/$domain/ and print and close ARGV;" $aconf | grep DocumentRoot | awk '{print \$2}' | tail -1};

    # real	11m54.446s box391
    ##my $cmd = qq{whmapi1 domainuserdata domain=$domain | grep documentroot | awk '{print \$2}'};

    say "$cmd" if $debug;
    chomp(my $droot = qx{$cmd});

    return $droot;
}

__END__;


perl -00 -wnl -e '/teamabsi.com/ and print and close ARGV;' /etc/httpd/conf/httpd.conf | grep DocumentRoot

<VirtualHost 74.220.194.133:80>
    Userdir disabled
    ServerName teamabsi.testdomain123.net
    ServerAlias www.teamabsi.com www.teamabsi.testdomain123.net teamabsi.com
    DocumentRoot /home1/nodiceus/public_html/teamabsi
    ServerAdmin webmaster@teamabsi.testdomain123.net
    UseCanonicalName Off
    ## User nodiceus # Needed for Cpanel::ApacheConf
    UserDir disabled
    UserDir enabled nodiceus
    <IfModule mod_suphp.c>
        suPHP_UserGroup nodiceus nodiceus
    </IfModule>
    <IfModule !mod_disable_suexec.c>
        SuexecUserGroup nodiceus nodiceus
    </IfModule>
    ScriptAlias /cgi-bin/ /home1/nodiceus/public_html/teamabsi/cgi-bin/
    RedirectMatch permanent ^(/mailman|/mailman/.*)$ https://box391.bluehost.com$1

          '\\*.rentfast.lk' => '/home2/peraspar/public_html/rentfast',

perl php52_sniffer.pl | grep --color 'PHP Version 7\.0'
