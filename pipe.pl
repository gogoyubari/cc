#!/usr/bin/perl
use strict;
use warnings;
use Time::HiRes qw(gettimeofday);

my $fps = 0.03/1001;

# デフォルトの出力ハンドルを変更
my $oldfh = select(STDOUT);
# コマンドバッファリングを有効にする
$| = 1;
# 元のファイルハンドルに選択しなおす
select($oldfh);

while (read STDIN, my $val, 1) {
	print STDOUT $val;
	if ($val =~ /\n/) {
		my ($epocsec, $microsec) = gettimeofday();
		my ($sec,$min,$hour) = localtime($epocsec);
		my $frame = $fps * $microsec;

		# SMPTE DF
		if ($min % 10 != 0 && $sec == 0 && $frame == 0) {$frame += 2;}

		printf STDOUT "[%02d:%02d:%02d;%02d] ",$hour,$min,$sec,$frame;
	}
}
