#!/usr/bin/perl

use strict;
use warnings;

use Net::Ping;
use Time::HiRes;
use Monitoring::Plugin;

my $timeout = 2;
my $remotehost = "172.30.0.2";

my $np = Monitoring::Plugin->new (
        usage => '',
        plugin => $0,
        shortname => 'TCP Check',
        blurb => 'check tcp with retries',
        timeout => 10
);

$np->add_arg(spec => 'hostname|h=s', help => 'hostname or ip', required => 1);
$np->add_arg(spec => 'port|p=i', help => 'tcp port number', required => 1);
$np->add_arg(spec => 'timeout|i=i', help => 'timeout per conection attempt', required => 1);
$np->add_arg(spec => 'attempts|a=i', help => 'number of attempts', required => 1);

$np->getopts;

my $p = Net::Ping->new("tcp", $np->opts->timeout);

my $failures = 0;
my $successes = 0;
my $totalduration = 0;
$p->port_number($np->opts->port);
for my $x (1..$np->opts->attempts) {
        my ($result, $duration, $ip) = $p->ping($np->opts->hostname);
        if($result) {
                $successes++;
        } else {
                $failures++;
        }
        $totalduration += $duration;
}
my $avgduration = $totalduration/$np->opts->attempts;
$np->add_perfdata(label => 'rtt', uom => 's', value => $avgduration);

$np->nagios_exit('OK', "TCP Port responded in: $avgduration") unless $successes == 0;
$np->nagios_exit('CRITICAL', "TCP Port ".$np->opts->port." unavailable");
