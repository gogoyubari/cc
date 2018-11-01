#!/usr/bin/perl
use strict;
use warnings;
use IO::Handle 'autoflush';
#binmode STDOUT;
STDOUT->autoflush(1);

my $file = shift;
open(my $fh, "<", $file) || die $!;
#binmode $fh;

while (defined(my $c = getc $fh)) {
    print $c;
#    select(undef, undef, undef, 0.01);
}

close($fh);
exit 0;
