#!/usr/bin/perl
use strict;
use warnings;
use FindBin;
use Device::SerialPort;
use Term::Spinner;
use constant PORT => '/dev/ttyUSB0';

my $file = "$FindBin::Bin/data.bin";

my $port = Device::SerialPort->new(PORT) or die $!;
$port->baudrate(19200);
$port->databits(8);
$port->parity('none');
$port->stopbits(1);
$port->handshake('none');
$port->write_settings() or die $!;

my $spinner = Term::Spinner->new();

open(my $fh, "<", $file) or die $!;
binmode $fh;

while (read($fh, my $val, 3)) {
    $spinner->advance();
    $port->write($val);
    select(undef, undef, undef, 0.001);
}

close $fh;
$port->close() or warn;
exit 0;
