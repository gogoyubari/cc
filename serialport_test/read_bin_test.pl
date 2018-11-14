#!/usr/bin/perl
use strict;
use warnings;
use FindBin;
use IO::Handle 'autoflush';

my $file = "$FindBin::Bin/data.bin";
STDOUT->autoflush(1);

open(my $fh, "<", $file) or die $!;
binmode $fh;

while (read $fh, my $val, 1) {
    if ($val =~ /[\x00-\x1F]/) {
        #printf "[%02X]", ord($val);
        print $val;
    } elsif ($val =~ /[\x20-\x7F]/) {
        print $val;
    } elsif ($val =~ /[\x80-\xFF]/) {
        #printf "[%02X]", ord($val);
        print $val;
    }
    select(undef, undef, undef, 0.001);
}
close($fh);
exit 0;
