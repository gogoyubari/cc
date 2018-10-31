#!/usr/bin/perl
use strict;
use warnings;
use POE qw(Component::Server::TCP Filter::Stream); # libpoe-perl
use Socket qw(IPPROTO_TCP TCP_NODELAY);
use constant PORT => 6666;
use constant MAXLEN => 2048;
use constant CMD => './stdout_test.pl | ../pipe.pl';

# デフォルトの出力先(STDOUT)のコマンドバッファリングを有効にする
$| = 1;

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
    my $kernel = $_[KERNEL];
    open(my $stdout, '-|', CMD) || die $!;
    $kernel->select_read($stdout, "got_input");
}

sub got_input {
    my $stdout = $_[ARG0];

    my $buffer = '';
    while (sysread($stdout, $buffer, MAXLEN)) {
        #print $buffer;
        foreach my $id (keys %clients) {
            $buffer =~ s/\n/\r\n/;
            $clients{$id}->put($buffer);
        }
    }
}

# ソケットに対する Nagle のアルゴリズムを無効にする
sub client_preconnect {
    my $socket = $_[ARG0];
    setsockopt($socket, IPPROTO_TCP, TCP_NODELAY, 1);
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

    if($input =~ /quit/){
        # クライアントを切断
        $kernel->yield("shutdown");
    }
    elsif($input =~ /count/){
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
