#!/usr/bin/perl
use strict;
use warnings;
use POE;
use IO::Socket::Multicast;

use constant DATAGRAM_MAXLEN => 2048;
use constant MCAST_PORT => 6666;
use constant MCAST_GROUP => '239.1.1.1';
use constant MCAST_DESTINATION => MCAST_GROUP . ':' . MCAST_PORT;
use constant CMD => './stdout_test.pl | ../pipe.pl';

$| = 1;


POE::Session->create(
    inline_states => {
        _start => \&session_start,
        got_input => \&got_input,
    },
);

POE::Kernel->run();
exit;


sub session_start {
    my $kernel = $_[KERNEL];

    my $socket = IO::Socket::Multicast->new(
        Proto =>'udp',
        PeerAddr => MCAST_DESTINATION,
        #LocalPort => MCAST_PORT,
        ReuseAddr => 1,
        ReusePort => 1,
    ) || die $!;
    #$socket->mcast_add(MCAST_GROUP) || die $!;
    #$socket->mcast_dest(MCAST_DESTINATION);

    open(my $handle, '-|', CMD) || die $!;
    $kernel->select_read($handle, "got_input", $socket);
}

sub got_input {
    my ($kernel, $handle, $socket) = @_[KERNEL, ARG0, ARG2];

    my $buffer = '';
    while (sysread($handle, $buffer, DATAGRAM_MAXLEN)) {
        print $buffer;
        #my $destination = $socket->mcast_dest;
        #send($socket, $buffer, 0, $destination) || warn $!;
        $socket->send($buffer) || warn $!;
    }
}
