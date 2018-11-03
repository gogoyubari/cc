#!/usr/bin/perl
use strict;
use warnings;
use FindBin;
use IO::Handle 'autoflush';

my $file = "$FindBin::Bin/data.bin";
STDOUT->autoflush(1);

open(my $fh, "<", $file) || die $!;
binmode $fh;

my $val;
while (read $fh, $val, 3) {
    if (ord($val) < 0x20) {
        #print '<',  ord($val), '>';
        print $val;
    } elsif (ord($val) >= 0x7F) {
        #print '<',  ord($val), '>';
        print $val;
    } else {
        print $val;
    }
    select(undef, undef, undef, 0.001);
}
close($fh);
exit 0;
