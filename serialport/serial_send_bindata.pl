#!/usr/bin/perl
use strict;
use warnings;
use Device::SerialPort;
use Term::Spinner;
use constant PORT => '/dev/ttyUSB0';
use constant DATA_FILE => 'data.bin';

my $port = Device::SerialPort->new(PORT) || die $!;
$port->baudrate(19200);
$port->databits(8);
$port->parity('none');
$port->stopbits(1);
$port->handshake('none');
$port->write_settings() || die $!;

open(my $fh, "<", DATA_FILE) || die $!;
binmode $fh;

#my $spinner = Term::Spinner->new();

my $val;
#while (read($fh, $val, 1)) {
while (defined(my $c = getc $fh)) {
#        $spinner->advance();
    #my $txchar = ord($val);
    $port->write($c);
}

close $fh;
$port->close() || warn;
