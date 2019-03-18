#!/usr/bin/perl
use strict;
use warnings;
use POE qw(Wheel::ReadWrite Filter::Stream);
use Device::SerialPort;
use Symbol qw(gensym);
use FindBin;
# /etc/udev/rules.d/99-local.rules
# KERNEL=="ttyUSB*",  ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6001", SYMLINK+="ttyUSB_FT232"
use constant PORT => '/dev/ttyUSB_FT232';

my $parse_cmd = "$FindBin::Bin/ga_parse.pl";


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

    my $serial_handle = gensym();
    my $port = tie(*$serial_handle, "Device::SerialPort", PORT) or die $!;
    $port->datatype('raw');
    $port->baudrate(19200);
    $port->databits(8);
    $port->parity('none');
    $port->stopbits(1);
    $port->handshake('none');
    $port->write_settings() or die $!;

    open(my $output_handle, '|-', $parse_cmd) or die $!;

    $heap->{wheel} = POE::Wheel::ReadWrite->new(
        InputHandle => $serial_handle,
        OutputHandle => $output_handle,
        Filter => POE::Filter::Stream->new(),
        InputEvent => "got_port",
        ErrorEvent => "got_error",
    );
}

sub display_port_data {
    my ($heap, $data) = @_[HEAP, ARG0];
    $heap->{wheel}->put($data);
}

sub handle_errors {
    my $heap = $_[HEAP];
    delete $heap->{wheel};
}
