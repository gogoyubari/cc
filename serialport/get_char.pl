#!/usr/bin/perl
use strict;
use warnings;
$| = 1;

my $file = shift;

open(my $fh, "<", $file) || die $!;

while (defined(my $c = getc $fh)) {
    print $c;
    select(undef, undef, undef, 0.03);
}

close($fh);
exit 0;
