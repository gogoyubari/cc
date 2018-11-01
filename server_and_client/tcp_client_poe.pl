#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long 'GetOptions';
use Pod::Usage 'pod2usage';
use POE qw(Component::Client::TCP Filter::Stream);
use IO::Handle 'autoflush';
STDOUT->autoflush(1);

my ($address, $port);
GetOptions(
    'address=s' => \$address,
    'port=i' => \$port,
) || pod2usage();
pod2usage() unless (defined($address) && defined($port));

=head1 SYNOPSIS

tcp_client_poe.pl [--address] IP_ADDRES [--port] PORT

=cut


POE::Component::Client::TCP->new(
    RemoteAddress => $address,
    RemotePort    => $port,
    ServerInput   => sub {
        my $input = $_[ARG0];
        print $input;
    },
    Filter => "POE::Filter::Stream",
);

POE::Kernel->run();
exit;
