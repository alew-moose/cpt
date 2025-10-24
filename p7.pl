#!/usr/bin/env perl
use v5.42;
use utf8;
use IO::Socket qw(AF_INET SOCK_STREAM SHUT_WR :crlf);
use IO::Select;
use URI::Escape;
use Time::HiRes qw(alarm gettimeofday tv_interval);

sub http_get($host, $port, $path, $query, $timeout) {
    my $body = eval {
        local $SIG{ALRM} = sub { die "timed out\n" };
        alarm $timeout;

        my $sock = IO::Socket->new(
            Domain   => AF_INET,
            Type     => SOCK_STREAM,
            Proto    => 'tcp',
            PeerHost => $host,
            PeerPort => $port,
            Timeout  => $timeout,
        ) || die "can't open socket: $IO::Socket::errstr";

        my $url = $path;
        if (%$query) {
            my @params;
            for my ($key, $val) (%$query) {
                push @params, sprintf '%s=%s', uri_escape_utf8($key), uri_escape_utf8($val);
            }
            $url .= '?' . join('&', @params);
        }

        $sock->send("GET $url HTTP/1.1\r\nHost:$host${CRLF}Connection:close$CRLF$CRLF") // die "send failed: $!";
        $sock->shutdown(SHUT_WR) // die "shutdown failed: $!";

        my $resp = "";
        while (1) {
            my $buffer = "";
            $sock->recv($buffer, 1024) // die 'recv failed';
            last if length($buffer)  == 0;
            $resp .= $buffer;
        }
        $sock->close() // die "close failed: $!";

        my ($header, $body) = split "$CRLF$CRLF", $resp, 2;

        my ($resp_code, $resp_msg) = $header =~ m{^HTTP/1.1 (\d\d\d) (.*)$CRLF};
        die 'failed to parse header' unless $resp_code && $resp_msg;
        die "$resp_code $resp_msg" unless $resp_code == 200;
        alarm 0;
        return $body;
    };
    alarm 0;
    die $@ if $@;

    return $body;
}

sub http_get_async($host, $port, $path, $query, $timeout) {
    my $start_ts = [gettimeofday];
    my $sock = IO::Socket->new(
        Domain   => AF_INET,
        Type     => SOCK_STREAM,
        Proto    => 'tcp',
        PeerHost => $host,
        PeerPort => $port,
        Timeout  => $timeout,
        Blocking => 0,
    ) || die "can't open socket: $IO::Socket::errstr";

    my $url = $path;
    if (%$query) {
        my @params;
        for my ($key, $val) (%$query) {
            push @params, sprintf '%s=%s', uri_escape_utf8($key), uri_escape_utf8($val);
        }
        $url .= '?' . join('&', @params);
    }

    $sock->send("GET $url HTTP/1.1\r\nHost:$host${CRLF}Connection:close$CRLF$CRLF") // die "send failed: $!";
    $sock->shutdown(SHUT_WR) // die "shutdown failed: $!";

    my $resp = "";
    my @numbers;
    my $select = IO::Select->new($sock);
    while (1) {
        my $buffer = "";
        while (1) {
            die "timed out\n" if tv_interval($start_ts) > $timeout;
            my @can_read = $select->can_read(0);
            if (@can_read) {
                $can_read[0]->recv($buffer, 1024) // die 'recv failed';
                last;
            }
            push @numbers, $_ for 1..1000;
        }
        last if length($buffer)  == 0;
        $resp .= $buffer;
    }
    $sock->close() // die "close failed: $!";
    printf STDERR "added %d numbers while waiting\n", scalar @numbers;

    my ($header, $body) = split "$CRLF$CRLF", $resp, 2;

    my ($resp_code, $resp_msg) = $header =~ m{^HTTP/1.1 (\d\d\d) (.*)$CRLF};
    die 'failed to parse header' unless $resp_code && $resp_msg;
    die "$resp_code $resp_msg" unless $resp_code == 200;

    return $body;
}


eval {
    # time out
    my $resp = http_get('localhost', 8888, '/url-parameters', {one => 1, two => 2, 'param three' => 'три'}, 0.5);
    say $resp;
};
warn $@ if $@;

eval {
    # ok
    my $resp = http_get('localhost', 8888, '/url-parameters', {one => 1, two => 2, 'param three' => 'три'}, 1.5);
    say $resp;
};
warn $@ if $@;

eval {
    # time out
    my $resp = http_get_async('localhost', 8888, '/url-parameters', {one => 1, two => 2, 'param three' => 'три'}, 0.5  );
    say $resp;
};
warn $@ if $@;

eval {
    # ok
    my $resp = http_get_async('localhost', 8888, '/url-parameters', {one => 1, two => 2, 'param three' => 'три'}, 1.5  );
    say $resp;
};
warn $@ if $@;
