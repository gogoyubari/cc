#!/usr/bin/perl
use strict;
use warnings;
use POE;
use IO::Socket::INET;
use constant DATAGRAM_MAXLEN => 1024;

POE::Session->create(
    inline_states => {
        _start       => \&server_start,
        get_datagram => \&server_read,
    }
);

POE::Kernel->run();
exit; 

sub server_start {
    my $kernel = $_[KERNEL];
    my $socket = IO::Socket::INET->new(
        Proto     => 'udp',
        LocalPort => '6666',
    ) || die $!;
    $kernel->select_read($socket, "get_datagram");
}

sub server_read {
    my ($kernel, $socket) = @_[KERNEL, ARG0];
    my $message = "";
    my $remote_address = recv($socket, $message, DATAGRAM_MAXLEN, 0);
    return unless defined $remote_address;

    my ($peer_port, $peer_addr) = unpack_sockaddr_in($remote_address);
    my $human_addr = inet_ntoa($peer_addr);
    print "(server) $human_addr : $peer_port sent us $message\n";

    send($socket, $message, 0, $remote_address);
}
