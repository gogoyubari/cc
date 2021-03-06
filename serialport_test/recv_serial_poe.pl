#!/usr/bin/perl
use strict;
use warnings;
use POE qw(Wheel::ReadWrite Filter::Stream);
use Device::SerialPort;
use IO::Handle 'autoflush';
use Symbol qw(gensym);
use constant PORT => '/dev/ttyUSB1';

binmode STDOUT;
STDOUT->autoflush(1);

POE::Session->create(
    inline_states => {
        _start => \&setup_device,
        got_port => \&display_port_data,
        got_error => \&handle_errors,
    },
);

POE::Kernel->run();
exit;

sub setup_device {
    my $heap = $_[HEAP];

    my $handle = gensym();
    my $port = tie(*$handle, "Device::SerialPort", PORT) or die $!;
    $port->datatype('raw');
    $port->baudrate(19200);
    $port->databits(8);
    $port->parity('none');
    $port->stopbits(1);
    $port->handshake('none');
    $port->write_settings() or die $!;

    $heap->{port_wheel} = POE::Wheel::ReadWrite->new(
        Handle => $handle,
        Filter => POE::Filter::Stream->new(),
        InputEvent => "got_port",
        ErrorEvent => "got_error",
    );
}

sub display_port_data {
    my $data = $_[ARG0];
    print $data;
}

sub handle_errors {
    my $heap = $_[HEAP];
    delete $heap->{port_wheel};
}
