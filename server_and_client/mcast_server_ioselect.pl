#!/usr/bin/perl
use warnings;
use strict;
use IO::Select;
use IO::Socket::Multicast; # libio-socket-multicast-perl

use constant TIMEOUT => 0.5;
use constant DATAGRAM_MAXLEN => 1024;
use constant DESTINATION => '239.1.1.1:6666';
use constant CMD => '/home/naka/cc/sample/stdout_test.pl | /home/naka/cc/pipe.pl';

$| = 1;

open(my $stdout, '-|', CMD) || die $!;
my $selector = IO::Select->new($stdout);

my $socket = IO::Socket::Multicast->new(
    Proto=>'udp',
    PeerAddr=>DESTINATION,
) || die $!;

while (1) {
    my $buffer = '';
    if ($selector->can_read(TIMEOUT)) {
        sysread($stdout, $buffer, DATAGRAM_MAXLEN) || warn $!;
        print $buffer;
        $socket->send($buffer) || warn $!;
    }
}
