#!/usr/bin/perl
use strict;
use warnings;
use POE qw(Component::Server::TCP Filter::Stream); # libpoe-perl
use Socket qw(IPPROTO_TCP TCP_NODELAY);
use IO::Handle 'autoflush';
use Term::Spinner;
use Pod::Usage 'pod2usage';
use constant PORT => 6666;
STDOUT->autoflush(1);

=head1 SYNOPSIS

script.pl comman1 command2 ...

=cut
pod2usage unless @ARGV;
my $cmd = join(' | ', @ARGV);

my $spinner = Term::Spinner->new();

# クライアントを管理するハッシュ
my %clients;

POE::Component::Server::TCP->new(
    Port => PORT,
    ClientPreConnect => \&client_preconnect,
    ClientConnected => \&client_connected,
    ClientInput => \&client_input,
    ClientDisconnected => \&client_disconnected,
    ClientInputFilter  => POE::Filter::Line->new(),
    ClientOutputFilter => POE::Filter::Stream->new(),
);

POE::Session->create(
    inline_states => {
        _start   => \&session_start,
        got_input => \&got_input,
    },
);

POE::Kernel->run();
exit;


sub session_start {
    my ($kernel, $heap) = @_[KERNEL, HEAP];

    open(my $handle, '-|', $cmd) or die $!;
    $heap->{wheel} = POE::Wheel::ReadWrite->new(
        InputHandle => $handle,
        OutputHandle => \*STDOUT,
        InputFilter => POE::Filter::Stream->new(),
        InputEvent => "got_input",
    );
}

sub got_input {
    my $data = $_[ARG0];
    $data =~ s/\n/\r\n/;
    foreach my $id (keys %clients) {
        $clients{$id}->put($data);
    }
    $spinner->advance();
}

sub client_preconnect {
    my $socket = $_[ARG0];
    # ソケットに対する Nagle のアルゴリズムを無効にする
    setsockopt($socket, IPPROTO_TCP, TCP_NODELAY, 1);
    # It must return a valid client socket if the connection is acceptable.
    return $socket;
}

# 接続時の処理
sub client_connected {
    my $heap = $_[HEAP];
    my $id = $heap->{client}->ID();
    $clients{$id} = $heap->{client};

    print $heap->{remote_ip}, "から接続($id)\n";
    print "コネクションカウント: ", scalar(keys %clients), "\n";
}

# ユーザーの入力に対する処理
sub client_input {
    my ($kernel, $heap, $input) = @_[KERNEL, HEAP, ARG0];

    $input =~ s/\W//g;
    if($input =~ /quit/i){
        # クライアントを切断
        $kernel->yield("shutdown");
    }
    elsif($input =~ /count/i){
        # 接続中のクライアントの数を返す
        $heap->{client}->put(scalar(keys %clients));
    }
}

#切断時の処理
sub client_disconnected {
    my $heap = $_[HEAP];
    my $id = $heap->{client}->ID();

    # %clientsからクライアントのオブジェクトを消します
    delete $clients{$id};

    print $heap->{remote_ip}, "が切断($id)\n";
    print "コネクションカウント: ", scalar(keys %clients), "\n";
}
