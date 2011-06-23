use Test::More tests => 1;
use IO::Socket;

my $host      = '127.0.0.1';
my $port      = 5672;
my $test_name = 'couchdb.t';

my $sock = IO::Socket::INET->new(
    Proto    => "tcp",
    PeerAddr => $host,
    PeerPort => $port,
) or BAIL_OUT("Could not open socket: $@");

print $sock "GET /\r\n\r\n";
shutdown $sock, 1;
my $got;
while (<$sock>) {
    $got .= $_;
}

like( $got, qr/Server: CouchDB/, $test_name );
