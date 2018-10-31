#!/usr/bin/perl
use strict;
use warnings;
use Device::SerialPort;
use constant PORT => '/dev/ttyUSB0';
$| = 1;

my $port = Device::SerialPort->new(PORT) || die $!;
$port->baudrate(19200);
$port->databits(8);
$port->parity('none');
$port->stopbits(1);
$port->handshake('none');
$port->write_settings() || die $!;

my @str = split(//, '12345678901234567890');

while (1) {
    foreach (@str) {
        $port->write($_);
        select(undef, undef, undef, 0.03);
    }
    $port->write("\r\n");
    print ".";
    select(undef, undef, undef, 1);
}
