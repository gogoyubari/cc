#!/usr/bin/perl
use warnings;
use strict;
use IO::Socket::Multicast; # libio-socket-multicast-perl
use constant GROUP => '239.1.1.1';
use constant PORT => '6666';

$| = 1;

my $socket = IO::Socket::Multicast->new(
    Proto=>'udp',
    LocalPort=>PORT,
    ReuseAddr => 1,
    ReusePort => 1,
) || die $!;
$socket->mcast_add(GROUP) || die $!;

while (1) {
    my $data;
    next unless $socket->recv($data, 1024);
    print $data;
}
