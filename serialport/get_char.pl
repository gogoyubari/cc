#!/usr/bin/perl
use strict;
use warnings;
use FindBin;
use IO::Handle 'autoflush';
STDOUT->autoflush(1);
my $file = "$FindBin::Bin/data.bin";

while (1) {
    open(my $fh, "<", $file) || die $!;
    binmode $fh;

    while (defined(my $c = getc $fh)) {
        print $c;
    }
    close($fh);
    sleep(1);
}
exit 0;
