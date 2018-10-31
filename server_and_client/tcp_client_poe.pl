#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use POE qw(Component::Client::TCP Filter::Stream);

my $opt_address = '';
my $opt_port = 0;
GetOptions(
    'address=s' => \$opt_address,
    'port=i' => \$opt_port,
);

$| = 1;

POE::Component::Client::TCP->new(
    RemoteAddress => $opt_address,
    RemotePort    => $opt_port,
    ServerInput   => sub {
        my $input = $_[ARG0];
        print $input;
    },
    Filter => "POE::Filter::Stream",
);

POE::Kernel->run();
exit;
