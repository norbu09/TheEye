#!/usr/bin/perl -Ilib

package TheEye::Plugin::Store::Collectd;

use Mouse::Role;
use Collectd::Unixsock;

has 'collectd_socket' => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
    lazy     => 1,
    default  => '/var/run/collectd-unixsock'
);


around 'save' => sub {
    my $orig = shift;
    my ( $self, $tests ) = @_;

    return unless -S $self->collectd_socket;
    my $sock = Collectd::Unixsock->new( $self->collectd_socket );
    foreach my $result (@{$tests}) {

        my @path = split(/\//, $result->{file});
        my @file = split(/\./, pop(@path));

        $sock->putval(
            host   => $self->hostname,
            plugin => $file[0],
            type   => 'latency',
            time   => $result->{time},
            values => [ $result->{delta}, $result->{passed}, $result->{failed} ],
        );
    }
    return;
};


1;
