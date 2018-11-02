#!/usr/bin/perl
use strict;
use warnings;
use FindBin;
use IO::Handle 'autoflush';
STDOUT->autoflush(1);
my $file = "$FindBin::Bin/data.bin";

open(my $fh, "<", $file) || die $!;
binmode $fh;

my $val;
while (read $fh, $val, 1) {
    if (ord($val) < 0x20) {
        #print '<',  ord($val), '>';
        print $val;
    } elsif (ord($val) >= 0x7F) {
        #print '<',  ord($val), '>';
        print $val;
    } else {
        print $val;
    }
}
close($fh);
exit 0;
