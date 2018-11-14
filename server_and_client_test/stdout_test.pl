#!/usr/bin/perl
use strict;
use warnings;

my @str1 = split(//, '1234567890123456789012345678901');
my @str2 = split(//, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ');
my @str = ("\x0D", @str1, "\x0D", @str2);

$| = 1;

while (1) {
	for (@str) {
		if ($_ =~ /[\x20-\x7F]/) {
			print $_;
		}
		elsif ($_ =~ /\x0D/) {
			print "\n"
		}
		select(undef, undef, undef, 0.03);
	}
	sleep 1;
}

